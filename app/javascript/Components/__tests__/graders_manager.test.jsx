/***
 * Tests for GradersManager Component
 */

import {GradersManager} from "../graders_manager";
import {render, screen, fireEvent} from "@testing-library/react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("For the GradersManager's display of inactive groups", () => {
  let groups_sample;
  beforeEach(async () => {
    groups_sample = [
      {
        _id: 15,
        members: [
          ["c9nielse", "inviter", true],
          ["c8szyman", "accepted", true],
        ],
        inactive: false,
        grace_credits: 5,
        remaining_grace_credits: 4,
        group_name: "group_0015",
        graders: [],
        criteria_coverage_count: 0,
      },
      {
        _id: 15,
        members: [
          ["d2lifese", "inviter", false],
          ["a3kjcbod", "accepted", false],
        ],
        inactive: false,
        grace_credits: 5,
        remaining_grace_credits: 4,
        group_name: "group_0014",
        graders: [],
        criteria_coverage_count: 0,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        graders: [],
        criteria: [],
        assign_graders_to_criteria: false,
        loading: false,
        sections: {},
        anonymize_groups: false,
        hide_unassigned_criteria: false,
        isGraderDistributionModalOpen: false,
        groups: groups_sample,
      }),
    });
    render(<GradersManager sections={{}} course_id={1} assignment_id={1} />);

    await screen.findByText("group_0014"); // Wait for data to be rendered
  });

  it("contains the correct amount of inactive groups in the hidden tooltip", () => {
    expect(screen.getByTestId("show_hidden_groups_tooltip").getAttribute("title")).toEqual(
      "1 inactive group"
    );
  });

  it("initially doesn't contain the inactive group", () => {
    expect(screen.queryByText("group_0015")).not.toBeInTheDocument();
  });

  it("contains the inactive group after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    expect(screen.getByText("group_0015")).toBeInTheDocument();
  });

  it("doesn't contain the inactive group after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    expect(screen.queryByText("group_0015")).not.toBeInTheDocument();
  });
});

describe("For the GradersManager's name search", () => {
  let graders_sample;
  beforeEach(async () => {
    graders_sample = [
      {
        _id: 1,
        user_name: "c6gehwol",
        first_name: "Severin",
        last_name: "Gehwolf",
        groups: 5,
        criteria: 2,
        hidden: false,
      },
      {
        _id: 2,
        user_name: "c9rada",
        first_name: "Mark",
        last_name: "Rada",
        groups: 4,
        criteria: 2,
        hidden: false,
      },
      {
        _id: 3,
        user_name: "c9varoqu",
        first_name: "Nelle",
        last_name: "Varoquaux",
        groups: 5,
        criteria: 2,
        hidden: false,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        graders: graders_sample,
        criteria: [],
        assign_graders_to_criteria: false,
        loading: false,
        sections: {},
        anonymize_groups: false,
        hide_unassigned_criteria: false,
        isGraderDistributionModalOpen: false,
        groups: [],
      }),
    });
    render(<GradersManager sections={{}} course_id={1} assignment_id={1} />);
    await screen.findByText("Severin Gehwolf");
  });

  it("displays all graders initially", () => {
    expect(screen.getByText("Severin Gehwolf")).toBeInTheDocument();
    expect(screen.getByText("Mark Rada")).toBeInTheDocument();
    expect(screen.getByText("Nelle Varoquaux")).toBeInTheDocument();
  });

  it("filters by first name correctly", async () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: "Severin"}});

    expect(screen.getByText("Severin Gehwolf")).toBeInTheDocument();
    expect(screen.queryByText("Mark Rada")).not.toBeInTheDocument();
    expect(screen.queryByText("Nelle Varoquaux")).not.toBeInTheDocument();
  });

  it("filters by last name correctly", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: "Rada"}});

    expect(screen.getByText("Mark Rada")).toBeInTheDocument();
    expect(screen.queryByText("Severin Gehwolf")).not.toBeInTheDocument();
    expect(screen.queryByText("Nelle Varoquaux")).not.toBeInTheDocument();
  });

  it("filters by full name correctly", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: "Nelle Varoquaux"}});

    expect(screen.getByText("Nelle Varoquaux")).toBeInTheDocument();
    expect(screen.queryByText("Severin Gehwolf")).not.toBeInTheDocument();
    expect(screen.queryByText("Mark Rada")).not.toBeInTheDocument();
  });

  it("is case insensitive when filtering", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: "mark"}});

    expect(screen.getByText("Mark Rada")).toBeInTheDocument();
    expect(screen.queryByText("Severin Gehwolf")).not.toBeInTheDocument();
    expect(screen.queryByText("Nelle Varoquaux")).not.toBeInTheDocument();
  });

  it("handles partial matches", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: "ver"}});

    expect(screen.getByText("Severin Gehwolf")).toBeInTheDocument();
    expect(screen.queryByText("Mark Rada")).not.toBeInTheDocument();
    expect(screen.queryByText("Nelle Varoquaux")).not.toBeInTheDocument();
  });

  it("shows all graders when filter is cleared", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {target: {value: ""}});

    expect(screen.getByText("Severin Gehwolf")).toBeInTheDocument();
    expect(screen.getByText("Mark Rada")).toBeInTheDocument();
    expect(screen.getByText("Nelle Varoquaux")).toBeInTheDocument();
  });

  it("shows no results when filter matches nothing", () => {
    const nameSearch = screen.getByRole("textbox", {name: `${I18n.t("search")} Name`});
    fireEvent.change(nameSearch, {
      target: {value: "NonexistentName"},
    });

    expect(screen.queryByText("Severin Gehwolf")).not.toBeInTheDocument();
    expect(screen.queryByText("Mark Rada")).not.toBeInTheDocument();
    expect(screen.queryByText("Nelle Varoquaux")).not.toBeInTheDocument();
  });
});
