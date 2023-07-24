/***
 * Tests for MultiSelectDropdown Component
 */

import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("MultiSelectDropdown", () => {
  let props = {
    id: "Test",
    options: [
      {key: "a", display: "a"},
      {key: "b", display: "b"},
      {key: "c", display: "c"},
      {key: "d", display: "d"},
    ],
    selected: ["a"],
    onToggleOption: jest.fn().mockImplementation(() => null),
    onClearSelection: jest.fn().mockImplementation(() => null),
  };

  it("should render the closed dropdown by default", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    expect(tags_box).toBeInTheDocument();
    expect(tags_box.getElementsByClassName("tag")).toHaveLength(1);
    expect(screen.getByText("a")).toBeInTheDocument(); //test for arrow
    expect(screen.getByTestId("reset")).toBeInTheDocument();
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("should expand dropdown on click", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    expect(screen.queryByRole("list")).toBeInTheDocument();
    expect(screen.queryAllByRole("listitem")).toHaveLength(4);
    expect(screen.getByLabelText("a")).toHaveAttribute("checked");
    expect(screen.getByLabelText("b")).not.toHaveAttribute("checked");
    expect(screen.getByLabelText("c")).not.toHaveAttribute("checked");
    expect(screen.getByLabelText("d")).not.toHaveAttribute("checked");
  });

  it("should close expanded dropdown on click", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    fireEvent.click(tags_box);
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("should close expanded dropdown on mousedown outside", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    fireEvent.mouseDown(document);
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("should deselect option when clicked on tag", () => {
    render(<MultiSelectDropdown {...props} />);

    const tag = screen.getByText("a");
    fireEvent.click(tag);
    expect(props.onToggleOption).toHaveBeenCalledWith("a");
  });

  it("should deselect option when clicked on a select list item", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    const selected_option = screen.getByLabelText("a");
    fireEvent.click(selected_option);
    expect(props.onToggleOption).toHaveBeenCalledWith("a");
    expect(screen.queryByRole("list")).toBeInTheDocument();
  });

  it("should select option when clicked on a list item", () => {
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    const option = screen.getByLabelText("b");
    fireEvent.click(option);
    expect(props.onToggleOption).toHaveBeenCalledWith("b");
  });

  it("should clear all selections when clicked on reset xmark icon", () => {
    render(<MultiSelectDropdown {...props} />);

    const icon = screen.getByTestId("reset");
    fireEvent.click(icon);
    expect(props.onClearSelection).toHaveBeenCalled();
  });

  it("should show no options available when options passed down from props is empty", () => {
    props.options = [];
    props.selected = [];
    render(<MultiSelectDropdown {...props} />);

    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    expect(screen.queryByRole("list")).toBeInTheDocument();
    expect(screen.queryAllByRole("listitem")).toHaveLength(1);
    expect(screen.getByText("No options available")).toBeInTheDocument();
  });
});
