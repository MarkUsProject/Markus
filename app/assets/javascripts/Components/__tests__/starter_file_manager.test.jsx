import {StarterFileManager} from "../starter_file_manager";

import {mount} from "enzyme";

import React from "react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

[true, false].forEach(readOnly => {
  describe(`When a user ${
    readOnly ? "without" : "with"
  } assignment manage access visits the changes the StarterFileManager`, () => {
    let wrapper;
    const pageInfo = {
      files: [
        {
          id: 1,
          name: "New Starter File Group",
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
        {section_id: 1, section_name: "LEC0101", group_id: 1, group_name: "New Starter File Group"},
        {section_id: 2, section_name: "LEC0201", group_id: 1, group_name: "New Starter File Group"},
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

    beforeEach(() => {
      fetch.resetMocks();
      fetch.mockResponseOnce(JSON.stringify(pageInfo));
      wrapper = mount(<StarterFileManager course_id={1} assignment_id={1} read_only={readOnly} />);
    });

    it(`all buttons on the page are ${readOnly ? "disabled" : "enabled"}`, () => {
      wrapper.update();
      let buttons = wrapper.find(".button");

      // one delete button per starter file group, one add button on top of that
      expect(buttons.length).toEqual(pageInfo.files.length + 1);

      buttons.forEach(button => {
        expect(button.props()["disabled"]).toBe(readOnly);
      });
    });

    it(`the internal FileManager is ${readOnly ? "in" : "not in"} readOnly mode`, () => {
      wrapper.update();
      let fileManager = wrapper.find("StarterFileFileManager");

      expect(fileManager.props()["readOnly"]).toBe(readOnly);
    });

    it(`all radio buttons are ${readOnly ? "disabled" : "enabled"}`, () => {
      wrapper.update();
      let radioButtons = wrapper.find({type: "radio"});

      // there's 4 by design
      expect(radioButtons.length).toEqual(4);

      radioButtons.forEach(radioButton => {
        expect(radioButton.props()["disabled"]).toBe(readOnly);
      });
    });

    it(`all dropdowns on the page are ${readOnly ? "disabled" : "enabled"}`, () => {
      wrapper.update();
      let dropdowns = wrapper.find(".starter-file-dropdown");

      // one for each section, plus one for the default starter file group
      expect(dropdowns.length).toEqual(pageInfo.sections.length + 1);

      dropdowns.forEach(dropdown => {
        expect(dropdown.getDOMNode().hasAttribute("disabled")).toBe(readOnly);
      });
    });

    it(`the checkbox on the page is ${readOnly ? "disabled" : "enabled"}`, () => {
      wrapper.update();
      let checkbox = wrapper.find({type: "checkbox"});

      // only checkbox is starter files available after due
      expect(checkbox.length).toEqual(1);

      expect(checkbox.props()["disabled"]).toBe(readOnly);
    });

    it(`the submit button on the page is ${readOnly ? "disabled" : "enabled"}`, () => {
      wrapper.update();
      let submit = wrapper.find({type: "submit"});

      // only checkbox is starter files available after due
      expect(submit.length).toEqual(1);

      expect(submit.getDOMNode().hasAttribute("disabled")).toBe(readOnly);
    });
  });
});
