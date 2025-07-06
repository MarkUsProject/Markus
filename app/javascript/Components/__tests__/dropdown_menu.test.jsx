import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {DropDownMenu} from "../Result/dropdown_menu";

describe("DropDownMenu", () => {
  const mockCategories = [
    {
      id: 1,
      className: "Grammar",
      texts: [
        {id: 101, content: "aaa", deduction: 1},
        {id: 102, content: "bbb", deduction: 2},
      ],
    },
    {
      id: 2,
      className: "Logic",
      texts: [{id: 201, content: "ddd", deduction: 3}],
    },
  ];

  const mockNewAnnotation = jest.fn();
  const mockAddExistingAnnotation = jest.fn();

  beforeEach(() => {
    render(
      <DropDownMenu
        categories={mockCategories}
        newAnnotation={mockNewAnnotation}
        addExistingAnnotation={mockAddExistingAnnotation}
      />
    );
  });

  it("should display the annotation category names", () => {
    expect(screen.getByText("Grammar")).toBeInTheDocument();
    expect(screen.getByText("Logic")).toBeInTheDocument();
  });

  it("should show up the correct annotations when hovering over the annotation category", () => {
    fireEvent.mouseEnter(screen.getByTestId("category-1"));
    expect(screen.getByText("aaa")).toBeInTheDocument();
    expect(screen.getByText("bbb")).toBeInTheDocument();
    expect(screen.queryByText("ddd")).toBeNull();

    fireEvent.mouseEnter(screen.getByTestId("category-2"));
    expect(screen.getByText("ddd")).toBeInTheDocument();
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
  });

  it("should hide the individual annotations on mouse leave", () => {
    fireEvent.mouseEnter(screen.getByTestId("category-1"));
    fireEvent.mouseLeave(screen.getByTestId("category-1"));
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
  });

  it("should not show annotations initially", () => {
    expect(screen.queryByText("aaa")).toBeNull();
    expect(screen.queryByText("bbb")).toBeNull();
    expect(screen.queryByText("ddd")).toBeNull();
  });

  it("should display the correct deduction values", () => {
    fireEvent.mouseEnter(screen.getByTestId("category-1"));
    expect(screen.getByText("-1")).toBeInTheDocument();
    expect(screen.getByText("-2")).toBeInTheDocument();

    fireEvent.mouseEnter(screen.getByTestId("category-2"));
    expect(screen.getByText("-3")).toBeInTheDocument();
  });
});
