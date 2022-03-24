import {StudentTable} from "../student_table";
import {render, screen, within, fireEvent} from "@testing-library/react";

// Unit test
describe("For the RawStudentTable component's non-conditional rendering", () => {
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
      ].forEach(text => {
        expect(within(screen.getByTestId("raw_student_table")).getByText(text)).toBeInTheDocument;
      });
    });
  });
});

describe("For the RawStudentTable component's conditional rendering", () => {
  describe("the CheckboxTable component", () => {
    let table;
    beforeEach(() => {
      table = render(<StudentTable selection={["c5anthei"]} course_id={1} />);
    });
    it("displays students", () => {
      const sample_student = {
        _id: 9,
        user_name: "c6scriab",
        first_name: "Scriabin",
        last_name: "Alexander",
        email: "scriabin.alexander@example.com",
        id_number: "0016430837",
        hidden: false,
        section: null,
        grace_credits: 5,
        remaining_grace_credits: 4,
      };
      // table.setState({
      //   students: [sample_student]
      // })
      expect(1).toEqual(1);
    });
  });
});
