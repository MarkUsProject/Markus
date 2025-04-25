import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {SingleSelectDropDown} from "../DropDown/SingleSelectDropDown.jsx";

describe("SingleSelectDropdown", () => {
  let props;
  let onChange = jest.fn();
  let options = ["a", "b", "c"];

  beforeEach(() => {
    props = {
      options: options,
      selected: "",
      onSelect: onChange,
      defaultValue: "",
    };

    render(<SingleSelectDropDown {...props} />);
  });

  describe("when the dropdown is closed", () => {
    describe("when the dropdown is first rendered", () => {
      it("should load the selected value as the currently selected option", () => {
        expect(screen.getByTestId("selection")).toHaveTextContent("");
      });
    });

    it("should not load the dropdown options", () => {
      expect(screen.queryByText("a")).toBeNull();
      expect(screen.queryByText("b")).toBeNull();
      expect(screen.queryByText("c")).toBeNull();
    });

    it("should render a down arrow within the dropdown", () => {
      expect(screen.getByTestId("arrow-down")).toBeInTheDocument();
    });
  });

  describe("when the dropdown is opened", () => {
    describe("when there are options available", () => {
      it("should open a dropdown only with the options specified", () => {
        fireEvent.click(screen.getByTestId("dropdown"));
        expect(screen.getByText("a")).toBeInTheDocument();
        expect(screen.getByText("b")).toBeInTheDocument();
        expect(screen.getByText("c")).toBeInTheDocument();
        expect(screen.getAllByRole("listitem").length).toBe(3);
      });
    });

    describe("No options available", () => {
      beforeAll(() => {
        options = [];
      });

      it("should show no options available when there aren't any options to choose from", () => {
        fireEvent.click(screen.getByTestId("dropdown"));
        expect(screen.getByText("No options available")).toBeInTheDocument();
        expect(screen.queryByText("a")).toBeNull();
        expect(screen.queryByText("b")).toBeNull();
        expect(screen.queryByText("c")).toBeNull();
      });
    });

    it("should render a upward arrow within the dropdown", () => {
      fireEvent.click(screen.getByTestId("dropdown"));
      expect(screen.getByTestId("arrow-up")).toBeInTheDocument();
    });

    it("should close the dropdown when clicked again", () => {
      fireEvent.click(screen.getByTestId("dropdown"));
      fireEvent.click(screen.getByTestId("dropdown"));
      expect(screen.queryByText("a")).toBeNull();
      expect(screen.queryByText("b")).toBeNull();
      expect(screen.queryByText("c")).toBeNull();
    });
  });
});
