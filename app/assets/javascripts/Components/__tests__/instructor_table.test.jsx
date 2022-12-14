import {mount} from "enzyme";

import {InstructorTable} from "../instructor_table";

describe("For the InstructorTable's display of instructors", () => {
  let wrapper, instructors_sample;

  describe("when some instructors are fetched", () => {
    const instructors_in_one_row = (wrapper, instructor) => {
      // Find the row
      const row = wrapper.find({children: instructor.user_name}).parent();
      // Expect the row to contain these information
      expect(row.children({children: instructor.first_name})).toBeTruthy();
      expect(row.children({children: instructor.last_name})).toBeTruthy();
      if (instructor.email) {
        expect(row.children({children: instructor.email})).toBeTruthy();
      }
    };

    beforeAll(() => {
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
      // Mocking the response returned by $.ajax, used in InstructorTable fetchData
      $.ajax = jest.fn(() =>
        Promise.resolve({
          data: instructors_sample,
          counts: {all: 2, active: 1, inactive: 1},
        })
      );
      wrapper = mount(<InstructorTable course_id={1} />);
    });

    it("each instructor is displayed as a row of the table", () => {
      instructors_sample.forEach(instructor => instructors_in_one_row(wrapper, instructor));
    });
  });

  describe("when no instructors are fetched", () => {
    beforeAll(() => {
      instructors_sample = [];
      // Mocking the response returned by $.ajax, used in InstructorTable fetchData
      $.ajax = jest.fn(() =>
        Promise.resolve({
          data: instructors_sample,
          counts: {all: 0, active: 0, inactive: 0},
        })
      );
      wrapper = mount(<InstructorTable course_id={1} />);
    });

    it("No rows found is shown", () => {
      expect(wrapper.find({children: "No rows found"})).toBeTruthy();
    });
  });
});
