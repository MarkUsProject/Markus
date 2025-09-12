import React from "react";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import CreateGroupModal from "../Modals/create_group_modal";
import Modal from "react-modal";

describe("CreateGroupModal", () => {
  let props;

  beforeEach(() => {
    props = {
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
      onSubmit: jest.fn(),
    };

    Modal.setAppElement("body");
    render(<CreateGroupModal {...props} />);
  });

  it("should add the correct group name on successful submit", async () => {
    const groupName = "Test Group";
    fireEvent.change(screen.getByLabelText(I18n.t("activerecord.models.group.one")), {
      target: {value: groupName},
    });

    const createGroupButton = screen
      .getAllByText(
        I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})
      )
      .find(el => el.tagName.toLowerCase() === "button");

    fireEvent.click(createGroupButton);

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledTimes(1);
      expect(props.onSubmit).toHaveBeenCalledWith(groupName);
    });
  });

  it("should call onRequestClose on successful submit", async () => {
    fireEvent.click(screen.getByText(I18n.t("cancel")));
    await waitFor(() => {
      expect(props.onRequestClose).toHaveBeenCalledTimes(1);
    });
  });

  it("should not submit when group name is empty", async () => {
    const createGroupButton = screen
      .getAllByText(
        I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})
      )
      .find(el => el.tagName.toLowerCase() === "button");
    fireEvent.click(createGroupButton);

    await waitFor(() => {
      expect(props.onSubmit).not.toHaveBeenCalled();
    });
  });
});
