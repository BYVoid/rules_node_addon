"""Minimal npm install support for the full example."""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_NPM_REPOSITORY_BUILD = """\
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "node_modules",
    srcs = glob(["node_modules/**"]),
)
"""

def _npm_install_repository_impl(repository_ctx):
    repository_ctx.symlink(repository_ctx.attr.package_json, "package.json")
    repository_ctx.symlink(repository_ctx.attr.package_lock, "package-lock.json")
    result = repository_ctx.execute([
        "npm",
        "ci",
        "--include=dev",
        "--no-audit",
        "--fund=false",
    ], quiet = False)
    if result.return_code != 0:
        fail("npm ci failed:\nSTDOUT:\n{}\nSTDERR:\n{}".format(result.stdout, result.stderr))
    repository_ctx.file("BUILD.bazel", _NPM_REPOSITORY_BUILD)

_npm_install_repository = repository_rule(
    implementation = _npm_install_repository_impl,
    attrs = {
        "package_json": attr.label(mandatory = True, allow_single_file = True),
        "package_lock": attr.label(mandatory = True, allow_single_file = True),
    },
)

_install = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "package_json": attr.label(mandatory = True),
        "package_lock": attr.label(mandatory = True),
    },
)

def _npm_deps_extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for install in mod.tags.install:
            maybe(
                _npm_install_repository,
                name = install.name,
                package_json = install.package_json,
                package_lock = install.package_lock,
            )

npm_deps = module_extension(
    implementation = _npm_deps_extension_impl,
    tag_classes = {"install": _install},
)
