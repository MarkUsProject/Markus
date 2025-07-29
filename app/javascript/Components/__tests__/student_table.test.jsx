/*
 * Tests for the StudentTable component
 */

import {StudentTable} from "../student_table";
import {render, screen, within, fireEvent, waitFor} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

describe("For the StudentTable component's states and props", () => {
  describe("submitting the child StudentsActionBox component", () => {
    beforeAll(async () => {
      render(<StudentTable selection={["c5anthei"]} course_id={1} />);
    });

    it("sets selection and selectAll to empty list", async () => {
      const submit = screen.getByRole("button", {name: I18n.t("apply")});
      await userEvent.click(submit);

      const selected = screen.queryAllByRole("checkbox", {checked: true, hidden: true});
      expect(selected).toEqual([]);
    });
  });

  describe("each filterable column has a custom filter method", () => {
    let wrapper = React.createRef();
    let filter_method;

    beforeEach(() => {
      render(<StudentTable selection={["c5anthei"]} course_id={1} ref={wrapper} />);
    });

    describe("the filter method for the section column", () => {
      beforeEach(() => {
        filter_method =
          wrapper.current.wrapped.checkboxTable.wrappedInstance.props.columns[6].filterMethod;
      });

      it("returns true when the selected value is all", () => {
        expect(filter_method({value: "all"})).toEqual(true);
      });

      it("returns true when the row's section index equals to the selected value", () => {
        // Sets data.sections
        wrapper.current.wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // Sample row
        const sample_row = {section: 1};
        expect(filter_method({id: "section", value: "LEC0101"}, sample_row)).toEqual(true);
      });

      it("returns false when the row's section index doesn't equal to the selected value", () => {
        // Sets data.sections
        wrapper.current.wrapped.state.data.sections = {1: "LEC0101", 2: "LEC0201"};
        // Sample row
        const sample_row = {section: 2};
        expect(filter_method({id: "section", value: "LEC0101"}, sample_row)).toEqual(false);
      });
    });

    describe("the filter method for the grace credits column", () => {
      beforeEach(() => {
        filter_method =
          wrapper.current.wrapped.checkboxTable.wrappedInstance.props.columns[7].filterMethod;
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
      beforeEach(() => {
        filter_method =
          wrapper.current.wrapped.checkboxTable.wrappedInstance.props.columns[8].filterMethod;
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
        I18n.t("roles.active") + "?",
        I18n.t("actions"),
      ].forEach(text => {
        expect(within(screen.getByTestId("raw_student_table")).getByText(text)).toBeInTheDocument;
      });
    });
  });
});

global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () =>
      Promise.resolve({
        students: [],
        sections: {},
        counts: {},
      }),
  })
);

describe("For the StudentTable's display of students", () => {
  let students_sample, sections_sample;

  describe("when some students are fetched", () => {
    const student_in_one_row = student => {
      const rows = screen.getAllByRole("row");
      for (let row of rows) {
        const cells = Array.from(row.childNodes).map(c => c.textContent);
        if (cells[1] === student.user_name) {
          expect(cells[2]).toEqual(student.first_name);
          expect(cells[3]).toEqual(student.last_name);
          if (student.email) {
            expect(cells[4]).toEqual(student.email);
          }
          expect(cells[5]).toEqual(student.id_number);
          expect(cells[6]).toEqual(sections_sample[student.section] || "");
          expect(cells[7]).toEqual(`${student.remaining_grace_credits} / ${student.grace_credits}`);
          expect(cells[8]).toEqual(
            !student.hidden ? I18n.t("roles.active") : I18n.t("roles.inactive")
          );
          return;
        }
      }
      // If the loop ends without finding the student, raise an error
      throw `Could not find row for ${student.user_name}`;
    };

    beforeAll(async () => {
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
      sections_sample = {1: "LEC0101"};
      // Mocking the response returned by fetch, used in StudentTable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          students: students_sample,
          sections: sections_sample,
          counts: {all: 2, active: 2, inactive: 0},
        }),
      });
      render(<StudentTable selection={[]} course_id={1} />);
      await screen.findByText("c6scriab");
    });

    it("each student is displayed as a row of the table", () => {
      students_sample.forEach(student => student_in_one_row(student));
    });
  });

  describe("when no students are fetched", () => {
    beforeAll(() => {
      students_sample = [];
      // Mocking the response returned by $.ajax, used in StudentTable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        // Use mockResolvedValueOnce to mock a successful response
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          students: students_sample,
          sections: {},
          counts: {all: 0, active: 0, inactive: 0},
        }),
      });
      render(<StudentTable selection={[]} course_id={1} />);
    });

    it("No rows found is shown", async () => {
      await screen.findByText(I18n.t("students.empty_table"));
    });
  });

  describe("When the remove button is pressed", () => {
    let mock_course_id = 1;
    let mock_student_id = 42;

    beforeEach(() => {
      jest.clearAllMocks();
      jest.spyOn(global, "fetch").mockResolvedValue({
        ok: true,
        json: jest.fn().mockResolvedValue({
          students: [
            {
              _id: mock_student_id,
              user_name: "testtest",
              first_name: "Test",
              last_name: "Test",
              email: "test@test.com",
              hidden: false,
            },
          ],
          sections: {},
          counts: {all: 1, active: 1, inactive: 0},
        }),
      });

      document.querySelector = jest.fn().mockReturnValue({
        content: "mocked-csrf-token",
      });
    });

    it("calls the correct endpoint when removeStudent is triggered", async () => {
      render(<StudentTable course_id={mock_course_id} />);

      await screen.findByText("testtest");

      fireEvent.click(screen.getByLabelText(I18n.t("remove")));

      await waitFor(() => {
        expect(fetch).toHaveBeenCalledWith(
          Routes.course_student_path(mock_course_id, mock_student_id),
          expect.objectContaining({
            method: "DELETE",
            headers: expect.objectContaining({
              "Content-Type": "application/json",
              "X-CSRF-Token": expect.any(String),
            }),
          })
        );
      });
    });
  });
});
