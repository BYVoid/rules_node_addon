"""Windows support module extension for rules_node_addon."""

def _node_api_repo_impl(repository_ctx):
    version = repository_ctx.attr.node_version

    repository_ctx.download_and_extract(
        url = "https://nodejs.org/dist/v%s/node-v%s-headers.tar.xz" % (version, version),
        output = ".",
        sha256 = repository_ctx.attr.headers_sha256,
        stripPrefix = "node-v%s" % version,
    )
    repository_ctx.download(
        url = "https://nodejs.org/dist/v%s/win-x64/node.lib" % version,
        output = "win-x64/node.lib",
        sha256 = repository_ctx.attr.win_x64_node_lib_sha256,
    )
    repository_ctx.download(
        url = "https://nodejs.org/dist/v%s/win-arm64/node.lib" % version,
        output = "win-arm64/node.lib",
        sha256 = repository_ctx.attr.win_arm64_node_lib_sha256,
    )
    repository_ctx.file("BUILD.bazel", """\
load("@rules_cc//cc:defs.bzl", "cc_import", "cc_library")

package(default_visibility = ["//visibility:public"])

config_setting(
    name = "windows_x64",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
)

config_setting(
    name = "windows_arm64",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:aarch64",
    ],
)

cc_library(
    name = "node_headers",
    hdrs = glob(["include/node/**/*.h"]),
    includes = ["include/node"],
)

cc_import(
    name = "node_lib_win_x64",
    interface_library = "win-x64/node.lib",
    system_provided = True,
)

cc_import(
    name = "node_lib_win_arm64",
    interface_library = "win-arm64/node.lib",
    system_provided = True,
)

cc_library(
    name = "node_api",
    target_compatible_with = ["@platforms//os:windows"],
    deps = [":node_headers"] + select({
        ":windows_x64": [":node_lib_win_x64"],
        ":windows_arm64": [":node_lib_win_arm64"],
        "//conditions:default": [],
    }),
)
""")

_node_api_repo = repository_rule(
    implementation = _node_api_repo_impl,
    attrs = {
        "headers_sha256": attr.string(mandatory = True),
        "node_version": attr.string(mandatory = True),
        "win_arm64_node_lib_sha256": attr.string(mandatory = True),
        "win_x64_node_lib_sha256": attr.string(mandatory = True),
    },
)

_DEFAULT_NODE_VERSION = "24.14.0"
_DEFAULT_HEADERS_SHA256 = "87d1a7d80599ce330de0f0832f6b85c7d93c5be7b6a203725afa016405227988"
_DEFAULT_WIN_ARM64_NODE_LIB_SHA256 = "59f1c42e5962e9333bb1673c21125b7a7ce9a6908299aee8f7673803c2e24212"
_DEFAULT_WIN_X64_NODE_LIB_SHA256 = "35fcdd35d3d22e283c0e2e095cc43ef676301bb85f950c344a73d59231bd7e61"

_toolchain = tag_class(
    attrs = {
        "headers_sha256": attr.string(default = _DEFAULT_HEADERS_SHA256),
        "node_version": attr.string(default = _DEFAULT_NODE_VERSION),
        "win_arm64_node_lib_sha256": attr.string(default = _DEFAULT_WIN_ARM64_NODE_LIB_SHA256),
        "win_x64_node_lib_sha256": attr.string(default = _DEFAULT_WIN_X64_NODE_LIB_SHA256),
    },
)

def _node_addon_impl(module_ctx):
    root_toolchains = []
    dependency_toolchains = []
    for module in module_ctx.modules:
        if module.is_root:
            root_toolchains.extend(module.tags.toolchain)
        else:
            dependency_toolchains.extend(module.tags.toolchain)

    if len(root_toolchains) > 1:
        fail("Only one node_addon.toolchain tag is supported in the root module")
    if root_toolchains:
        toolchain = root_toolchains[0]
    elif len(dependency_toolchains) > 1:
        fail("Only one non-root node_addon.toolchain tag is supported")
    elif dependency_toolchains:
        toolchain = dependency_toolchains[0]
    else:
        toolchain = struct(
            headers_sha256 = _DEFAULT_HEADERS_SHA256,
            node_version = _DEFAULT_NODE_VERSION,
            win_arm64_node_lib_sha256 = _DEFAULT_WIN_ARM64_NODE_LIB_SHA256,
            win_x64_node_lib_sha256 = _DEFAULT_WIN_X64_NODE_LIB_SHA256,
        )

    _node_api_repo(
        name = "node_addon_node_api",
        headers_sha256 = toolchain.headers_sha256,
        node_version = toolchain.node_version,
        win_arm64_node_lib_sha256 = toolchain.win_arm64_node_lib_sha256,
        win_x64_node_lib_sha256 = toolchain.win_x64_node_lib_sha256,
    )

node_addon = module_extension(
    implementation = _node_addon_impl,
    tag_classes = {
        "toolchain": _toolchain,
    },
)
