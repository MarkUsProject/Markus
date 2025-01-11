import {StarterFileManager} from "../starter_file_manager";
import {render, screen} from "@testing-library/react";

import React from "react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

[true, false].forEach(readOnly => {
  let container;
  describe(`When a user ${
    readOnly ? "without" : "with"
  } assignment manage access visits the changes the StarterFileManager`, () => {
    const pageInfo = {
      files: [
        {
          id: 1,
          name: "My Starter File Group",
          entry_rename: "",
          use_rename: false,
          files: [
            {
              key: "a4.pdf",
              size: 1,
              submitted_date: "Thursday, March 14, 2024, 06:34:51 PM EDT",
              url: "http://localhost:3000/csc108/courses/1/starter_file_groups/1/download_file?file_name=a4.pdf",
            },
          ],
        },
      ],
      sections: [
        {section_id: 1, section_name: "LEC0101", group_id: 1, group_name: "My Starter File Group"},
        {section_id: 2, section_name: "LEC0201", group_id: 1, group_name: "My Starter File Group"},
      ],
      available_after_due: true,
      starterfileType: "sections",
      defaultStarterFileGroup: 1,
    };

    // for the case where this is read only, we don't want to have the form as
    // changed because that's impossible
    //
    // for the case where this is NOT read only, we want to simulate page changed
    // so submit button is enabled (the point is to ensure this is possible)
    pageInfo.form_changed = !readOnly;

    beforeEach(async () => {
      fetch.resetMocks();
      fetch.mockResponseOnce(JSON.stringify(pageInfo));

      container = render(
        <StarterFileManager course_id={1} assignment_id={1} read_only={readOnly} />
      );
      await screen.findByRole("link", {name: "My Starter File Group"});
    });

    it(`all buttons on the page are ${readOnly ? "disabled" : "enabled"}`, () => {
      const buttons = screen.getAllByRole("button", {
        name: new RegExp(`${I18n.t("assignments.starter_file.aria_labels.action_button")}`),
      });

      // one delete button per starter file group, one add button on top of that
      expect(buttons).toHaveLength(pageInfo.files.length + 1);

      buttons.forEach(button => {
        if (readOnly) {
          expect(button).toBeDisabled();
        } else {
          expect(button).not.toBeDisabled();
        }
      });
    });

    it(`all radio buttons are ${readOnly ? "disabled" : "enabled"}`, () => {
      const radioButtons = screen.getAllByRole("radio");

      // there's exactly 4 at all times
      expect(radioButtons).toHaveLength(4);

      radioButtons.forEach(radioButton => {
        if (readOnly) {
          expect(radioButton).toBeDisabled();
        } else {
          expect(radioButton).not.toBeDisabled();
        }
      });
    });

    it(`all dropdowns on the page are ${readOnly ? "disabled" : "enabled"}`, () => {
      const dropdowns = screen.getAllByRole("combobox", {
        name: new RegExp(`${I18n.t("assignments.starter_file.aria_labels.dropdown")}`),
      });

      // one for each section, plus one for the default starter file group
      expect(dropdowns).toHaveLength(pageInfo.sections.length + 1);

      dropdowns.forEach(dropdown => {
        if (readOnly) {
          expect(dropdown).toBeDisabled();
        } else {
          expect(dropdown).not.toBeDisabled();
        }
      });
    });

    it(`the checkbox on the page is ${readOnly ? "disabled" : "enabled"}`, () => {
      // should only be one
      const checkbox = screen.getByTestId("available_after_due_checkbox");

      if (readOnly) {
        expect(checkbox).toBeDisabled();
      } else {
        expect(checkbox).not.toBeDisabled();
      }
    });

    it(`the submit button on the page is ${readOnly ? "disabled" : "enabled"}`, () => {
      // should only be one
      const saveButton = screen.getByTestId("save_button");

      if (readOnly) {
        expect(saveButton).toBeDisabled();
      } else {
        expect(saveButton).not.toBeDisabled();
      }
    });
  });
});
