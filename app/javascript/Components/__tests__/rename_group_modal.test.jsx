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
  });

  it("should rename the group on successful submit", async () => {
    render(<RenameGroupModal {...props} />);
    const groupName = "new_group";
    const groupNameInput = screen.getByLabelText(
      I18n.t("activerecord.attributes.group.group_name")
    );
    fireEvent.change(groupNameInput, {
      target: {value: groupName},
    });

    const renameGroupButton = screen.getByTestId("rename-submit-button");
    fireEvent.click(renameGroupButton);

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledTimes(1);
      expect(props.onSubmit).toHaveBeenCalledWith(groupName);
      expect(groupNameInput).toHaveValue("");
    });
  });

  it("should call onRequestClose on successful call", async () => {
    render(<RenameGroupModal {...props} />);
    fireEvent.click(screen.getByText(I18n.t("cancel")));
    await waitFor(() => {
      expect(props.onRequestClose).toHaveBeenCalledTimes(1);
    });
  });

  it("should not add the new group when the inputted group name is empty", async () => {
    render(<RenameGroupModal {...props} />);
    const renameGroupButton = screen.getByTestId("rename-submit-button");
    fireEvent.click(renameGroupButton);

    await waitFor(() => {
      expect(props.onSubmit).not.toHaveBeenCalled();
    });
  });

  it("should populate input with the selected group name each time the modal opens", () => {
    const propsWithInitialName = {
      isOpen: true,
      onRequestClose: jest.fn(),
      onSubmit: jest.fn(),
      initialGroupName: "First Group Name",
    };

    const {rerender} = render(<RenameGroupModal {...propsWithInitialName} />);
    expect(screen.getByDisplayValue("First Group Name")).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(I18n.t("activerecord.attributes.group.group_name")), {
      target: {value: "Unsaved First Group Name"},
    });
    rerender(<RenameGroupModal {...propsWithInitialName} isOpen={false} initialGroupName="" />);
    rerender(
      <RenameGroupModal
        {...propsWithInitialName}
        isOpen={true}
        initialGroupName="Second Group Name"
      />
    );

    expect(screen.getByDisplayValue("Second Group Name")).toBeInTheDocument();
  });

  it("should not submit when group name is empty", async () => {
    render(<RenameGroupModal {...props} />);
    fireEvent.change(screen.getByLabelText(I18n.t("activerecord.attributes.group.group_name")), {
      target: {value: ""},
    });

    const form = document.querySelector("form");
    fireEvent.submit(form);

    expect(props.onSubmit).not.toHaveBeenCalled();
  });
});
