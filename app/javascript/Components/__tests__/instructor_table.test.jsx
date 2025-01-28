import {render, screen} from "@testing-library/react";

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
      await screen.findByText("No rows found");
    });
  });
});
