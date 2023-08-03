/***
 * Tests for CriteriaFilter Component
 */

import * as React from "react";
import {render, screen, fireEvent, within} from "@testing-library/react";
import {CriteriaFilter} from "../criteria_filter";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("Criteria Filter", () => {
  let props = {
    criteria: {
      a: {min: 0, max: 10},
      b: {min: 0},
      c: {max: 10},
      d: {min: 10, max: 0},
    },
    options: [
      {criterion: "a"},
      {criterion: "b"},
      {criterion: "c"},
      {criterion: "d"},
      {criterion: "e"},
    ],
    onMinChange: jest.fn().mockImplementation(() => null),
    onMaxChange: jest.fn().mockImplementation(() => null),
    onAddCriterion: jest.fn().mockImplementation(() => null),
    onDeleteCriterion: jest.fn().mockImplementation(() => null),
  };

  beforeEach(() => {
    render(<CriteriaFilter {...props} />);
  });

  describe("when the component is first rendered", () => {
    it("should render the component", () => {
      expect(screen.getByText("Criteria")).toBeInTheDocument();
    });

    it("should render the single select dropdown and the add criterion button", () => {
      const dropdown = screen.getByTestId("dropdown");
      const button = screen.getByRole("button");

      expect(dropdown).toBeInTheDocument();
      expect(button).toBeInTheDocument();
      expect(button).toBeDisabled();
    });

    it("should render the criteria list", () => {
      const list = screen.getByRole("list");
      const listItems = screen.getAllByRole("listitem");

      expect(list).toBeInTheDocument();
      expect(listItems).toHaveLength(4);
    });
  });

  describe("when adding a new criterion", () => {
    it("should not select disabled option", () => {
      const dropdown = screen.getByTestId("dropdown");
      const button = screen.getByRole("button");

      fireEvent.click(dropdown);
      fireEvent.click(within(dropdown).getByText("a"));

      expect(within(dropdown).queryByText("a")).not.toBeInTheDocument();
      expect(button).toBeDisabled();
    });

    it("should add criterion", () => {
      const dropdown = screen.getByTestId("dropdown");
      const button = screen.getByRole("button");

      //select option
      fireEvent.click(dropdown);
      fireEvent.click(within(dropdown).getByText("e"));

      expect(within(dropdown).queryByText("e")).toBeInTheDocument();
      expect(button).not.toBeDisabled();

      //add criterion
      fireEvent.click(button);
      expect(props.onAddCriterion).toHaveBeenCalledWith("e");
    });
  });

  describe("when editing a criterion", () => {
    it("should change minimum value", () => {
      const listItem = screen.getAllByRole("listitem")[0];
      const minInput = within(listItem).getByPlaceholderText("Min");

      fireEvent.change(minInput, {
        target: {value: 1},
      });

      expect(props.onMinChange).toHaveBeenCalled();
    });

    it("should change maximum value", () => {
      const listItem = screen.getAllByRole("listitem")[0];
      const maxInput = within(listItem).getByPlaceholderText("Max");

      fireEvent.change(maxInput, {
        target: {value: 1},
      });

      expect(props.onMaxChange).toHaveBeenCalled();
    });
  });

  describe("when deleting a criterion", () => {
    it("should delete the criterion", () => {
      const listItems = screen.getAllByRole("listitem");
      const listItem = listItems[0];
      const xmark = within(listItem).getByTestId("remove-criterion");

      fireEvent.click(xmark);

      expect(props.onDeleteCriterion).toHaveBeenCalledWith("a");
    });
  });
});
