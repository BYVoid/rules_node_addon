"""Minimal hermetic Bun support for examples."""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_nodejs//nodejs:toolchain.bzl", "NodeInfo")

_DEFAULT_BUN_VERSION = "1.3.14"
_BUN_RELEASE_URL = "https://github.com/oven-sh/bun/releases/download/bun-v{version}/bun-{platform}.zip"

_KNOWN_BUN_SHA256 = {
    "1.3.14": {
        "darwin-aarch64": "d8b96221828ad6f97ac7ac0ab7e95872341af763001e8803e8267652c2652620",
        "darwin-x64": "4183df3374623e5bab315c547cfa0974533cd457d86b73b639f7a87974cd6633",
        "linux-aarch64": "a27ffb63a8310375836e0d6f668ae17fa8d8d18b88c37c821c65331973a19a3b",
        "linux-x64": "951ee2aee855f08595aeec6225226a298d3fea83a3dcd6465c09cbccdf7e848f",
        "windows-aarch64": "89841f5a57f2348b67ec0839b718f4bf4ea7d07c371c9ba4b77b6c790f918953",
        "windows-x64": "0a0620930b6675d7ba440e81f4e0e00d3cfbe096c4b140d3fff02205e9e18922",
    },
}

_BUN_REPOSITORY_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["{bun}"])

