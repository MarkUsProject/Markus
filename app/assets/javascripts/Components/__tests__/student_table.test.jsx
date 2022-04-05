/*
 * Tests for the StudentTable component
 */

import {StudentTable} from "../student_table";
import {render, screen, within} from "@testing-library/react";

import {mount} from "enzyme";

describe("For the StudentTable component's states and props", () => {
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
        // Sets data.sections
        wrapper.instance().wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // Sample row
        const sample_row = {section: 1};
        expect(filter_method({id: "section", value: "LEC0101"}, sample_row)).toEqual(true);
      });

      it("returns false when the row's section index doesn't equal to the selected value", () => {
        // Sets data.sections
        wrapper.instance().wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // Sample row
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

      it("returns true when the selected value is active (i.e. not hidden) and hidden is false", () => {
        // Sample row
        const sample_row = {hidden: false};
        expect(filter_method({id: "hidden", value: "active"}, sample_row)).toEqual(true);
      });

      it("returns false when the selected value is active and hidden is true", () => {
        // Sample row
        const sample_row = {hidden: true};
        expect(filter_method({id: "hidden", value: "active"}, sample_row)).toEqual(false);
      });

      it("returns true when the selected value is inactive and hidden is true", () => {
        // Sample row
        const sample_row = {hidden: true};
        expect(filter_method({id: "hidden", value: "inactive"}, sample_row)).toEqual(true);
      });

      it("returns false when the selected value is inactive and hidden is false", () => {
        // Sample row
        const sample_row = {hidden: false};
        expect(filter_method({id: "hidden", value: "inactive"}, sample_row)).toEqual(false);
      });
    });
  });
});

describe("For the StudentTable component's rendering", () => {
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

describe("For the StudentTable's display of students", () => {
  let wrapper, students_sample;

  describe("when some students are fetched", () => {
    const student_in_one_row = (wrapper, student) => {
      // Find the row
      const row = wrapper.find({children: student.first_name}).parent();
      // Expect the row to contain these information
      expect(row.children({children: student.last_name})).toBeTruthy();
      expect(row.children({children: student.email})).toBeTruthy();
      expect(row.children({children: student.id_number})).toBeTruthy();
      expect(
        row.children({
          children: student.section
            ? wrapper.instance().wrapped.state.data.sections[student.section]
            : "",
        })
      ).toBeTruthy();
      expect(
        row.children({children: `${student.remaining_grace_credits} / ${student.grace_credits}`})
      ).toBeTruthy();
      expect(row.children({children: !student.hidden ? "Active" : "Inactive"})).toBeTruthy();
    };

    beforeAll(() => {
      students_sample = [
        {
          _id: 9,
          user_name: "c6scriab",
          first_name: "Scriabin",
          last_name: "Alexander",
          email: "scriabin.alexander@example.com",
          id_number: "0016430837",
          hidden: false,
          section: 1,
          grace_credits: 5,
          remaining_grace_credits: 4,
        },
        {
          _id: 10,
          user_name: "g8butter",
          first_name: "Butterworth",
          last_name: "George",
          email: "butterworth.george@example.com",
          id_number: "0024019685",
          hidden: false,
          section: null,
          grace_credits: 5,
          remaining_grace_credits: 4,
        },
      ];
      // Mocking the response returned by $.ajax, used in StudentTable fetchData
      $.ajax = jest.fn(() =>
        Promise.resolve({
          students: students_sample,
          sections: {1: "LEC0101"},
          counts: {all: 2, active: 2, inactive: 0},
        })
      );
      wrapper = mount(<StudentTable selection={[]} course_id={1} />);
    });

    it("each student is displayed as a row of the table", () => {
      students_sample.forEach(student => student_in_one_row(wrapper, student));
    });
  });

  describe("when no students are fetched", () => {
    beforeAll(() => {
      students_sample = [];
      // Mocking the response returned by $.ajax, used in StudentTable fetchData
      $.ajax = jest.fn(() =>
        Promise.resolve({
          students: students_sample,
          sections: {},
          counts: {all: 0, active: 0, inactive: 0},
        })
      );
      wrapper = mount(<StudentTable selection={[]} course_id={1} />);
    });

    it("No rows found is shown", () => {
      expect(wrapper.find({children: "No rows found"})).toBeTruthy();
    });
  });
});
