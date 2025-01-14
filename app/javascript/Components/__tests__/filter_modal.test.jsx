import * as React from "react";
import {render, screen, fireEvent, within} from "@testing-library/react";
import {FilterModal} from "../Modals/filter_modal";
import Modal from "react-modal";
import {ResultContext} from "../Result/result_context";
import {renderInResultContext} from "./result_context_renderer";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("FilterModal", () => {
  let props;
  let component;

  let sharedExamplesTaAndInstructor = role => {
    beforeEach(() => {
      props = {
        filterData: {
          ascending: true,
          orderBy: "group_name",
          annotationText: "",
          tas: ["a", "b"],
          tags: ["a", "b"],
          section: "",
          markingState: "",
          totalMarkRange: {
            min: "",
            max: "",
          },
          totalExtraMarkRange: {
            min: "",
            max: "",
          },
          criteria: {
            a: {min: 0, max: 10},
            b: {min: 0},
            c: {max: 10},
            d: {min: 10, max: 0},
          },
        },
        available_tags: [{name: "a"}, {name: "b"}],
        current_tags: [{name: "c"}, {name: "d"}],
        sections: ["LEC0101", "LEC0202"],
        tas: [
          ["a", "A"],
          ["b", "B"],
          ["c", "C"],
          ["d", "D"],
        ],
        isOpen: true,
        onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
        updateFilterData: jest.fn().mockImplementation(() => null),
        clearAllFilters: jest.fn().mockImplementation(() => null),
        criterionSummaryData: [
          {criterion: "a"},
          {criterion: "b"},
          {criterion: "c"},
          {criterion: "d"},
          {criterion: "e"},
        ],
      };

      // Set the app element for React Modal
      Modal.setAppElement("body");

      component = renderInResultContext(<FilterModal {...props} />, {role: role});
    });

    it("should close on submit", () => {
      fireEvent.click(screen.getByText(/Close/i));
      expect(props.onRequestClose).toHaveBeenCalled();
    });

    it("should clear all filters when clicked on Clear All button", () => {
      fireEvent.click(screen.getByText(/Clear All/i));
      expect(props.clearAllFilters).toHaveBeenCalled();
    });

    it("should render the modal", () => {
      expect(screen.getByText(/Filter Submissions/i)).toBeInTheDocument();
      expect(screen.getByText(/Close/i)).toBeInTheDocument();
      expect(screen.getByText(/Clear All/i)).toBeInTheDocument();
    });

    describe("Filter By Annotation", () => {
      it("should render the annotation textbox", () => {
        expect(screen.getByText(/Annotation/i)).toBeInTheDocument();
        expect(screen.getByPlaceholderText(/Search Text/i)).toBeInTheDocument();
      });

      it("should save annotation text on input", () => {
        fireEvent.change(screen.getByPlaceholderText(/Search Text/i), {
          target: {value: "JavaScript"},
        });
        expect(props.updateFilterData).toHaveBeenCalled();
      });
    });

    describe("MultiSelectDropdown filters", () => {
      let multiSelectDropdownClear = test_id => {
        it("should reset tags selection when clicked on xmark icon", () => {
          const dropdown = screen.getByTestId(test_id);
          const icon = within(dropdown).getByTestId("reset");
          fireEvent.click(icon);
          expect(props.updateFilterData).toHaveBeenCalled();
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
          const option = within(dropdown).getByText(selection);
          fireEvent.click(option);

          expect(props.updateFilterData).toHaveBeenCalled();
        });
      };

      let multiSelectDropdownDeselect = (test_id, option) => {
        it("should deselect option when clicked on a tag", () => {
          const dropdown = screen.getByTestId(test_id);
          fireEvent.click(within(dropdown).getByText(option));

          expect(props.updateFilterData).toHaveBeenCalled();
        });

        it("should deselect option when clicked on a selected option", () => {
          const dropdown = screen.getByTestId(test_id);
          fireEvent.click(dropdown);
          const list = within(dropdown).getByRole("list", {hidden: true});

          //select
          const selected_option = within(list).getByText(option);
          fireEvent.click(selected_option);

          expect(props.updateFilterData).toHaveBeenCalled();
        });
      };

      describe("Filter By Tags", () => {
        const test_id = "Tags";
        multiSelectDropdownRender(test_id);
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

      let rangeOnInput = test_id => {
        it("should update props on input", () => {
          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);
          fireEvent.change(minInput, {
            target: {value: 0},
          });
          fireEvent.change(maxInput, {
            target: {value: 10},
          });

          expect(props.updateFilterData).toHaveBeenCalled();
        });
      };

      let rangeValidInput = test_id => {
        it("inputs should be valid when passed valid range", () => {
          props.filterData.totalMarkRange = {min: 0, max: 10};
          props.filterData.totalExtraMarkRange = {min: 0, max: 10};
          component.rerender(<FilterModal {...props} />);

          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);

          expect(minInput).toHaveValue(0);
          expect(maxInput).toHaveValue(10);

          expect(minInput.checkValidity()).toBe(true);
          expect(maxInput.checkValidity()).toBe(true);
        });
      };

      let rangeInvalidInput = test_id => {
        it("inputs should be invalid when passed invalid range", () => {
          props.filterData.totalMarkRange = {min: 0, max: -1};
          props.filterData.totalExtraMarkRange = {min: 0, max: -1};
          component.rerender(<FilterModal {...props} />);

          const filter = screen.getByTestId(test_id);
          const minInput = within(filter).getByPlaceholderText(/Min/i);
          const maxInput = within(filter).getByPlaceholderText(/Max/i);

          expect(minInput).toHaveValue(0);
          expect(maxInput).toHaveValue(-1);

          expect(minInput.checkValidity()).toBe(false);
          expect(maxInput.checkValidity()).toBe(false);
        });
      };

      describe("Total Mark Range", () => {
        const test_id = "Total Mark";
        rangeRender(test_id);
        rangeOnInput(test_id);
        rangeValidInput(test_id);
        rangeInvalidInput(test_id);
      });

      describe("Total Extra Mark Range", () => {
        const test_id = "Total Extra Marks";
        rangeRender(test_id);
        rangeOnInput(test_id);
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
          expect(props.updateFilterData).toHaveBeenCalled();
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
          expect(props.updateFilterData).toHaveBeenCalled();
        });
      };

      describe("Order By", () => {
        describe("selecting order subject", () => {
          singleSelectDropdownMakeSelection("order-by", "Submission Date");
          singleSelectDropdownClear("order-by", "Submission Date", "Group Name");

          it("should show the user specific options", () => {
            let dropdownDiv = screen.getByTestId("order-by");
            fireEvent.click(within(dropdownDiv).getByTestId("dropdown"));
            const options = within(dropdownDiv).getByTestId("options");
            expect(within(options).getByText("Group name")).toBeInTheDocument();
            expect(within(options).getByText("Submission Date")).toBeInTheDocument();
          });
        });

        describe("selecting between ascending and descending order", () => {
          it("should save the selection on change", () => {
            // setting the ordering to descending
            fireEvent.click(within(screen.getByTestId("order-by")).getByTestId("descending"));
            expect(props.updateFilterData).toHaveBeenCalled();
          });
        });
      });

      describe("Filter By Section", () => {
        singleSelectDropdownMakeSelection("section", "LEC0101");
        singleSelectDropdownClear("section", "LEC0101", "");
      });

      describe("Filter By Marking State", () => {
        singleSelectDropdownMakeSelection("marking-state", "Complete");
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

    describe("Criteria Filter", () => {
      it("should render the criteria filter component", () => {
        expect(screen.getByText("Criteria")).toBeInTheDocument();
      });

      it("should add the selected criterion", () => {
        const criteria = screen.getByTestId("criteria");
        const dropdown = within(criteria).getByTestId("dropdown");
        const button = within(criteria).getByRole("button", {hidden: true});

        //select option
        fireEvent.click(dropdown);
        fireEvent.click(within(dropdown).getByText("e"));

        //add criterion
        fireEvent.click(button);
        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should delete a criterion", () => {
        const criteria = screen.getByTestId("criteria");
        const listItems = within(criteria).getAllByRole("listitem", {hidden: true});
        const listItem = listItems[0];
        const xmark = within(listItem).getByTestId("remove-criterion");

        fireEvent.click(xmark);

        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should update minimum value on input", () => {
        const criteria = screen.getByTestId("criteria");
        const listItems = within(criteria).getAllByRole("listitem", {hidden: true});
        const listItem = listItems[0];
        const minInput = within(listItem).getByPlaceholderText("Min");

        fireEvent.change(minInput, {
          target: {value: 1},
        });

        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should update maximum value on input", () => {
        const criteria = screen.getByTestId("criteria");
        const listItems = within(criteria).getAllByRole("listitem", {hidden: true});
        const listItem = listItems[0];
        const maxInput = within(listItem).getByPlaceholderText("Max");

        fireEvent.change(maxInput, {
          target: {value: 1},
        });

        expect(props.updateFilterData).toHaveBeenCalled();
      });
    });
  };

  describe("An Instructor", () => {
    sharedExamplesTaAndInstructor("Instructor");

    describe("Filter by Tas", () => {
      const test_id = "Tas";

      it("should reset tags selection when clicked on xmark icon", () => {
        const dropdown = screen.getByTestId(test_id);
        const icon = within(dropdown).getByTestId("reset");
        fireEvent.click(icon);
        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should render all selected tags", () => {
        const dropdown = screen.getByTestId(test_id);
        const tags = dropdown.getElementsByClassName("tag");
        expect(tags).toHaveLength(2);
      });

      it("should select option when clicked on an option", () => {
        const dropdown = screen.getByTestId(test_id);
        fireEvent.click(dropdown);
        const option = within(dropdown).getByText("d - D");
        fireEvent.click(option);

        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should deselect option when clicked on a tag", () => {
        const dropdown = screen.getByTestId(test_id);
        const tag = within(dropdown).getByText("a");
        fireEvent.click(tag);

        expect(props.updateFilterData).toHaveBeenCalled();
      });

      it("should deselect option when clicked on a selected option", () => {
        const dropdown = screen.getByTestId(test_id);
        fireEvent.click(dropdown);
        const selected_option = within(dropdown).getByText("a - A");
        fireEvent.click(selected_option);

        expect(props.updateFilterData).toHaveBeenCalled();
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
