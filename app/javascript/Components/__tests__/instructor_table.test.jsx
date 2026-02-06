import {render, screen, fireEvent, waitFor} from "@testing-library/react";

import {InstructorTable} from "../instructor_table";

global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () =>
      Promise.resolve({
        data: [],
        counts: {},
      }),
  })
);

describe("For the InstructorTable's display of instructors", () => {
  let instructors_sample;

  describe("when some instructors are fetched", () => {
    const instructors_in_one_row = instructor => {
      const rows = screen.getAllByRole("row");
      for (let row of rows) {
        const cells = Array.from(row.childNodes).map(c => c.textContent);
        if (cells[0] === instructor.user_name) {
          expect(cells[1]).toEqual(instructor.first_name);
          expect(cells[2]).toEqual(instructor.last_name);
          if (instructor.email) {
            expect(cells[3]).toEqual(instructor.email);
          }
          return;
        }
      }
      // If the loop ends without finding the instructor, raise an error
      throw `Could not find row for ${instructor.user_name}`;
    };

    beforeAll(async () => {
      instructors_sample = [
        {
          id: 1,
          user_name: "a",
          first_name: "David",
          last_name: "Liu",
          email: "example@gmail.com",
          hidden: false,
        },
        {
          id: 2,
          user_name: "reid",
          first_name: "Karen",
          last_name: "Reid",
          email: null,
          hidden: true,
        },
      ];
      // Mocking the response returned by fetch, used in InstructorTable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: instructors_sample,
          counts: {all: 2, active: 1, inactive: 1},
        }),
      });
      render(<InstructorTable course_id={1} />);
      await screen.findByText("reid");
    });

    it("each instructor is displayed as a row of the table", async () => {
      instructors_sample.forEach(instructor => instructors_in_one_row(instructor));
    });
  });

  describe("when no instructors are fetched", () => {
    beforeAll(() => {
      instructors_sample = [];
      // Mocking the response returned by fetch, used in InstructorTable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: instructors_sample,
          counts: {all: 0, active: 0, inactive: 0},
        }),
      });
      render(<InstructorTable course_id={1} />);
    });

    it("No rows found is shown", async () => {
      await screen.findByText(I18n.t("instructors.empty_table"));
    });
  });
});

describe("For the InstructorTable's admin remove button", () => {
  let mock_course_id = 1;
  let mock_instructor_id = 42;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue({
        data: [
          {
            id: mock_instructor_id,
            user_name: "testinstructor",
            first_name: "Test",
            last_name: "Instructor",
            email: "test@test.com",
            hidden: false,
          },
        ],
        counts: {all: 1, active: 1, inactive: 0},
      }),
    });

    document.querySelector = jest.fn().mockReturnValue({
      content: "mocked-csrf-token",
    });
  });

  it("shows remove button when is_admin is true", async () => {
    render(<InstructorTable course_id={mock_course_id} is_admin={true} />);
    await screen.findByText("testinstructor");
    expect(screen.getByLabelText(I18n.t("remove"))).toBeInTheDocument();
  });

  it("does not show remove button when is_admin is false", async () => {
    render(<InstructorTable course_id={mock_course_id} is_admin={false} />);
    await screen.findByText("testinstructor");
    expect(screen.queryByLabelText(I18n.t("remove"))).not.toBeInTheDocument();
  });

  it("does not show remove button when is_admin is not set", async () => {
    render(<InstructorTable course_id={mock_course_id} />);
    await screen.findByText("testinstructor");
    expect(screen.queryByLabelText(I18n.t("remove"))).not.toBeInTheDocument();
  });

  it("calls the correct endpoint when remove is confirmed", async () => {
    jest.spyOn(global, "confirm").mockReturnValue(true);
    render(<InstructorTable course_id={mock_course_id} is_admin={true} />);
    await screen.findByText("testinstructor");

    fireEvent.click(screen.getByLabelText(I18n.t("remove")));

    await waitFor(() => {
      expect(global.confirm).toHaveBeenCalledWith(I18n.t("instructors.delete_confirm"));
      expect(fetch).toHaveBeenCalledWith(
        Routes.course_instructor_path(mock_course_id, mock_instructor_id),
        expect.objectContaining({
          method: "DELETE",
          headers: expect.objectContaining({
            "Content-Type": "application/json",
            "X-CSRF-Token": expect.any(String),
          }),
        })
      );
    });
    global.confirm.mockRestore();
  });

  it("does not call the endpoint when remove is cancelled", async () => {
    jest.spyOn(global, "confirm").mockReturnValue(false);
    render(<InstructorTable course_id={mock_course_id} is_admin={true} />);
    await screen.findByText("testinstructor");

    const initialFetchCount = fetch.mock.calls.length;
    fireEvent.click(screen.getByLabelText(I18n.t("remove")));

    expect(global.confirm).toHaveBeenCalledWith(I18n.t("instructors.delete_confirm"));
    expect(fetch.mock.calls.length).toBe(initialFetchCount);
    global.confirm.mockRestore();
  });
});

describe("For each InstructorTable's loading status", () => {
  beforeEach(() => {
    jest.spyOn(global, "fetch").mockImplementation(() => new Promise(() => {}));
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("InstructorTable Spinner", () => {
    it("shows loading spinner when data is being fetched", async () => {
      render(<InstructorTable course_id={1} />);

      const spinner = await screen.findByLabelText("grid-loading", {}, {timeout: 3000});
      expect(spinner).toBeInTheDocument();
    });
  });
});