filegroup(
    name = "bun_bin",
    srcs = ["{bun}"],
)
"""

def _bun_archive_sha(version, platform):
    version_shas = _KNOWN_BUN_SHA256.get(version)
    if not version_shas:
        fail("Unsupported Bun version '{}'. Add pinned SHA-256 values to //:bun.bzl.".format(version))
    sha256 = version_shas.get(platform)
    if not sha256:
        fail("Unsupported Bun platform '{}' for version '{}'.".format(platform, version))
    return sha256

def _bun_archive_url(version, platform):
    return _BUN_RELEASE_URL.format(version = version, platform = platform)

def _select_host_platform(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch.lower()

    if "mac" in os_name or "darwin" in os_name:
        if arch in ["aarch64", "arm64"]:
            return "darwin-aarch64"
        if arch in ["amd64", "x86_64", "x64"]:
            return "darwin-x64"

    if "linux" in os_name:
        if arch in ["aarch64", "arm64"]:
            return "linux-aarch64"
        if arch in ["amd64", "x86_64", "x64"]:
            return "linux-x64"

    if "windows" in os_name:
        if arch in ["aarch64", "arm64"]:
            return "windows-aarch64"
        if arch in ["amd64", "x86_64", "x64"]:
            return "windows-x64"

    fail("Unsupported Bun host platform: os={}, arch={}".format(repository_ctx.os.name, repository_ctx.os.arch))

def _bun_executable(platform):
    return "bun.exe" if platform.startswith("windows-") else "bun"

def _download_bun_repository(repository_ctx, platform):
    version = repository_ctx.attr.version
    repository_ctx.download_and_extract(
        url = _bun_archive_url(version, platform),
        sha256 = _bun_archive_sha(version, platform),
        stripPrefix = "bun-{}".format(platform),
    )
    repository_ctx.file("BUILD.bazel", _BUN_REPOSITORY_BUILD.format(
        bun = _bun_executable(platform),
    ))

def _bun_host_repository_impl(repository_ctx):
    _download_bun_repository(repository_ctx, _select_host_platform(repository_ctx))

_bun_host_repository = repository_rule(
    implementation = _bun_host_repository_impl,
    attrs = {
        "version": attr.string(default = _DEFAULT_BUN_VERSION),
    },
)

_toolchain = tag_class(
    attrs = {
        "version": attr.string(default = _DEFAULT_BUN_VERSION),
    },
)

def _bun_extension_impl(module_ctx):
    version = _DEFAULT_BUN_VERSION
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            version = toolchain.version

    maybe(
        _bun_host_repository,
        name = "rules_node_addon_bun_host",
        version = version,
    )

bun = module_extension(
    implementation = _bun_extension_impl,
    tag_classes = {"toolchain": _toolchain},
)

def _shell_quote(value):
    return "'" + str(value).replace("'", "'\"'\"'") + "'"

def _cmd_quote(value):
    return '"' + str(value).replace('"', '\\"') + '"'

def _validate_env_name(name):
    if not name:
        fail("Environment variable names must be non-empty.")
    valid_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
    first_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"
    if name[0] not in first_chars:
        fail("Invalid environment variable name '{}'. Names must start with a letter or underscore.".format(name))
    for i in range(len(name)):
        char = name[i]
        if char not in valid_chars:
            fail("Invalid environment variable name '{}'. Names may contain only letters, digits, and underscores.".format(name))

def _sh_runfiles_env(env):
    lines = []
    for name, path in env.items():
        _validate_env_name(name)
        lines.append("export {}=\"$(rlocation {})\"".format(name, _shell_quote(path)))
    return "\n".join(lines)

def _cmd_runfiles_env(env):
    lines = []
    index = 0
    for name, path in env.items():
        _validate_env_name(name)
        result_var = "__runfiles_env_{}".format(index)
        lines.append("call :rlocation {} {}".format(_cmd_quote(path), result_var))
        lines.append("if errorlevel 1 exit /b 1")
        lines.append("set \"{}=!{}!\"".format(name, result_var))
        index += 1
    return "\n".join(lines)

def _runfiles_env_file_values(targets):
    env = {}
    files = []
    for target, name in targets.items():
        target_files = target[DefaultInfo].files.to_list()
        if len(target_files) != 1:
            fail("runfiles_env_files target for '{}' must provide exactly one file.".format(name))
        file = target_files[0]
        env[name] = _runfiles_path(file)
        files.append(file)
    return env, files

def _runfiles_path(file):
    workspace_name = file.owner.workspace_name
    short_path = file.short_path
    if workspace_name:
        external_prefix = "../{}/".format(workspace_name)
        if short_path.startswith(external_prefix):
            short_path = short_path[len(external_prefix):]
        return "{}/{}".format(workspace_name, short_path)
    return "_main/{}".format(short_path)

def _main_runfiles_path(package, filename):
    if package:
        return "_main/{}/{}".format(package, filename)
    return "_main/{}".format(filename)

def _is_windows(ctx):
    return ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

def _collect_runfiles(targets):
    return [target[DefaultInfo].files for target in targets] + [
        target[DefaultInfo].default_runfiles.files
        for target in targets
    ]

def _bun_run_test_impl(ctx):
    windows = _is_windows(ctx)
    extension = ".cmd" if windows else ".sh"
    executable = ctx.actions.declare_file(ctx.label.name + extension)
    template = ctx.file._cmd_launcher_template if windows else ctx.file._sh_launcher_template
    quote = _cmd_quote if windows else _shell_quote
    node_info = ctx.attr._node_runtime[NodeInfo]
    node = node_info.node
    if not node:
        fail("bun_run_test requires a hermetic rules_nodejs runtime with a node executable.")

    package_dir = ctx.attr.package or ctx.label.package
    runfiles_env_files, env_files = _runfiles_env_file_values(ctx.attr.runfiles_env_files)
    runfiles_env = dict(ctx.attr.runfiles_env)
    runfiles_env.update(runfiles_env_files)

    ctx.actions.expand_template(
        output = executable,
        template = template,
        is_executable = True,
        substitutions = {
            "{{ARGS}}": " ".join([quote(arg) for arg in ctx.attr.args]),
            "{{BUN_PATH}}": _runfiles_path(ctx.file._bun),
            "{{NODE_PATH}}": _runfiles_path(node),
            "{{PACKAGE_JSON_PATH}}": _main_runfiles_path(package_dir, "package.json"),
            "{{RUNFILES_ENV}}": _cmd_runfiles_env(runfiles_env) if windows else _sh_runfiles_env(runfiles_env),
            "{{SCRIPT}}": quote(ctx.attr.script),
        },
    )

    runfiles = ctx.runfiles(
        files = ctx.files.data + [
            ctx.file._bun,
            node,
            executable,
        ] + env_files,
        transitive_files = depset(transitive = _collect_runfiles(ctx.attr.data) + [ctx.attr._node_runtime[DefaultInfo].default_runfiles.files]),
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = runfiles,
    )]

bun_run_test = rule(
    implementation = _bun_run_test_impl,
    attrs = {
        "script": attr.string(mandatory = True),
        "package": attr.string(),
        "runfiles_env": attr.string_dict(),
        "runfiles_env_files": attr.label_keyed_string_dict(allow_files = True),
        "data": attr.label_list(allow_files = True),
        "_bun": attr.label(
            default = "@rules_node_addon_bun_host//:bun_bin",
            allow_single_file = True,
            cfg = "exec",
        ),
        "_node_runtime": attr.label(
            default = "@rules_nodejs//nodejs:current_node_runtime",
            cfg = "exec",
        ),
        "_cmd_launcher_template": attr.label(
            default = "//:bun_run_test.cmd.tpl",
            allow_single_file = True,
        ),
        "_sh_launcher_template": attr.label(
            default = "//:bun_run_test.sh.tpl",
            allow_single_file = True,
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    },
    test = True,
)
