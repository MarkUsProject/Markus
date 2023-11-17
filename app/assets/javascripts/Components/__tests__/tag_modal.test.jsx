import React from "react";
import {render, screen, fireEvent, waitFor, cleanup} from "@testing-library/react";
import TagModal from "../Helpers/tag_modal";
import Modal from "react-modal";

describe("TagModal", () => {
  let props;
  let component;

  beforeEach(() => {
    props = {
      name: "",
      description: "",
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
      tagModalHeading: "Heading",
      onSubmit: jest.fn().mockImplementation(() => (props.isOpen = false)),
      handleNameChange: jest.fn().mockImplementation(() => {}),
      handleDescriptionChange: jest.fn().mockImplementation(() => {}),
    };

    // Set the app element for React Modal
    Modal.setAppElement("body");
    component = render(<TagModal {...props} />);
  });

  afterEach(() => {
    cleanup();
  });

  it("should close on Cancel", () => {
    fireEvent.change(screen.getByTestId("tag_name_input"), {target: {value: "Name"}});
    fireEvent.click(screen.getByText(I18n.t("cancel")));
    expect(props.onRequestClose).toHaveBeenCalledTimes(1);
  });

  it("should not be submittable with empty name", () => {
    expect(screen.getByText(I18n.t("save"))).toBeDisabled();
  });

  it("should render correct headings, labels, buttons and inputs", () => {
    const headingLabelDataTestIds = [
      "tag_modal_heading",
      "tag_name_label",
      "tag_description_label",
    ];
    headingLabelDataTestIds.forEach(dataTestId => {
      expect(screen.queryByTestId(dataTestId)).toBeInTheDocument();
    });
    const buttonDataTestIds = screen
      .queryAllByRole("button", {hidden: true})
      .map(button => button.getAttribute("data-testid"));
    expect(buttonDataTestIds.sort()).toEqual(["tag_submit_button", "tag_cancel_button"].sort());
    const inputDataTestIds = screen
      .queryAllByRole("textbox", {hidden: true})
      .map(textarea => textarea.getAttribute("data-testid"));
    expect(inputDataTestIds.sort()).toEqual(["tag_name_input", "tag_description_input"].sort());
    // verify maxLength for the inputs
    expect(screen.getByTestId("tag_name_input")).toHaveAttribute("maxLength", "30");
    expect(screen.getByTestId("tag_description_input")).toHaveAttribute("maxLength", "120");
  });

  describe("When name filled", () => {
    beforeEach(() => {
      // cleanup needed here to clean up the previous beforeEach
      cleanup();

      props.name = "Name";
      // rerender with the non empty name
      component = render(<TagModal {...props} />);
    });

    it("should be submittable", async () => {
      await waitFor(() => {
        expect(screen.getByText(I18n.t("save"))).not.toBeDisabled();
      });
    });

    it("should call onSubmit on submit", async () => {
      fireEvent.click(screen.getByText(I18n.t("save")));
      await waitFor(() => {
        expect(props.onSubmit).toHaveBeenCalledTimes(1);
      });
    });
  });
});
