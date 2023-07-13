/***
 * Tests for MultiSelectDropdown Component
 */

import * as React from "react";
import {render, screen, fireEvent, within, waitFor} from "@testing-library/react";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";

describe("MultiSelectDropdown", () => {
  let props;

  beforeEach(() => {
    props = {
      id: "Test",
      options: ["abc", "def", "ghi", "jhk"],
      selected: ["abc"],
      toggleOption: jest.fn().mockImplementation(() => null),
      clearSelection: jest.fn().mockImplementation(() => null),
    };
    render(<MultiSelectDropdown {...props} />);
  });

  it("should render the closed dropdown by default", () => {
    const tags_box = screen.getByTestId("tags-box");
    expect(tags_box).toBeInTheDocument();
    expect(tags_box.getElementsByClassName("tag")).toHaveLength(1);
    expect(screen.getByText("abc")).toBeInTheDocument(); //test for arrow
    expect(screen.getByTestId("reset")).toBeInTheDocument();
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("should expand dropdown on click", () => {
    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    expect(screen.queryByRole("list")).toBeInTheDocument();
    expect(screen.queryAllByRole("listitem")).toHaveLength(4);
    expect(screen.getByLabelText("abc")).toHaveAttribute("checked");
  });

  it("should close expanded dropdown on click", () => {
    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    fireEvent.click(tags_box);
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("should deselect option when clicked on tag", () => {
    const tag = screen.getByText("abc");
    fireEvent.click(tag);
    expect(props.toggleOption).toHaveBeenCalledWith("abc");
  });

  it("should deselect option when clicked on a select list item", () => {
    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    const selected_option = screen.getByLabelText("abc");
    fireEvent.click(selected_option);
    expect(props.toggleOption).toHaveBeenCalledWith("abc");
  });

  it("should select option when clicked on a list item", () => {
    const tags_box = screen.getByTestId("tags-box");
    fireEvent.click(tags_box);
    const option = screen.getByLabelText("def");
    fireEvent.click(option);
    expect(props.toggleOption).toHaveBeenCalledWith("def");
  });

  it("should clear all selections when clicked on reset xmark icon", () => {
    const icon = screen.getByTestId("reset");
    fireEvent.click(icon);
    expect(props.clearSelection).toHaveBeenCalled();
  });
});
