import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {DropDownMenu} from "../Result/dropdown_menu";

describe("DropDownMenu", () => {
  const mockItems = [
    {id: 101, content: "aaa", deduction: 1},
    {id: 102, content: "bbb", deduction: 2},
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
  });

  it("should hide items on mouse leave", () => {
    fireEvent.mouseLeave(screen.getByText("Logic"));
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
  });

  it("should not show up items initially", () => {
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
  });

  it("should display the correct deduction values", () => {
    fireEvent.mouseEnter(screen.getByText("Logic"));
    expect(screen.getByText("-1")).toBeInTheDocument();
    expect(screen.getByText("-2")).toBeInTheDocument();
  });
});
