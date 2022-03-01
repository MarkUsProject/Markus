// https://github.com/facebook/jest/issues/8217
// import $ from "jquery/src/jquery";
import $ from "jquery";
window.$ = window.jQuery = $;

import * as I18n from "i18n-js";
import "translations";
window.I18n = I18n;

import {RawStudentTable, StudentsActionBox} from "../student_table";
import React from "react";
import {render, screen} from "@testing-library/react";
import "@testing-library/jest-dom";

//unit test
describe("For the student_table component", () => {
  beforeEach(() => {
    render(<StudentsActionBox />);
  });
  describe("The parent component", () => {
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
