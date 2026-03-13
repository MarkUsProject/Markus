const {add, isEven} = require("./submission.js");

describe("submission", () => {
  describe("add", () => {
    it("adds two numbers", () => {
      expect(add(1, 2)).toBe(3);
    });

    it("adds negative numbers", () => {
      expect(add(-1, -2)).toBe(-3);
    });
  });

  describe("isEven", () => {
    it("returns true for even numbers", () => {
      expect(isEven(2)).toBe(true);
      expect(isEven(0)).toBe(true);
    });

    it("returns false for odd numbers", () => {
      expect(isEven(1)).toBe(false);
      expect(isEven(3)).toBe(false);
    });
  });
});
