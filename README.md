# rules_node_addon

Bazel rules for building Node.js native addons.

## Setup

Enable the Node toolchain with headers in your root `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_node_addon", version = "0.0.0")
bazel_dep(name = "rules_nodejs", version = "6.7.4")

node = use_extension("@rules_nodejs//nodejs:extensions.bzl", "node")
node.toolchain(include_headers = True)
use_repo(node, "nodejs_toolchains")
```

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
bazel test //examples:hello_test
```
