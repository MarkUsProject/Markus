import React from "react";
import {render, screen, fireEvent, waitFor, cleanup} from "@testing-library/react";
import AssignmentGroupUseModal from "../Modals/assignment_group_use_modal";
import Modal from "react-modal";

describe("AssignmentGroupUseModal", () => {
  let props;
  let mockCloneAssignments;

  beforeEach(() => {
    mockCloneAssignments = [
      {id: 1, short_identifier: "Assignment 1"},
      {id: 2, short_identifier: "Assignment 2"},
      {id: 3, short_identifier: "Assignment 3"},
    ];
    props = {
      isOpen: true,
      onRequestClose: jest.fn(),
      onSubmit: jest.fn(),
      cloneAssignments: mockCloneAssignments,
    };

    Modal.setAppElement("body");
    global.confirm = jest.fn(() => true);
  });

  afterEach(() => {
    cleanup();
  });

  it("should display all clonable assignments in the dropdown", () => {
    render(<AssignmentGroupUseModal {...props} />);

    mockCloneAssignments.forEach(assignment => {
      expect(screen.getByText(assignment.short_identifier)).toBeInTheDocument();
    });
  });

  it("should set assignmentId to first assignment when modal opens with assignments", async () => {
    const closedProps = {...props, isOpen: false};
    const {rerender} = render(<AssignmentGroupUseModal {...closedProps} />);

    rerender(<AssignmentGroupUseModal {...{...closedProps, isOpen: true}} />);

    await waitFor(() => {
      const select = document.getElementById("assignment-group-select");
      expect(select.value).toBe("1");
    });
  });

  it("should call onSubmit with selected assignment ID on successful submit", async () => {
    render(<AssignmentGroupUseModal {...props} />);

    const select = document.getElementById("assignment-group-select");
    fireEvent.change(select, {target: {value: "2"}});

    fireEvent.click(screen.getByText(I18n.t("save")));

    await waitFor(() => {
      expect(global.confirm).toHaveBeenCalledWith(I18n.t("groups.delete_groups_linked"));
      expect(props.onSubmit).toHaveBeenCalledWith("2");
    });

    expect(screen.getByText(I18n.t("working"))).toBeInTheDocument();
    expect(screen.getByText(I18n.t("working"))).toBeDisabled();
  });

  it("should call onRequestClose when cancel button is clicked", () => {
    render(<AssignmentGroupUseModal {...props} />);

    fireEvent.click(screen.getByText(I18n.t("cancel")));
    expect(props.onRequestClose).toHaveBeenCalledTimes(1);
  });

  it("calls confirm and does not submit when user cancels", () => {
    global.confirm = jest.fn(() => false);
    render(<AssignmentGroupUseModal {...props} />);

    const select = document.getElementById("assignment-group-select");
    fireEvent.change(select, {target: {value: "3"}});

    fireEvent.click(screen.getByText(I18n.t("save")));

    expect(global.confirm).toHaveBeenCalledWith(I18n.t("groups.delete_groups_linked"));
    expect(props.onSubmit).not.toHaveBeenCalled();
  });

  it("calls confirm and submits when user confirms", async () => {
    global.confirm = jest.fn(() => true);
    render(<AssignmentGroupUseModal {...props} />);

    const select = document.getElementById("assignment-group-select");
    fireEvent.change(select, {target: {value: "3"}});

    fireEvent.click(screen.getByText(I18n.t("save")));

    await waitFor(() => {
      expect(global.confirm).toHaveBeenCalledWith(I18n.t("groups.delete_groups_linked"));
      expect(props.onSubmit).toHaveBeenCalledWith("3");
    });
  });

  it("should disable save button when no assignments are available", () => {
    const emptyProps = {...props, cloneAssignments: []};
    render(<AssignmentGroupUseModal {...emptyProps} />);

    expect(screen.getByText(I18n.t("save"))).toBeDisabled();
  });

  it("should set assignmentId to empty string when modal opens with no assignments", async () => {
    const emptyProps = {...props, isOpen: false, cloneAssignments: []};
    const {rerender} = render(<AssignmentGroupUseModal {...emptyProps} />);

    rerender(<AssignmentGroupUseModal {...{...emptyProps, isOpen: true}} />);

    await waitFor(() => {
      const select = document.getElementById("assignment-group-select");
      expect(select.length).toBe(0);
    });
  });
});
