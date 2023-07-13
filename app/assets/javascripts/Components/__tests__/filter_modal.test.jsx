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
      available_tags: [{name: "abc"}, {name: "def"}],
      current_tags: [{name: "jkl"}, {name: "ghi"}],
      sections: ["LEC0101", "LEC0202"],
      tas: ["abc", "def", "jkl", "ghi"],
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
  });

  describe("Filter By Annotation", () => {
    it("should render the annotation textbox", () => {
      expect(screen.getByLabelText(/Annotation/i)).toBeInTheDocument();
    });

    it("should reset annotation textbox on Clear all", () => {
      fireEvent.change(screen.getByLabelText("Annotation"), {
        target: {value: "JavaScript"},
      });
      fireEvent.click(screen.getByText(/Clear All/i));
      expect(screen.getByLabelText("Annotation")).toHaveValue("");
    });
  });

  describe("Filter By Tags", () => {
    it("should reset tags selection on Clear all", () => {
      const dropdown = screen.getByTestId("Tags");
      fireEvent.click(screen.getByText(/Clear All/i));
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(0);
    });

    it("should render all selected tags", () => {
      const dropdown = screen.getByTestId("Tags");
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(2);
    });

    it("should select option when clicked on an option", () => {
      const dropdown = screen.getByTestId("Tags");
      fireEvent.click(dropdown);
      const option = within(dropdown).getByLabelText("ghi");
      fireEvent.click(option);
      waitFor(() => expect(option).toHaveAttribute("checked"));
      fireEvent.click(dropdown);
      expect(within(dropdown).queryByText("ghi")).toBeInTheDocument();
    });

    it("should deselect option when clicked on a tag", () => {
      const dropdown = screen.getByTestId("Tags");
      const tag = within(dropdown).getByText("abc");
      fireEvent.click(tag);
      expect(within(dropdown).queryByText("abc")).not.toBeInTheDocument();
    });

    it("should deselect option when clicked on a selected option", () => {
      const dropdown = screen.getByTestId("Tags");
      fireEvent.click(dropdown);
      const selected_option = within(dropdown).getByLabelText("abc");
      fireEvent.click(selected_option);
      waitFor(() => expect(selected_option).not.toHaveAttribute("checked"));
      fireEvent.click(dropdown);
      expect(within(dropdown).queryByText("abc")).not.toBeInTheDocument();
    });
  });

  describe("Filter By Tas", () => {
    it("should reset tas selection on Clear all", () => {
      const dropdown = screen.getByTestId("Tas");
      fireEvent.click(screen.getByText(/Clear All/i));
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(0);
    });

    it("should render all selected tas", () => {
      const dropdown = screen.getByTestId("Tas");
      const tags = dropdown.getElementsByClassName("tag");
      expect(tags).toHaveLength(2);
    });

    it("should select option when clicked on an option", () => {
      const dropdown = screen.getByTestId("Tas");
      fireEvent.click(dropdown);
      const option = within(dropdown).getByLabelText("ghi");
      fireEvent.click(option);
      waitFor(() => expect(option).toHaveAttribute("checked"));
      fireEvent.click(dropdown);
      expect(within(dropdown).queryByText("ghi")).toBeInTheDocument();
    });

    it("should deselect option when clicked on a tag", () => {
      const dropdown = screen.getByTestId("Tas");
      const tag = within(dropdown).getByText("abc");
      fireEvent.click(tag);
      expect(within(dropdown).queryByText("abc")).not.toBeInTheDocument();
    });

    it("should deselect option when clicked on a selected option", () => {
      const dropdown = screen.getByTestId("Tas");
      fireEvent.click(dropdown);
      const selected_option = within(dropdown).getByLabelText("abc");
      fireEvent.click(selected_option);
      waitFor(() => expect(selected_option).not.toHaveAttribute("checked"));
      fireEvent.click(dropdown);
      expect(within(dropdown).queryByText("abc")).not.toBeInTheDocument();
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

    it("should show error message when passed invalid range", () => {
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
