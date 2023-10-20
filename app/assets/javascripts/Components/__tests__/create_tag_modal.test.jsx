import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import CreateTagModal from "../Modals/create_tag_modal";
import Modal from "react-modal";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("CreateTagModal", () => {
  let props;
  let component;

  beforeAll(() => {
    process.env.AUTH_TOKEN = "token";
  });

  beforeEach(() => {
    props = {
      course_id: 1,
      assignment_id: 1,
      loading: false,
      isOpen: true,
      closeModal: jest.fn().mockImplementation(() => (props.isOpen = false)),
    };

    // Set the app element for React Modal
    Modal.setAppElement("body");
    component = render(<CreateTagModal {...props} />);
  });

  it("should not render if parent loading", () => {
    props.loading = true;
    expect(screen.queryByTestId("create_new_tag")).not.toBeInTheDocument();
  });

  it("should close on Cancel", () => {
    fireEvent.change(screen.getByTestId("tag_name"), {target: {value: "Name"}});
    fireEvent.click(screen.getByText(/Cancel/i));
    expect(props.closeModal).toHaveBeenCalled();
  });

  it("should not close on Submit when name empty", async () => {
    fireEvent.click(screen.getByText(/Save/i));
    await expect(props.closeModal).not.toHaveBeenCalled();
  });

  it("should close on Submit when name not empty", async () => {
    fireEvent.change(screen.getByTestId("tag_name"), {target: {value: "Name"}});
    fireEvent.click(screen.getByText(/Save/i));
    await expect(props.closeModal).toHaveBeenCalled();
  });
});
