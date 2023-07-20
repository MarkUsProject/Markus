import * as React from "react";
import {render, screen, fireEvent, within} from "@testing-library/react";
import {FilterModal} from "../Modals/filter_modal";
import Modal from "react-modal";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("FilterModal", () => {
  let props;

  let sharedExamplesTaAndInstructor = role => {
    beforeEach(() => {
      props = {
        filterData: {
          ascBool: true,
          orderBy: "Group Name",
          annotationValue: "",
          tas: ["a", "b"],
          tags: ["a", "b"],
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
        available_tags: [{name: "a"}, {name: "b"}],
        current_tags: [{name: "c"}, {name: "d"}],
        sections: ["LEC0101", "LEC0202"],
        tas: ["a", "b", "c", "d"],
        isOpen: true,
        onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
        mutateFilterData: jest.fn().mockImplementation(() => null),
        role: role,
      };

      // Set the app element for React Modal
      Modal.setAppElement("body");
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

    describe("MultiSelectDropdown filters", () => {
      let multiSelectDropdownClearAll = test_id => {
        it("should reset selection on Clear all button", () => {
          const dropdown = screen.getByTestId(test_id);
          fireEvent.click(screen.getByText(/Clear All/i));
          const tags = dropdown.getElementsByClassName("tag");
          expect(tags).toHaveLength(0);
        });
      };

      let multiSelectDropdownClear = test_id => {
        it("should reset tags selection when clicked on xmark icon", () => {
          const dropdown = screen.getByTestId(test_id);
          const icon = within(dropdown).getByTestId("reset");
          fireEvent.click(icon);
          const tags = dropdown.getElementsByClassName("tag");
          expect(tags).toHaveLength(0);
        });
      };

      let multiSelectDropdownRender = test_id => {
        it("should render all selected tags", () => {
          const dropdown = screen.getByTestId(test_id);
          const tags = dropdown.getElementsByClassName("tag");
          expect(tags).toHaveLength(2);
        });
      };

      let multiSelectDropdownMakeSelection = (test_id, selection) => {
        it("should select option when clicked on an option", () => {
          const dropdown = screen.getByTestId(test_id);
          fireEvent.click(dropdown);

          //select
          const option = within(dropdown).getByLabelText(selection);
          fireEvent.click(option);

          //check if option checked in dropdown
          expect(option).toBeChecked();
          fireEvent.click(dropdown);

          //check if tag added to list of selected options
          expect(within(dropdown).queryByText(selection)).toBeInTheDocument();
        });
      };

      let multiSelectDropdownDeselect = (test_id, option) => {
        it("should deselect option when clicked on a tag", () => {
          const dropdown = screen.getByTestId(test_id);
          const tag = within(dropdown).getByText(option);
          fireEvent.click(tag);

          //check if tag removed from list of selected options
          expect(within(dropdown).queryByText(option)).not.toBeInTheDocument();

          //check if option unchecked from dropdown
          fireEvent.click(dropdown);
          const selected_option = within(dropdown).getByLabelText(option);
          expect(selected_option).not.toBeChecked();
        });

        it("should deselect option when clicked on a selected option", () => {
          const dropdown = screen.getByTestId(test_id);
          fireEvent.click(dropdown);

          //select
          const selected_option = within(dropdown).getByLabelText(option);
          fireEvent.click(selected_option);

          //check if option unchecked from dropdown
          expect(selected_option).not.toBeChecked();

          //check if tag removed from list of selected options
          fireEvent.click(dropdown);
          expect(within(dropdown).queryByText(option)).not.toBeInTheDocument();
        });
      };

      describe("Filter By Tags", () => {
        const test_id = "Tags";
        multiSelectDropdownRender(test_id);
        multiSelectDropdownClearAll(test_id);
        multiSelectDropdownClear(test_id);
        multiSelectDropdownMakeSelection(test_id, "d");
        multiSelectDropdownDeselect(test_id, "a");
      });
    });

    describe("Range filters", () => {
      let rangeRender = test_id => {
        it("should render 2 input fields of type number", () => {
          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);
          expect(minInput).toHaveAttribute("type", "number");
          expect(maxInput).toHaveAttribute("type", "number");
        });
      };

      let rangeClearAll = test_id => {
        it("should reset range inputs on Clear all", () => {
          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);
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
      };

      let rangeValidInput = test_id => {
        it("inputs should be valid when passed valid range", () => {
          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);
          fireEvent.change(minInput, {
            target: {value: 0},
          });
          fireEvent.change(maxInput, {
            target: {value: 10},
          });
          expect(minInput).toHaveValue(0);
          expect(maxInput).toHaveValue(10);

          // Check the validity of the inputs
          expect(minInput.checkValidity()).toBe(true);
          expect(maxInput.checkValidity()).toBe(true);
        });
      };

      let rangeInvalidInput = test_id => {
        it("inputs should be invalid when passed invalid range", () => {
          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);
          fireEvent.change(minInput, {
            target: {value: 0},
          });
          fireEvent.change(maxInput, {
            target: {value: -1},
          });
          expect(minInput).toHaveValue(0);
          expect(maxInput).toHaveValue(-1);

          // Check the validity of the inputs
          expect(minInput.checkValidity()).toBe(false);
          expect(maxInput.checkValidity()).toBe(false);
        });
      };

      describe("Total Mark Range", () => {
        const test_id = "Total Mark";
        rangeRender(test_id);
        rangeClearAll(test_id);
        rangeValidInput(test_id);
        rangeInvalidInput(test_id);
      });

      describe("Total Extra Mark Range", () => {
        const test_id = "Total Extra Mark";
        rangeRender(test_id);
        rangeClearAll(test_id);
        rangeValidInput(test_id);
        rangeInvalidInput(test_id);
      });
    });

    describe("Single Select Dropdown Filters", () => {
      let singleSelectDropdownMakeSelection = (filterTestId, selection) => {
        it("should change the selection", () => {
          let dropdownDiv = screen.getByTestId(filterTestId);
          fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
          fireEvent.click(within(dropdownDiv).getByText(selection));
          expect(
            within(screen.getByTestId(filterTestId)).getByTestId("selection")
          ).toHaveTextContent(selection);
        });
      };

      let singleSelectDropdownClearAll = (filterTestId, selection, defaultValue) => {
        it("should reset selection on Clear all", () => {
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
          it("should save the selection on change", () => {
            // setting the ordering to descending
            fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));
            expect(within(screen.getByTestId("order-by")).getByTestId("descending")).toBeChecked();
            expect(
              within(screen.getByTestId("order-by")).getByTestId("ascending")
            ).not.toBeChecked();
          });

          it("should reset ordering on clearAll", () => {
            // setting the ordering to descending
            fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));

            // clearing the dropdown values
            fireEvent.click(screen.getByText(/Clear All/i));
            expect(
              within(screen.getByTestId("order-by")).getByTestId("descending")
            ).not.toBeChecked();
            expect(within(screen.getByTestId("order-by")).getByTestId("ascending")).toBeChecked();
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
  };

  describe("An Instructor", () => {
    sharedExamplesTaAndInstructor("Instructor");

    describe("Filter by Tas", () => {
      const test_id = "Tas";

      it("should reset selection on Clear all button", () => {
        const dropdown = screen.getByTestId(test_id);
        fireEvent.click(screen.getByText(/Clear All/i));
        const tags = dropdown.getElementsByClassName("tag");
        expect(tags).toHaveLength(0);
      });

      it("should reset tags selection when clicked on xmark icon", () => {
        const dropdown = screen.getByTestId(test_id);
        const icon = within(dropdown).getByTestId("reset");
        fireEvent.click(icon);
        const tags = dropdown.getElementsByClassName("tag");
        expect(tags).toHaveLength(0);
      });

      it("should render all selected tags", () => {
        const dropdown = screen.getByTestId(test_id);
        const tags = dropdown.getElementsByClassName("tag");
        expect(tags).toHaveLength(2);
      });

      it("should select option when clicked on an option", () => {
        const dropdown = screen.getByTestId(test_id);
        fireEvent.click(dropdown);
        const option = within(dropdown).getByLabelText("d");
        fireEvent.click(option);

        //check if option checked in dropdown
        expect(option).toBeChecked();
        fireEvent.click(dropdown);

        //check if tag added to list of selected options
        expect(within(dropdown).queryByText("d")).toBeInTheDocument();
      });

      it("should deselect option when clicked on a tag", () => {
        const dropdown = screen.getByTestId(test_id);
        const tag = within(dropdown).getByText("a");
        fireEvent.click(tag);

        //check if tag removed from list of selected options
        expect(within(dropdown).queryByText("a")).not.toBeInTheDocument();

        //check if option unchecked from dropdown
        fireEvent.click(dropdown);
        const selected_option = within(dropdown).getByLabelText("a");
        expect(selected_option).not.toBeChecked();
      });

      it("should deselect option when clicked on a selected option", () => {
        const dropdown = screen.getByTestId(test_id);
        fireEvent.click(dropdown);
        const selected_option = within(dropdown).getByLabelText("a");
        fireEvent.click(selected_option);

        //check if option unchecked from dropdown
        expect(selected_option).not.toBeChecked();

        //check if tag removed from list of selected options
        fireEvent.click(dropdown);
        expect(within(dropdown).queryByText("a")).not.toBeInTheDocument();
      });
    });
  });

  describe("A Ta", () => {
    sharedExamplesTaAndInstructor("Ta");

    describe("Filter by Tas", () => {
      it("should not render filter by tas", () => {
        const dropdown = screen.queryByTestId("Tas");
        expect(dropdown).not.toBeInTheDocument();
      });
    });
  });
});
