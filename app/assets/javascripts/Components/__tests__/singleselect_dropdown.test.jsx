import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {SingleSelectDropDown} from "../../DropDownMenu/SingleSelectDropDown.js";

describe("SingleSelectDropdown", () => {
  let props;
  let onChange = jest.fn();
  beforeEach(() => {
    props = {
      options: ["a", "b", "c"],
      selected: "",
      select: onChange,
      defaultValue: "",
    };
    render(<SingleSelectDropDown {...props} />);
  });

  it("should load the default value as the currently selected option", () => {
    expect(screen.getByTestId("selection")).toHaveTextContent("");
  });
  it("should not load the dropdown options when the dropdown has not been clicked", () => {
    expect(screen.queryByText("a")).toBeNull();
    expect(screen.queryByText("b")).toBeNull();
    expect(screen.queryByText("c")).toBeNull();
  });

  it("should load the dropdown options when it has been clicked", () => {
    fireEvent.click(screen.getByTestId("dropdown"));
    expect(screen.getByText("a")).toBeInTheDocument();
    expect(screen.getByText("b")).toBeInTheDocument();
    expect(screen.getByText("c")).toBeInTheDocument();
  });
  it("should open a dropdown only with the options specified", () => {
    fireEvent.click(screen.getByTestId("dropdown"));
    expect(screen.getByText("a")).toBeInTheDocument();
    expect(screen.getByText("b")).toBeInTheDocument();
    expect(screen.getByText("c")).toBeInTheDocument();
    expect(screen.getAllByRole("listitem").length).toBe(3);
  });
  it("should render a down arrow within the dropdown when it is closed", () => {
    expect(screen.getByTestId("arrow-down")).toBeInTheDocument();
  });
  it("should render a upward arrow within the dropdown when it is open", () => {
    fireEvent.click(screen.getByTestId("dropdown"));
    expect(screen.getByTestId("arrow-up")).toBeInTheDocument();
  });
  it("should close the dropdown when already expanded and clicked again", () => {
    fireEvent.click(screen.getByTestId("dropdown"));
    fireEvent.click(screen.getByTestId("dropdown"));
    expect(screen.queryByText("a")).toBeNull();
    expect(screen.queryByText("b")).toBeNull();
    expect(screen.queryByText("c")).toBeNull();
  });
});
