import * as React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {FilterModal} from "../Modals/filter_modal";

describe("FilterModal", () => {
  let props;

  beforeEach(() => {
    props = {
      filterData: {
        ascBool: true,
        orderBy: "Group Name",
        annotationValue: "",
        tas: ["abc", "def"],
        tags: ["abc", "def"],
        sectionValue: "",
        markingStateValue: "",
        totalMarkRange: {
          min: "",
          max: "",
        },
        totalExtraMarkRange: {
          min: "",
          max: "",
        },
      },
      available_tags: ["abc", "def"],
      current_tags: ["jhk", "lmp"],
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
      mutateFilterData: jest.fn().mockImplementation(() => null),
    };
    render(<FilterModal {...props} />);
  });

  it("should close on submit", () => {
    fireEvent.click(screen.getByText(/Save/i));
    expect(props.onRequestClose).toHaveBeenCalled();
  });

  it("should save filters on submit", () => {
    fireEvent.click(screen.getByText(/Save/i));
    expect(props.mutateFilterData).toHaveBeenCalled();
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

  describe("Filter By Tags", () => {
    it("should reset tags selection on Clear all", async () => {
      const dropdown = screen.getByTestId(/Tags/i);
      fireEvent.click(screen.getByText(/Clear All/i));
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(0);
    });

    it("should save render all selected tags", () => {
      const dropdown = screen.getByTestId(/Tags/i);
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(2);
    });
  });

  describe("Filter By Tas", () => {
    it("should reset tas selection on Clear all", () => {
      const dropdown = screen.getByTestId(/Tas/i);
      fireEvent.click(screen.getByText(/Clear All/i));
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(0);
    });

    it("should save render all selected tas", () => {
      const dropdown = screen.getByTestId(/Tas/i);
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(2);
    });
  });
});
