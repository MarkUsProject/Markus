const _ = require("lodash");

function add(a, b) {
  return _.sum([a, b]);
}

function isEven(n) {
  return Number.isInteger(n) && n % 2 === 0;
}

module.exports = {add, isEven};
