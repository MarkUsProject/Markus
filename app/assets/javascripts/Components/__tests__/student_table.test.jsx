import {StudentTable} from "../student_table";
import {render, screen, within} from "@testing-library/react";

import {mount} from "enzyme";
// Unit test
describe("For the RawStudentTable component's rendering", () => {
  beforeEach(() => {
    render(<StudentTable selection={["c5anthei"]} course_id={1} />);
  });

  describe("the parent component", () => {
    it("renders", () => {
      expect(screen.getByTestId("raw_student_table")).toBeInTheDocument();
    });

    it("renders a child StudentsActionBox", () => {
      expect(within(screen.getByTestId("raw_student_table")).getByTestId("student_action_box"))
        .toBeInTheDocument;
    });

    it("renders a child CheckboxTable containing the specified headers", () => {
      [
        I18n.t("activerecord.attributes.user.user_name"),
        I18n.t("activerecord.attributes.user.first_name"),
        I18n.t("activerecord.attributes.user.last_name"),
        I18n.t("activerecord.attributes.user.email"),
        I18n.t("activerecord.attributes.user.id_number"),
        I18n.t("activerecord.models.section", {count: 1}),
        I18n.t("activerecord.attributes.user.grace_credits"),
        I18n.t("students.active") + "?",
        I18n.t("actions"),
      ].forEach(text => {
        expect(within(screen.getByTestId("raw_student_table")).getByText(text)).toBeInTheDocument;
      });
    });
  });
});

describe("For the RawStudentTable component's states and props", () => {
  describe("submitting the child StudentsActionBox component", () => {
    let wrapper, form;
    beforeAll(() => {
      wrapper = mount(<StudentTable selection={["c5anthei"]} course_id={1} />);
      form = wrapper.find("form").first();
    });

    it("sets loading to false", () => {
      form.simulate("submit", () => {
        expect(wrapper.instance().wrapped.state.loading).toEqual(false);
      });
    });

    it("sets selection to empty list", () => {
      form.simulate("submit", () => {
        expect(wrapper.instance().wrapped.state.selection).toEqual([]);
      });
    });

    it("sets selectAll to false", () => {
      form.simulate("submit", () => {
        expect(wrapper.instance().wrapped.state.selectAll).toEqual(false);
      });
    });
  });

  describe("each filterable column has a custom filter method", () => {
    let wrapper, filter_method;
    beforeAll(() => {
      wrapper = mount(<StudentTable selection={["c5anthei"]} course_id={1} />);
    });

    describe("the filter method for the section column", () => {
      beforeAll(() => {
        filter_method =
          wrapper.instance().wrapped.checkboxTable.wrappedInstance.props.columns[6].filterMethod;
      });

      it("returns true when the selected value is all", () => {
        expect(filter_method({value: "all"})).toEqual(true);
      });

      it("returns true when the row's section index equals to the selected value", () => {
        // sets data.sections
        wrapper.instance().wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // sample row
        const sample_row = {section: 1};
        expect(filter_method({id: "section", value: "LEC0101"}, sample_row)).toEqual(true);
      });

      it("returns false when the row's section index doesn't equal to the selected value", () => {
        // sets data.sections
        wrapper.instance().wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // sample row
        const sample_row = {section: 2};
        expect(filter_method({id: "section", value: "LEC0101"}, sample_row)).toEqual(false);
      });
    });

    describe("the filter method for the grace credits column", () => {
      beforeAll(() => {
        filter_method =
          wrapper.instance().wrapped.checkboxTable.wrappedInstance.props.columns[7].filterMethod;
      });

      it("returns true when the input equals to the row's remaining grace credits", () => {
        const sample_row = {
          _original: {
            remaining_grace_credits: 4,
          },
        };
        expect(filter_method({value: 4}, sample_row)).toEqual(true);
      });

      it("returns true when the input is not a number", () => {
        const sample_row = {
          _original: {
            remaining_grace_credits: 4,
          },
        };
        expect(filter_method({value: "unlimited"}, sample_row)).toEqual(true);
      });

      it("returns false when the input a number and doesn't equal to the row's remaining grace credits", () => {
        const sample_row = {
          _original: {
            remaining_grace_credits: 4,
          },
        };
        expect(filter_method({value: 3}, sample_row)).toEqual(false);
      });
    });

    describe("the filter method for the active column", () => {
      beforeAll(() => {
        filter_method =
          wrapper.instance().wrapped.checkboxTable.wrappedInstance.props.columns[8].filterMethod;
      });

      it("returns true when the selected value is all", () => {
        expect(filter_method({value: "all"})).toEqual(true);
      });

      it("returns true when the selected value is active and inactive is false", () => {
        // sample row
        const sample_row = {inactive: false};
        expect(filter_method({id: "inactive", value: "active"}, sample_row)).toEqual(true);
      });

      it("returns false when the selected value is active and inactive is true", () => {
        // sample row
        const sample_row = {inactive: true};
        expect(filter_method({id: "inactive", value: "active"}, sample_row)).toEqual(false);
      });

      it("returns true when the selected value is inactive and inactive is true", () => {
        // sample row
        const sample_row = {inactive: true};
        expect(filter_method({id: "inactive", value: "inactive"}, sample_row)).toEqual(true);
      });

      it("returns false when the selected value is inactive and inactive is false", () => {
        // sample row
        const sample_row = {inactive: false};
        expect(filter_method({id: "inactive", value: "inactive"}, sample_row)).toEqual(false);
      });
    });
  });
});
