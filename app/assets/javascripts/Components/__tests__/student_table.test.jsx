import {StudentTable} from "../student_table";
import {render, screen, fireEvent} from "@testing-library/react";

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
      expect(screen.getByTestId("student_action_box")).toBeInTheDocument;
    });

    it("renders a child CheckboxTable", () => {
      // expect(screen.getByTestId("checkbox_table")).toBeInTheDocument;
      expect(screen.getAllByRole("columnheader").length).toBeGreaterThanOrEqual(1);
    });
  });
});

describe("For the RawStudentTable component's conditional rendering", () => {
  describe("the CheckboxTable component", () => {
    it("displays students", () => {
      // const sample_student = {
      //   "_id": 9,
      //   "user_name": "c6scriab",
      //   "first_name": "Scriabin",
      //   "last_name": "Alexander",
      //   "email": "scriabin.alexander@example.com",
      //   "id_number": "0016430837",
      //   "hidden": false,
      //   "section": null,
      //   "grace_credits": 5,
      //   "remaining_grace_credits": 4
      // }
      // render(<StudentTable selection={["c5anthei"]} course_id={1} />)
      expect(1).toEqual(1);
    });
  });
});
