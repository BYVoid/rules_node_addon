const assert = require("node:assert/strict");
const path = require("node:path");

const addon = require(path.join(__dirname, "hello.node"));

const expected = "hello from rules_node_addon";
const actual = addon.hello();

assert.equal(
  actual,
  expected,
  `addon.hello() returned "${actual}", expected "${expected}"`,
);

console.log("CommonJS addon test passed:", actual);
