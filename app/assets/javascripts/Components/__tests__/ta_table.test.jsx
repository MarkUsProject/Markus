import {mount} from "enzyme";

import {TATable} from "../ta_table";

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

describe("For the TATable's display of TAs", () => {
  let wrapper, tas_sample;

  describe("when some TAs are fetched", () => {
    const tas_in_one_row = (wrapper, ta) => {
      // Find the row
      const row = wrapper.find({children: ta.user_name}).parent();
      // Expect the row to contain these information
      expect(row.children({children: ta.first_name})).toBeTruthy();
      expect(row.children({children: ta.last_name})).toBeTruthy();
      if (ta.email) {
        expect(row.children({children: ta.email})).toBeTruthy();
      }
    };

    beforeAll(() => {
      tas_sample = [
        {
          id: 3,
          user_name: "c6conley",
          first_name: "Mike",
          last_name: "Conley",
          email: "example@gmail.com",
          hidden: false,
        },
        {
          id: 4,
          user_name: "c6gehwol",
          first_name: "Severin",
          last_name: "Gehwolf",
          email: null,
          hidden: false,
        },
        {
          id: 5,
          user_name: "c9varoqu",
          first_name: "Nelle",
          last_name: "Varoquaux",
          email: null,
          hidden: false,
        },
        {
          id: 6,
          user_name: "c9rada",
          first_name: "Mark",
          last_name: "Rada",
          email: null,
          hidden: true,
        },
      ];
      // Mocking the response returned by fetch, used in TATable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: tas_sample,
          counts: {all: 4, active: 3, inactive: 1},
        }),
      });
      wrapper = mount(<TATable course_id={1} />);
    });

    it("each TA is displayed as a row of the table", () => {
      tas_sample.forEach(ta => tas_in_one_row(wrapper, ta));
    });
  });

  describe("when no TAs are fetched", () => {
    beforeAll(() => {
      tas_sample = [];
      // Mocking the response returned by fetch, used in TATable fetchData
      fetch.mockReset();
      fetch.mockResolvedValueOnce({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: tas_sample,
          counts: {all: 0, active: 0, inactive: 0},
        }),
      });
      wrapper = mount(<TATable course_id={1} />);
    });

    it("No rows found is shown", () => {
      expect(wrapper.find({children: "No rows found"})).toBeTruthy();
    });
  });
});
