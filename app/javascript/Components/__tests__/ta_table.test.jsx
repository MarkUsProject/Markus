import {TATable} from "../ta_table";
import {render, screen, fireEvent, waitFor, within} from "@testing-library/react";
import {StudentTable} from "../student_table";

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
  let tas_sample;

  describe("when some TAs are fetched", () => {
    const tas_in_one_row = ta => {
      const row = screen.getByText(ta.user_name).closest("div[role='row']");
      expect(row).toBeInTheDocument();

      expect(within(row).queryByText(ta.first_name)).toBeInTheDocument();

      expect(within(row).queryByText(ta.last_name)).toBeInTheDocument();

      if (ta.email) {
        expect(within(row).queryByText(ta.email)).toBeInTheDocument();
      }
    };

    beforeAll(async () => {
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

      render(<TATable course_id={1} />);
      await screen.findByText("c6conley");
    });

    it("each TA is displayed as a row of the table", () => {
      tas_sample.forEach(ta => tas_in_one_row(ta));
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
      render(<TATable course_id={1} />);
    });

    it("No rows found is shown", async () => {
      await screen.findByText(I18n.t("tas.empty_table"));
    });
  });

  describe("When the remove button is pressed", () => {
    let mock_course_id = 1;
    let mock_ta_id = 42;

    beforeEach(() => {
      jest.clearAllMocks();
      jest.spyOn(global, "fetch").mockResolvedValue({
        ok: true,
        json: jest.fn().mockResolvedValue({
          data: [
            {
              id: mock_ta_id,
              user_name: "testtest",
              first_name: "Test",
              last_name: "Test",
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

    it("calls the correct endpoint when removeTA is triggered", async () => {
      render(<TATable course_id={mock_course_id} />);

      await screen.findByText("testtest");

      fireEvent.click(screen.getByLabelText(I18n.t("remove")));

      await waitFor(() => {
        expect(fetch).toHaveBeenCalledWith(
          Routes.course_ta_path(mock_course_id, mock_ta_id),
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

describe("For each TATable's loading status", () => {
  beforeEach(() => {
    jest.spyOn(global, "fetch").mockImplementation(() => new Promise(() => {}));
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("TATable Spinner", () => {
    it("shows loading spinner when data is being fetched", async () => {
      render(<TATable course_id={mock_course_id} />);

      const spinner = await screen.findByLabelText("grid-loading", {}, {timeout: 3000});
      expect(spinner).toBeInTheDocument();
    });
  });
});
