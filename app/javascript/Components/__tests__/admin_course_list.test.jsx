import {render, screen, within} from "@testing-library/react";
import "@testing-library/jest-dom";
import userEvent from "@testing-library/user-event";
import {AdminCourseList} from "../admin_course_list";

beforeAll(() => {
  global.Routes = {
    admin_courses_path: jest.fn(() => "/admin/courses"),
    edit_admin_course_path: jest.fn(id => `/admin/courses/${id}/edit`),
    course_path: jest.fn(id => `/courses/${id}`),
  };
  global.I18n = {
    t: jest.fn(key => {
      const translations = {
        "activerecord.attributes.course.name": "Name",
        "activerecord.attributes.course.display_name": "Display Name",
        "activerecord.attributes.course.is_hidden": "Visibility",
        "courses.hidden": "Hidden",
        "courses.visible": "Visible",
        "courses.go_to_course": "Go to course",
        actions: "Actions",
        edit: "Edit",
        all: "All",
        table: {no_data: "No data"},
      };
      return translations[key] || key;
    }),
  };
});

beforeEach(() => {
  global.fetch = jest.fn().mockResolvedValue({
    ok: true,
    json: async () => [
      {id: 1, name: "Course B", display_name: "Beta", is_hidden: true},
      {id: 2, name: "Course A", display_name: "Alpha", is_hidden: false},
    ],
  });
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("AdminCourseList", () => {
  it("sorts courses by name", async () => {
    const {container} = render(<AdminCourseList />);

    await screen.findByText("Course A");
    const rows = container.querySelectorAll(".rt-tbody .rt-tr");
    expect(within(rows[0]).getByText("Course A")).toBeInTheDocument();
    expect(within(rows[1]).getByText("Course B")).toBeInTheDocument();
  });

  it("filters to hidden courses", async () => {
    const user = userEvent.setup();
    render(<AdminCourseList />);
    await screen.findByText("Course A");

    const visibilityFilter = screen.getByRole("combobox");
    expect(within(visibilityFilter).getByRole("option", {name: "Hidden (1)"})).toBeInTheDocument();
    expect(within(visibilityFilter).getByRole("option", {name: "Visible (1)"})).toBeInTheDocument();
    await user.selectOptions(visibilityFilter, "Hidden (1)");

    expect(screen.getByText("Course B")).toBeInTheDocument();
    expect(screen.queryByText("Course A")).not.toBeInTheDocument();
  });

  it("filters to visible courses", async () => {
    const user = userEvent.setup();
    render(<AdminCourseList />);
    await screen.findByText("Course A");

    const visibilityFilter = screen.getByRole("combobox");
    await user.selectOptions(visibilityFilter, "Visible (1)");

    expect(screen.getByText("Course A")).toBeInTheDocument();
    expect(screen.queryByText("Course B")).not.toBeInTheDocument();
  });
});
