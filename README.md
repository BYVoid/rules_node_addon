# rules_node_addon

Bazel rules for building Node.js native addons.

## Setup

Enable the Windows addon support repository and Node runtime with headers in your root `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_node_addon", version = "0.0.0")
bazel_dep(name = "rules_nodejs", version = "6.7.4")

node_addon_windows = use_extension("@rules_node_addon//node_addon:windows.bzl", "node_addon_windows")
use_repo(node_addon_windows, "windows_node_api")

node = use_extension("@rules_nodejs//nodejs:extensions.bzl", "node")
node.toolchain(include_headers = True)
use_repo(node, "nodejs_toolchains")
```

The `node_addon_windows` extension is used only on Windows, where rules_nodejs' built-in
Node toolchain does not provide C headers. It downloads Node's C headers and
Windows import libraries. It defaults to Node 24.14.0. To use a different Node
release, pass `node_version` and the matching SHA-256 values to
`node_addon_windows.toolchain(...)`.

To use Node 26 with rules_nodejs 6.7.4, provide explicit Node distribution
metadata because that rules_nodejs release does not include Node 26 in its
built-in catalog:

```starlark
node_addon_windows.toolchain(
    node_version = "26.4.0",
    headers_sha256 = "6eb5714cf9e917c5627f1f4df8ba126080333ddd51bca64bc0d424f82162c434",
    win_arm64_node_lib_sha256 = "c01ce0d5e4e956f0e5e73cdba925d15a6d6f86883aa49f8f0b0de87aa93508ce",
    win_x64_node_lib_sha256 = "56f06350037085fce04930befd98327afc86ee46f52af6f6f8a68a03630e8380",
)

node.toolchain(
    node_version = "26.4.0",
    include_headers = True,
    node_repositories = {
        "26.4.0-darwin_amd64": ("node-v26.4.0-darwin-x64.tar.gz", "node-v26.4.0-darwin-x64", "eb3bdd8dec3ff2558ee10e284da7d2a3865af0cbda21f06d397b0265837c641e"),
        "26.4.0-darwin_arm64": ("node-v26.4.0-darwin-arm64.tar.gz", "node-v26.4.0-darwin-arm64", "4f4fbcacf6b1ff1a95deedba7bd7b2d79efecaa53a8ecb0530546dc9063fefbc"),
        "26.4.0-linux_amd64": ("node-v26.4.0-linux-x64.tar.xz", "node-v26.4.0-linux-x64", "5c4286dcd5bbd5acb1ccc7eb0e088bd5eb1e3affad671ee9364004f8f6a4a431"),
        "26.4.0-linux_arm64": ("node-v26.4.0-linux-arm64.tar.xz", "node-v26.4.0-linux-arm64", "f6d8eedc52170667d45730ac2f413c4aa1e7cd2165c9cac5746ef3cb0f4ec45a"),
        "26.4.0-windows_amd64": ("node-v26.4.0-win-x64.zip", "node-v26.4.0-win-x64", "5f87d038c6ec442aa46b9126f8ca170acbd2f3b9b9152ca798cf54596a31e214"),
        "26.4.0-windows_arm64": ("node-v26.4.0-win-arm64.zip", "node-v26.4.0-win-arm64", "394cb72e664faaa518ca1877bcc20bb03a3e2f51ed1f6cfce53e1a306e8c97f6"),
    },
)
```

See `examples/node26` for a complete module.

## Example

```starlark
load("@rules_node_addon//node_addon:defs.bzl", "node_addon")

node_addon(
    name = "hello",
    srcs = ["hello.cc"],
)
```

This produces `hello.node`, suitable for `require("./hello.node")` from Node.js.

Run the included test with:

```sh
bazel test //examples/hello/...
cd examples/node26 && bazel test //...
```
