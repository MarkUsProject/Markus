import {StudentsActionBox} from "../student_table";
import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import "@testing-library/jest-dom";

//unit test
describe("For the StudentsActionBox component's rendering", () => {
  beforeEach(() => {
    render(<StudentsActionBox />);
  });
  describe("the parent component", () => {
    it("renders", () => {
      const action_box = screen.getByTestId("student_action_box");
      expect(action_box).toBeInTheDocument();
    });

    it("renders a child select element", () => {
      expect(screen.getByRole("combobox")).toBeInTheDocument;
    });
  });

  describe("The select element", () => {
    it("renders 4 options", () => {
      expect(screen.getAllByRole("option").length).toEqual(4);
    });

    it("has option elements equal to the specified displayed text", () => {
      [
        I18n.t("students.instructor_actions.give_grace_credits"),
        I18n.t("students.instructor_actions.add_section"),
        I18n.t("students.instructor_actions.mark_inactive"),
        I18n.t("students.instructor_actions.mark_active"),
      ].forEach(text => {
        expect(screen.getByRole("option", {name: text})).toBeInTheDocument();
      });
    });
  });
});

describe("For the StudentsActionBox component's props", () => {
  describe("when the state action is give_grace_credits", () => {
    beforeEach(() => {
      render(<StudentsActionBox />);
      fireEvent.change(screen.getByTestId("student_action_box_select"), {
        target: {value: "give_grace_credits"},
      });
    });

    it("has the give_grace_credits selected", () => {
      let options = screen.getAllByTestId("student_action_box_select");
      expect(options[0]).toBeTruthy();
      expect(options[1]).toBeFalsy();
      expect(options[2]).toBeFalsy();
      expect(options[3]).toBeFalsy();
    });
  });

  describe("when the state action is update_section", () => {
    describe("if the sections' prop's length > 0", () => {
      beforeEach(() => {
        render(<StudentsActionBox sections={{LEC0101: "LEC0101", LEC0102: "LEC0102"}} />);
        fireEvent.change(screen.getByTestId("student_action_box_select"), {
          target: {value: "update_section"},
        });
      });

      it("renders a select field with all the sections as individual options", () => {
        let options = screen.getByTestId("student_action_box_update_section");
        expect(options[0].value).toEqual("LEC0101");
        expect(options[1].value).toEqual("LEC0102");
      });
    });

    describe("if the sections' prop's length == 0", () => {
      beforeEach(() => {
        render(<StudentsActionBox sections={{}} />);
        fireEvent.change(screen.getByTestId("student_action_box_select"), {
          target: {value: "update_section"},
        });
      });

      it("renders a text that says there's no sections yet", () => {
        expect(screen.getByText(I18n.t("sections.none"))).toBeInTheDocument();
      });
    });
  });
});
