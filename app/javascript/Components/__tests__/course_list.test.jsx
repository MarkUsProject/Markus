import React from "react";
import {render, screen, waitFor} from "@testing-library/react";
import CourseList, {makeCourseList} from "../course_list.jsx";
import fetchMock from "jest-fetch-mock";
import {createRoot} from "react-dom/client";

jest.mock("../course_cards", () => {
  return function MockCourseCard(props) {
    return <div>{props.course_name}</div>;
  };
});

jest.mock("react-dom/client", () => ({
  createRoot: jest.fn(() => ({
    render: jest.fn(),
  })),
}));

describe("CourseList", () => {
  beforeAll(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date("2026-01-01T00:00:00-04:00"));
    fetchMock.enableMocks();
  });

  beforeEach(() => {
    global.Routes = {courses_path: () => "/courses"};
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  afterEach(() => {
    fetchMock.resetMocks();
  });

  const createCourse = ({id, name, role, endAt}) => ({
    "courses.id": id,
    "courses.name": name,
    "roles.type": role,
    "courses.end_at": endAt,
  });

  it("shows both headings and no courses message when no course related to the user", async () => {
    fetchMock.mockResponseOnce(JSON.stringify({data: []}));
    render(<CourseList />);

    await waitFor(() => {
      expect(screen.getByText(I18n.t("courses.current_courses"))).toBeInTheDocument();
      expect(screen.getByText(I18n.t("courses.past_courses"))).toBeInTheDocument();
      expect(screen.getAllByText(I18n.t("courses.no_courses"))).toHaveLength(2);
    });
  });

  it("shows no course message under Past Courses if there are no past courses", async () => {
    const courses = [
      createCourse({id: 1, name: "csc108", role: "Student", endAt: "2026-04-27T00:00:00-04:00"}),
    ];

    fetchMock.mockResponseOnce(JSON.stringify({data: courses}));
    render(<CourseList />);

    await waitFor(() => {
      expect(screen.getByText(I18n.t("courses.current_courses"))).toBeInTheDocument();
      expect(screen.getByText("csc108")).toBeInTheDocument();
      expect(screen.getByText(I18n.t("courses.past_courses"))).toBeInTheDocument();
      expect(screen.getByText(I18n.t("courses.no_courses"))).toBeInTheDocument();
    });
  });

  it("shows no course message under Current Courses if there are no current courses", async () => {
    const courses = [
      createCourse({id: 1, name: "csc108", role: "Student", endAt: "2025-04-27T00:00:00-04:00"}),
    ];

    fetchMock.mockResponseOnce(JSON.stringify({data: courses}));
    render(<CourseList />);

    await waitFor(() => {
      expect(screen.getByText(I18n.t("courses.past_courses"))).toBeInTheDocument();
      expect(screen.getByText("csc108")).toBeInTheDocument();
      expect(screen.getByText(I18n.t("courses.current_courses"))).toBeInTheDocument();
      expect(screen.getByText(I18n.t("courses.no_courses"))).toBeInTheDocument();
    });
  });
});

describe("makeCourseList", () => {
  beforeEach(() => {
    createRoot.mockClear();
  });

  it("calls createRoot and renders CourseList", () => {
    const container = document.createElement("div");
    const props = {foo: "bar"};

    makeCourseList(container, props);

    expect(createRoot).toHaveBeenCalledWith(container);

    const root = createRoot.mock.results[0].value;
    expect(root.render).toHaveBeenCalledTimes(1);

    const element = root.render.mock.calls[0][0];
    expect(element.type).toBe(CourseList);
  });
});
