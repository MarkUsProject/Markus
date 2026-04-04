import React from "react";
import {render, screen} from "@testing-library/react";
import CourseCard from "../course_cards";

describe("CourseCard", () => {
  beforeEach(() => {
    global.Routes = {
      course_path: id => `/courses/${id}`,
      course_assignments_path: id => `/courses/${id}/assignments`,
    };
  });

  const baseProps = {
    course_id: 1,
    course_name: "CSC108",
    course_display_name: "Intro to CS",
  };

  it("uses the course page link for instructors", () => {
    render(<CourseCard {...baseProps} role_type="Instructor" />);
    expect(screen.getByRole("link")).toHaveAttribute("href", "/courses/1");
  });

  it("uses the assignments page link for non-instructors", () => {
    render(<CourseCard {...baseProps} role_type="Student" />);
    expect(screen.getByRole("link")).toHaveAttribute("href", "/courses/1/assignments");
  });
});
