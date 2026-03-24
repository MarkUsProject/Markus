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

    it("returns false for numeric strings", () => {
      expect(isEven("2")).toBe(false);
    });
  });

  describe("error example", () => {
    it("raises an error during test execution", () => {
      throw new Error("Intentional error example for JS autotester output");
    });
  });
});
