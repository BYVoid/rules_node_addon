const assert = require("assert");
const path = require("path");

const addon = require(path.join(__dirname, "hello.node"));

const expected = "hello from rules_node_addon";
const actual = addon.hello();

assert.strictEqual(
  actual,
  expected,
  `addon.hello() returned "${actual}", expected "${expected}"`,
);

console.log("addon test passed:", actual);
