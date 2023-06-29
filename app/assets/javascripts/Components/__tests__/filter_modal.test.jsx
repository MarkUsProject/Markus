import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {FilterModal} from "../Modals/filter_modal";

describe("FilterModal", () => {
  let props;

  beforeEach(() => {
    props = {
      filterData: {annotationValue: ""},
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
    };
    render(<FilterModal {...props} />);
  });

  it("should close on submit", () => {
    fireEvent.click(screen.getByText(/Save/i));
    expect(props.onRequestClose).toHaveBeenCalled();
  });

  it("should render the modal", () => {
    expect(screen.getByText(/Filter By:/i)).toBeInTheDocument();
    expect(screen.getByText(/Save/i)).toBeInTheDocument();
    expect(screen.getByText(/Clear All/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Annotation/i)).toBeInTheDocument();
  });

  describe("Filter By Annotation", () => {
    it("should reset annotation textbox on Clear all", () => {
      fireEvent.change(screen.getByLabelText("Annotation"), {
        target: {value: "JavaScript"},
      });
      fireEvent.click(screen.getByText(/Clear All/i));
      expect(screen.getByLabelText("Annotation")).toHaveValue("");
    });

    it("should save annotation text on submit", () => {
      fireEvent.change(screen.getByLabelText("Annotation"), {
        target: {value: "JavaScript"},
      });
      fireEvent.click(screen.getByText(/Save/i));
      props.isOpen = true;
      expect(screen.getByLabelText("Annotation")).toHaveValue("JavaScript");
    });
  });
});
