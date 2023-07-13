import * as React from "react";
import {render, screen, fireEvent, within, waitFor} from "@testing-library/react";
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
      sections: ["LEC0101", "LEC0202"],
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

  describe("Total Mark Range", () => {
    it("should render 2 input fields of type number", () => {
      const totalMarkFilter = screen.getByText(/Total Mark/i).closest("div");

      const minInput = within(totalMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalMarkFilter).getByPlaceholderText(/Max/i);
      expect(minInput).toHaveAttribute("type", "number");
      expect(maxInput).toHaveAttribute("type", "number");
    });

    it("should reset range inputs on Clear all", () => {
      const totalMarkFilter = screen.getByText(/Total Mark/i).closest("div");
      const minInput = within(totalMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: 10},
      });

      fireEvent.click(screen.getByText(/Clear All/i));
      expect(minInput).toHaveValue(null);
      expect(maxInput).toHaveValue(null);
    });

    it("should not show error message when passed valid range", () => {
      const totalMarkFilter = screen.getByText(/Total Mark/i).closest("div");
      const minInput = within(totalMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: 10},
      });
      expect(minInput).toHaveValue(0);
      expect(maxInput).toHaveValue(10);
      waitFor(
        () => expect(within(totalMarkFilter).getByText(/Invalid Range/i)).not.toBeInTheDocument
      );
    });

    it("should show error message when passed invalid range", async () => {
      const totalMarkFilter = screen.getByText(/Total Mark/i).closest("div");
      const minInput = within(totalMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: -1},
      });
      expect(minInput).toHaveValue(0);
      expect(maxInput).toHaveValue(-1);
      waitFor(() => expect(within(totalMarkFilter).getByText(/Invalid Range/i)).toBeInTheDocument);
    });
  });
  describe("Total Extra Mark Range", () => {
    it("should render 2 input fields of type number", () => {
      const totalExtraMarkFilter = screen.getByText(/Total Extra Mark/i).closest("div");
      const minInput = within(totalExtraMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalExtraMarkFilter).getByPlaceholderText(/Max/i);
      expect(minInput).toHaveAttribute("type", "number");
      expect(maxInput).toHaveAttribute("type", "number");
    });

    it("should reset range inputs on Clear all", () => {
      const totalExtraMarkFilter = screen.getByText(/Total Mark/i).closest("div");
      const minInput = within(totalExtraMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalExtraMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: 10},
      });

      fireEvent.click(screen.getByText(/Clear All/i));
      expect(minInput).toHaveValue(null);
      expect(maxInput).toHaveValue(null);
    });

    it("should not show error message when passed valid range", () => {
      const totalExtraMarkFilter = screen.getByText(/Total Extra Mark/i).closest("div");
      const minInput = within(totalExtraMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalExtraMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: 10},
      });
      expect(minInput).toHaveValue(0);
      expect(maxInput).toHaveValue(10);
      waitFor(
        () => expect(within(totalExtraMarkFilter).getByText(/Invalid Range/i)).not.toBeInTheDocument
      );
    });

    it("should show error message when passed invalid range", async () => {
      const totalExtraMarkFilter = screen.getByText(/Total Mark/i).closest("div");
      const minInput = within(totalExtraMarkFilter).getByPlaceholderText(/Min/i);
      const maxInput = within(totalExtraMarkFilter).getByPlaceholderText(/Max/i);
      fireEvent.change(minInput, {
        target: {value: 0},
      });
      fireEvent.change(maxInput, {
        target: {value: -1},
      });
      expect(minInput).toHaveValue(0);
      expect(maxInput).toHaveValue(-1);
      waitFor(
        () => expect(within(totalExtraMarkFilter).getByText(/Invalid Range/i)).toBeInTheDocument
      );
    });
  });
  describe("Single Select Dropdown Filters", () => {
    let singleSelectDropdownMakeSelection = (filterTestId, selection) => {
      it("should save the selection on submit", () => {
        let dropdownDiv = screen.getByTestId(filterTestId);
        fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
        fireEvent.click(within(dropdownDiv).getByText(selection));
        fireEvent.click(screen.getByText(/Save/i));
        props.isOpen = true;
        expect(within(screen.getByTestId(filterTestId)).getByTestId("selection")).toHaveTextContent(
          selection
        );
      });
    };
    let singleSelectDropdownClearAll = (filterTestId, selection, defaultValue) => {
      it("should reset selection on Clear all", async () => {
        let dropdownDiv = screen.getByTestId(filterTestId);
        // setting the dropdown value to some random value
        fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
        fireEvent.click(within(dropdownDiv).getByText(selection));
        //resetting the dropdown value
        fireEvent.click(screen.getByText(/Clear All/i));
        expect(within(dropdownDiv).getByTestId("selection")).toHaveTextContent(defaultValue);
      });
    };
    let singleSelectDropdownClear = (filterTestId, selection, defaultValue) => {
      it("should reset the selection and close the dropdown when the x button is clicked", () => {
        let dropdownDiv = screen.getByTestId(filterTestId);
        // setting the dropdown value to some random value
        fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
        fireEvent.click(within(dropdownDiv).getByText(selection));
        // resetting the dropdown value
        fireEvent.click(within(dropdownDiv).getByTestId("reset-dropdown-selection"));
        expect(within(dropdownDiv).getByTestId("selection")).toHaveTextContent(defaultValue);
      });
    };
    describe("Order By", () => {
      describe("selecting order subject", () => {
        singleSelectDropdownMakeSelection("order-by", "Submission Date");
        singleSelectDropdownClearAll("order-by", "Submission Date", "Group Name");
        singleSelectDropdownClear("order-by", "Submission Date", "Group Name");
        it("should show the user specific options", () => {
          let dropdownDiv = screen.getByTestId("order-by");
          fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
          const options = within(dropdownDiv).getByTestId("options");
          expect(within(options).getByText("Group Name")).toBeInTheDocument();
          expect(within(options).getByText("Submission Date")).toBeInTheDocument();
        });
      });
      describe("selecting between ascending and descending order", () => {
        it("should save the selection on submit", () => {
          // setting the ordering to descending
          fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));
          fireEvent.click(screen.getByText(/Save/i));
          props.isOpen = true;
          screen.debug();
          expect(within(screen.getByTestId("order-by")).getByTestId("descending")).toHaveAttribute(
            "checked",
            true
          );
          expect(within(screen.getByTestId("order-by")).getByTestId("ascending")).toHaveAttribute(
            "checked",
            false
          );
        });
        it("should reset ordering on clear", () => {
          // setting the ordering to descending
          fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));
          // clearing the dropdown values
          fireEvent.click(
            within(screen.getByTestId("order-by")).getByTestId("reset-dropdown-selection")
          );
          expect(within(screen.getByTestId("order-by")).getByTestId("descending")).toHaveAttribute(
            "checked",
            false
          );
          expect(within(screen.getByTestId("order-by")).getByTestId("ascending")).toHaveAttribute(
            "checked",
            true
          );
        });
        it("should reset ordering on clearAll", () => {
          // setting the ordering to descending
          fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));
          // clearing the dropdown values
          fireEvent.click(screen.getByText(/Clear All/i));
          expect(within(screen.getByTestId("order-by")).getByTestId("descending")).toHaveAttribute(
            "checked",
            false
          );
          expect(within(screen.getByTestId("order-by")).getByTestId("ascending")).toHaveAttribute(
            "checked",
            true
          );
        });
      });
    });
    describe("Filter By Section", () => {
      singleSelectDropdownMakeSelection("section", "LEC0101");
      singleSelectDropdownClearAll("section", "LEC0101", "");
      singleSelectDropdownClear("section", "LEC0101", "");
    });
    describe("Filter By Marking State", () => {
      singleSelectDropdownMakeSelection("marking-state", "Complete");
      singleSelectDropdownClearAll("marking-state", "Complete", "");
      singleSelectDropdownClear("marking-state", "Complete", "");
      it("should show the user specific options", () => {
        let dropdownDiv = screen.getByTestId("marking-state");
        fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
        dropdownDiv = screen.getByTestId("marking-state");
        expect(within(dropdownDiv).getByText("In Progress")).toBeInTheDocument();
        expect(within(dropdownDiv).getByText("Complete")).toBeInTheDocument();
        expect(within(dropdownDiv).getByText("Released")).toBeInTheDocument();
        expect(within(dropdownDiv).getByText("Remark Requested")).toBeInTheDocument();
      });
    });
  });
});
