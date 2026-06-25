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
release, see the complete module in [`examples/node_version_pin`](examples/node_version_pin).

## Example

```starlark
load("@rules_node_addon//node_addon:defs.bzl", "node_addon")

node_addon(
    name = "hello",
    srcs = ["hello.cc"],
)
```

This produces `hello.node`, suitable for `require("./hello.node")` from Node.js.

By default, `node_addon` does not define `NAPI_VERSION`. To build against a
specific Node-API version, pass the `napi_version` build setting:

```sh
bazel build //path/to:addon --@rules_node_addon//node_addon:napi_version=8
```

Run the included test with:

```sh
bazel test //examples/hello/...
cd examples/node_version_pin && bazel test //...
cd examples/full && bazel test //...
```
