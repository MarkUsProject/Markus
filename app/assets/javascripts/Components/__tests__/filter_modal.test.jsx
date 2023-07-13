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
});
