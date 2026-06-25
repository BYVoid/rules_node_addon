# rules_node_addon

Bazel rules for building Node.js native addons.

## Setup

Enable the addon support repository and Node runtime in your root `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_node_addon", version = "0.0.0")
bazel_dep(name = "rules_nodejs", version = "6.7.4")

node_addon = use_extension("@rules_node_addon//node_addon:extensions.bzl", "node_addon")
use_repo(node_addon, "node_addon_node_api")

node = use_extension("@rules_nodejs//nodejs:extensions.bzl", "node")
node.toolchain()
use_repo(node, "nodejs_toolchains")
```

The `node_addon` extension downloads Node's C headers and Windows import
libraries. It defaults to Node 24.14.0. To use a different Node release, pass
`node_version` and the matching SHA-256 values to `node_addon.toolchain(...)`.

## Example

```starlark
load("@rules_node_addon//node_addon:defs.bzl", "node_addon")

node_addon(
    name = "hello",
    srcs = ["hello.cc"],
    copts = ["-std=c++17"],
)
```

This produces `hello.node`, suitable for `require("./hello.node")` from Node.js.

Run the included test with:

```sh
bazel test //examples/...
```
