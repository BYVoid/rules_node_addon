"""Rules for building Node.js native addons."""

load("@rules_cc//cc:defs.bzl", "cc_binary")

def _default_copts():
    return select({
        "@platforms//os:windows": ["/std:c++17"],
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
            "@platforms//os:macos": ["-undefined", "dynamic_lookup"],
            "//conditions:default": [],
        }),
        linkshared = True,
        local_defines = local_defines,
        tags = tags,
        testonly = testonly,
        deps = deps + select({
            "@platforms//os:windows": [
                "@node_addon_api//:node_addon_api_headers_only",
                "@node_addon_node_api//:node_api",
            ],
            "//conditions:default": ["@node_addon_api//:node_addon_api"],
        }),
        visibility = ["//visibility:private"],
        **kwargs
    )

    native.genrule(
        name = name,
        srcs = [":" + shared_lib],
        outs = [name + ".node"],
        cmd = """
for f in $(SRCS); do
  case "$$f" in
    *.so|*.dylib)
      cp "$$f" "$(OUTS)"
      exit 0
      ;;
  esac
done
echo "No shared library found in $(SRCS)" >&2
exit 1
""",
        cmd_bat = """
@echo off
for %%f in ($(SRCS)) do (
  if /I "%%~xf"==".dll" (
    copy /Y "%%f" "$(OUTS)"
    if errorlevel 1 exit /B 1
    exit /B 0
  )
)
echo No DLL found in $(SRCS) 1>&2
exit /B 1
""",
        cmd_ps = """
$$ErrorActionPreference = "Stop"
$$srcs = "$(SRCS)".Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
foreach ($$src in $$srcs) {
  if ([System.IO.Path]::GetExtension($$src) -ieq ".dll") {
    Copy-Item -LiteralPath $$src -Destination "$(OUTS)" -Force
    exit 0
  }
}
Write-Error "No DLL found in $(SRCS)"
exit 1
""",
        tags = tags,
        testonly = testonly,
        visibility = visibility,
    )
