/***
 * Tests for SubmissionTable Component
 */

import {SubmissionTable} from "../submission_table";
import {render, screen, fireEvent} from "@testing-library/react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("For the SubmissionTable's display of inactive groups", () => {
  let groups_sample;
  beforeEach(async () => {
    groups_sample = [
      {
        _id: 1,
        max_mark: 21.0,
        group_name: "group_0001",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 1,
        final_grade: 12.0,
        members: [
          ["c6scriab", true],
          ["g5dalber", true],
        ],
        grace_credits_used: 1,
      },
      {
        _id: 2,
        max_mark: 21.0,
        group_name: "group_0002",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 2,
        final_grade: 7.0,
        members: [
          ["g8butter", false],
          ["g6duparc", false],
        ],
        section: "LEC0101",
        grace_credits_used: 1,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        groupings: groups_sample,
        sections: {},
      }),
    });

    render(
      <SubmissionTable
        assignment_id={1}
        course_id={1}
        show_grace_tokens={true}
        show_sections={true}
        is_timed={false}
        is_scanned_exam={false}
        release_with_urls={false}
        can_collect={true}
        can_run_tests={false}
        defaultFiltered={[{id: "", value: ""}]}
      />
    );
    await screen.findByText("group_0002");
  });

  it("contains the correct amount of inactive groups in the hidden tooltip", () => {
    expect(screen.getByTestId("show_inactive_groups_tooltip").getAttribute("title")).toEqual(
      "1 inactive group"
    );
  });

  it("initially does not contain the inactive group", () => {
    expect(screen.queryByText("group_0001")).not.toBeInTheDocument();
  });

  it("contains the inactive group after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    expect(screen.queryByText("group_0001")).toBeInTheDocument();
  });

  it("doesn't contain the inactive group after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    expect(screen.queryByText("group_0001")).not.toBeInTheDocument();
  });
});

describe("For the SubmissionTable's display of assigned submissions", () => {
  beforeEach(async () => {
    const groups_sample = [
      {
        _id: 1,
        max_mark: 21.0,
        group_name: "assigned_group",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 1,
        final_grade: 12.0,
        members: [["c6scriab", false]],
        grace_credits_used: 1,
        assigned: true,
      },
      {
        _id: 2,
        max_mark: 21.0,
        group_name: "unassigned_group",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 2,
        final_grade: 7.0,
        members: [["g8butter", false]],
        grace_credits_used: 1,
        assigned: false,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        groupings: groups_sample,
        sections: {},
      }),
    });

    render(
      <SubmissionTable
        assignment_id={1}
        course_id={1}
        show_grace_tokens={true}
        show_sections={true}
        is_timed={false}
        is_scanned_exam={false}
        release_with_urls={false}
        can_collect={true}
        can_run_tests={false}
        can_view_assigned_submissions_only={true}
        defaultFiltered={[{id: "", value: ""}]}
      />
    );
    await screen.findByText("assigned_group");
  });

  it("contains the correct amount of assigned submissions in the hidden tooltip", () => {
    expect(
      screen.getByTestId("show_assigned_submissions_only_tooltip").getAttribute("title")
    ).toEqual("1 assigned submission");
  });

  it("initially displays assigned and unassigned submissions", () => {
    expect(screen.getByText("assigned_group")).toBeInTheDocument();
    expect(screen.getByText("unassigned_group")).toBeInTheDocument();
  });

  it("only displays assigned submissions after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));
    expect(screen.getByText("assigned_group")).toBeInTheDocument();
    expect(screen.queryByText("unassigned_group")).not.toBeInTheDocument();
  });

  it("displays all submissions after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));
    expect(screen.getByText("assigned_group")).toBeInTheDocument();
    expect(screen.getByText("unassigned_group")).toBeInTheDocument();
  });
});

describe("For the SubmissionTable's group name search", () => {
  beforeEach(async () => {
    const groups_sample = [
      {
        _id: 1,
        max_mark: 21.0,
        group_name: "Alpha_group",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 1,
        final_grade: 12.0,
        members: [["c1abc", false]],
        grace_credits_used: 0,
      },
      {
        _id: 2,
        max_mark: 21.0,
        group_name: "alpha_lower",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 2,
        final_grade: 12.0,
        members: [["c2abc", false]],
        grace_credits_used: 0,
      },
      {
        _id: 3,
        max_mark: 21.0,
        group_name: "Beta_group",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 3,
        final_grade: 12.0,
        members: [["c3abc", false]],
        grace_credits_used: 0,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        groupings: groups_sample,
        sections: {},
      }),
    });

    render(
      <SubmissionTable
        assignment_id={1}
        course_id={1}
        show_grace_tokens={true}
        show_sections={true}
        is_timed={false}
        is_scanned_exam={false}
        release_with_urls={false}
        can_collect={true}
        can_run_tests={false}
        defaultFiltered={[{id: "", value: ""}]}
      />
    );
    await screen.findByText("Alpha_group");
  });

  it("is case-insensitive by default", () => {
    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "alpha"}});

    expect(screen.getByText("Alpha_group")).toBeInTheDocument();
    expect(screen.getByText("alpha_lower")).toBeInTheDocument();
    expect(screen.queryByText("Beta_group")).not.toBeInTheDocument();
  });

  it("becomes case-sensitive when the toggle is checked", () => {
    fireEvent.click(screen.getByTestId("group_name_case_sensitive"));

    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "Alpha"}});

    expect(screen.getByText("Alpha_group")).toBeInTheDocument();
    expect(screen.queryByText("alpha_lower")).not.toBeInTheDocument();
    expect(screen.queryByText("Beta_group")).not.toBeInTheDocument();
  });

  it("returns to case-insensitive when toggled back off", () => {
    const toggle = screen.getByTestId("group_name_case_sensitive");
    fireEvent.click(toggle); // on
    fireEvent.click(toggle); // off again

    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "alpha"}});

    expect(screen.getByText("Alpha_group")).toBeInTheDocument();
    expect(screen.getByText("alpha_lower")).toBeInTheDocument();
    expect(screen.queryByText("Beta_group")).not.toBeInTheDocument();
  });
});
