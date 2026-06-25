"""Rules for building Node.js native addons."""

load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_cc//cc:defs.bzl", "cc_binary")

_NODE_ADDON_API = Label("@node_addon_api//:node_addon_api")
_NODE_ADDON_API_HEADERS_ONLY = Label("@node_addon_api//:node_addon_api_headers_only")
_NODE_API_WINDOWS = Label("@windows_node_api//:node_api")
_WINDOWS = Label("@platforms//os:windows")
_MACOS = Label("@platforms//os:macos")

def _default_copts():
    return select({
        _WINDOWS: ["/std:c++17"],
        "//conditions:default": ["-std=c++17"],
    })

def node_addon(
        name,
        srcs,
        deps = [],
        copts = [],
        linkopts = [],
        data = [],
        defines = [],
        includes = [],
        local_defines = [],
        visibility = None,
        tags = [],
        testonly = False,
        **kwargs):
    """Builds a Node.js native addon with a `.node` extension.

    The addon is linked as a loadable shared library. On macOS, N-API symbols are
    resolved from the hosting Node process at dlopen time, matching node-gyp's
    behavior.

    Args:
      name: Name of the generated addon target. The output file is `name.node`.
      srcs: C/C++ sources for the addon.
      deps: Additional C/C++ dependencies.
      copts: Additional compiler options. Defaults to C++17 when empty.
      linkopts: Additional linker options.
      data: Runtime files needed by the shared library.
      defines: C/C++ defines.
      includes: Include search paths.
      local_defines: C/C++ local defines.
      visibility: Target visibility for the generated `.node` file.
      tags: Tags propagated to generated targets.
      testonly: Whether generated targets are testonly.
      **kwargs: Extra attributes passed to the underlying `cc_binary`.
    """

    shared_lib = name + "_shared"

    cc_binary(
        name = shared_lib,
        srcs = srcs,
        copts = copts if copts else _default_copts(),
        data = data,
        defines = defines,
        includes = includes,
        linkopts = linkopts + select({
            _MACOS: ["-undefined", "dynamic_lookup"],
            "//conditions:default": [],
        }),
        linkshared = True,
        local_defines = local_defines,
        tags = tags,
        testonly = testonly,
        deps = deps + select({
            _WINDOWS: [
                _NODE_ADDON_API_HEADERS_ONLY,
                _NODE_API_WINDOWS,
            ],
            "//conditions:default": [_NODE_ADDON_API],
        }),
        visibility = ["//visibility:private"],
        **kwargs
    )

    copy_file(
        name = name,
        src = ":" + shared_lib,
        out = name + ".node",
        tags = tags,
        testonly = testonly,
        visibility = visibility,
    )
