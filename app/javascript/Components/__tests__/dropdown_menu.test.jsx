import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {DropDownMenu} from "../Result/dropdown_menu";

describe("DropDownMenu", () => {
  const mockItems = [
    {id: 101, content: "aaa", deduction: 1},
    {id: 102, content: "bbb", deduction: 2},
    {id: 103, content: "ccc"},
  ];

  const mockAddExistingAnnotation = jest.fn();

  beforeEach(() => {
    render(
      <DropDownMenu
        header={"Logic"}
        items={mockItems}
        addExistingAnnotation={mockAddExistingAnnotation}
      />
    );
  });

  it("should display the header text", () => {
    expect(screen.getByText("Logic")).toBeInTheDocument();
  });

  it("should show up items when hovering over the header", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    expect(screen.getByText("aaa")).toBeInTheDocument();
    expect(screen.getByText("bbb")).toBeInTheDocument();
    expect(screen.getByText("ccc")).toBeInTheDocument();
  });

  it("should hide items on mouse leave", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    fireEvent.mouseLeave(screen.getByText("Logic"));
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
    expect(screen.queryByText("ccc")).toBeNull();
  });

  it("should not show up items initially", () => {
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
    expect(screen.queryByText("ccc")).toBeNull();
  });

  it("should display the correct deduction values", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    expect(screen.getByText("-1")).toBeInTheDocument();
    expect(screen.getByText("-2")).toBeInTheDocument();
  });

  it("should render the item without deduction correctly", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    expect(screen.getByText("ccc")).toBeInTheDocument();
    expect(screen.queryByText("-")).toBeNull();
  });

  it("should trigger the mock function when an item is clicked", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    fireEvent.click(screen.getByText("aaa"));
    expect(mockAddExistingAnnotation).toHaveBeenCalledWith(101);
  });
});
