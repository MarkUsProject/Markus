import React from "react";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import RenameGroupModal from "../Modals/rename_group_modal";
import Modal from "react-modal";
import {expect} from "@jest/globals";

describe("RenameGroupModal", () => {
  let props;

  beforeEach(() => {
    props = {
      isOpen: true,
      onRequestClose: jest.fn(),
      onSubmit: jest.fn(),
    };

    Modal.setAppElement("body");
    render(<RenameGroupModal {...props} />);
  });

  it("should rename the group on successful submit", async () => {
    const groupName = "new_group";
    fireEvent.change(screen.getByLabelText(I18n.t("activerecord.attributes.group.group_name")), {
      target: {value: groupName},
    });

    const renameGroupButton = screen.getByTestId("rename-submit-button");
    fireEvent.click(renameGroupButton);

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

  it("should not add the new group when the inputted group name is empty", async () => {
    const renameGroupButton = screen.getByTestId("rename-submit-button");
    fireEvent.click(renameGroupButton);

    await waitFor(() => {
      expect(props.onSubmit).not.toHaveBeenCalled();
    });
  });
});
