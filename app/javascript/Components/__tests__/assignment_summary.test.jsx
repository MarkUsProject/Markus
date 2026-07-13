/***
 * Tests for AssignmentSummaryTable Component
 */

import {AssignmentSummaryTable} from "../assignment_summary_table";
import {render, screen, fireEvent, waitFor, act} from "@testing-library/react";
import {expect} from "@jest/globals";
import {defaultSearchPlaceholderText} from "../table/search_filter";

describe("For the AssignmentSummaryTable's display of inactive groups", () => {
  let groups_sample;
  beforeEach(async () => {
    groups_sample = [
      {
        group_name: "group_0001",
        section: null,
        members: [
          ["c9nielse", "Nielsen", "Carl", true],
          ["c8szyman", "Szymanowski", "Karol", true],
        ],
        tags: [],
        graders: [["c9varoqu", "Nelle", "Varoquaux"]],
        marking_state: "released",
        final_grade: 9.0,
        criteria: {1: 0.0},
        max_mark: "21.0",
        result_id: 15,
        submission_id: 15,
        total_extra_marks: null,
      },
      {
        group_name: "group_0002",
        section: "LEC0101",
        members: [
          ["c8debuss", "Debussy", "Claude", false],
          ["c8holstg", "Holst", "Gustav", false],
        ],
        tags: [],
        graders: [["c9varoqu", "Nelle", "Varoquaux"]],
        marking_state: "released",
        final_grade: 6.0,
        criteria: {1: 2.0},
        max_mark: "21.0",
        result_id: 5,
        submission_id: 5,
        total_extra_marks: null,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: groups_sample,
        criteriaColumns: [
          {
            Header: "dolores",
            accessor: "criteria.1",
            className: "number",
            headerClassName: "",
          },
        ],
        numAssigned: 2,
        numMarked: 2,
        ltiDeployments: [],
      }),
    });

    render(
      <AssignmentSummaryTable
        assignment_id={1}
        course_id={1}
        is_instructor={false}
        lti_deployments={[]}
      />
    );
    await screen.findByText("group_0002", {exact: false});
  });

  it("contains the correct amount of inactive groups in the hidden tooltip", () => {
    expect(screen.getByTestId("show_inactive_groups_tooltip").getAttribute("title")).toEqual(
      "1 inactive group"
    );
  });

  it("initially does not contain the inactive group", () => {
    expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
  });

  it("contains the inactive group after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    expect(screen.queryByText(/group_0001/)).toBeInTheDocument();
  });

  it("doesn't contain the inactive group after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    fireEvent.click(screen.getByTestId("show_inactive_groups"));
    expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
  });
});

describe("For the AssignmentSummaryTable's display of assigned submissions", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: [
          {
            group_name: "assigned_group",
            section: null,
            members: [["c6scriab", "Scriabin", "Alexander", false]],
            tags: [],
            graders: [["c9varoqu", "Nelle", "Varoquaux"]],
            marking_state: "released",
            final_grade: 12.0,
            criteria: {},
            max_mark: "21.0",
            result_id: 1,
            submission_id: 1,
            total_extra_marks: null,
            assigned: true,
          },
          {
            group_name: "unassigned_group",
            section: null,
            members: [["g8butter", "Butterworth", "George", false]],
            tags: [],
            graders: [],
            marking_state: "released",
            final_grade: 7.0,
            criteria: {},
            max_mark: "21.0",
            result_id: 2,
            submission_id: 2,
            total_extra_marks: null,
            assigned: false,
          },
        ],
        criteriaColumns: [],
        numAssigned: 1,
        numMarked: 1,
        enableTest: false,
        ltiDeployments: [],
      }),
    });

    render(
      <AssignmentSummaryTable
        assignment_id={1}
        course_id={1}
        is_instructor={false}
        lti_deployments={[]}
        can_view_assigned_submissions_only={true}
        initial_show_assigned_submissions_only={true}
      />
    );
    await screen.findByText("assigned_group", {exact: false});
  });

  it("contains the correct number of assigned submissions in the hidden tooltip", () => {
    expect(
      screen.getByTestId("show_assigned_submissions_only_tooltip").getAttribute("title")
    ).toEqual("1 assigned submission");
  });

  it("initially displays only assigned submissions", () => {
    expect(screen.getByTestId("show_assigned_submissions_only")).toBeChecked();
    expect(screen.queryByText(/^assigned_group/)).toBeInTheDocument();
    expect(screen.queryByText(/unassigned_group/)).not.toBeInTheDocument();
  });

  it("displays all submissions after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));

    expect(screen.queryByText(/^assigned_group/)).toBeInTheDocument();
    expect(screen.queryByText(/unassigned_group/)).toBeInTheDocument();
  });

  it("only displays assigned submissions after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));
    fireEvent.click(screen.getByTestId("show_assigned_submissions_only"));

    expect(screen.queryByText(/^assigned_group/)).toBeInTheDocument();
    expect(screen.queryByText(/unassigned_group/)).not.toBeInTheDocument();
  });
});

describe("For graders who cannot view all assignment summary submissions", () => {
  it("does not display the assigned submissions filter", async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: [],
        criteriaColumns: [],
        numAssigned: 0,
        numMarked: 0,
        enableTest: false,
        ltiDeployments: [],
      }),
    });

    render(
      <AssignmentSummaryTable
        assignment_id={1}
        course_id={1}
        is_instructor={false}
        lti_deployments={[]}
      />
    );

    await waitFor(() => expect(fetch).toHaveBeenCalledTimes(1));
    expect(screen.queryByTestId("show_assigned_submissions_only")).not.toBeInTheDocument();
  });
});

describe("For the AssignmentSummaryTable's display of an assignment with automated testing", () => {
  beforeEach(() => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce(
      Promise.resolve({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: [],
          criteriaColumns: [],
          numAssigned: 0,
          numMarked: 0,
          enableTest: true,
          ltiDeployments: [],
        }),
      })
    );

    render(
      <AssignmentSummaryTable
        assignment_id={1}
        course_id={1}
        is_instructor={true}
        lti_deployments={[]}
      />
    );
  });

  it("should render the Download Test Results button", async () => {
    await waitFor(() => {
      expect(
        screen.getByText(
          I18n.t("download_the", {item: I18n.t("activerecord.models.test_result.other")})
        )
      ).toBeInTheDocument();
    });
  });
});

describe("For the AssignmentSummaryTable's display of an assignment without automated testing", () => {
  beforeEach(() => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce(
      Promise.resolve({
        ok: true,
        json: jest.fn().mockResolvedValueOnce({
          data: [],
          criteriaColumns: [],
          numAssigned: 0,
          numMarked: 0,
          enableTest: false,
          ltiDeployments: [],
        }),
      })
    );

    render(
      <AssignmentSummaryTable
        assignment_id={1}
        course_id={1}
        is_instructor={true}
        lti_deployments={[]}
      />
    );
  });

  it("should not render the Download Test Results button", async () => {
    await waitFor(() => {
      expect(
        screen.queryByText(
          I18n.t("download_the", {item: I18n.t("activerecord.models.test_result.other")})
        )
      ).not.toBeInTheDocument();
    });
  });
});

describe("For the AssignmentSummaryTable's search filter", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: [
          {
            group_name: "group_0001",
            section: null,
            members: [["c8debuss", "Debussy", "Claude", false]],
            tags: [],
            graders: [["c9varoqu", "Nelle", "Varoquaux"]],
            marking_state: "complete",
            final_grade: 9.0,
            criteria: {},
            max_mark: "21.0",
            result_id: 1,
            submission_id: 1,
            total_extra_marks: null,
          },
          {
            group_name: "group_0002",
            section: null,
            members: [["c8holstg", "Holst", "Gustav", false]],
            tags: [],
            graders: [
              ["c6gehwol", "Severin", "Gehwolf"],
              ["c9rada", "Mark", "Rada"],
            ],
            marking_state: "complete",
            final_grade: 6.0,
            criteria: {},
            max_mark: "21.0",
            result_id: 2,
            submission_id: 2,
            total_extra_marks: null,
          },
        ],
        criteriaColumns: [],
        numAssigned: 2,
        numMarked: 2,
        ltiDeployments: [],
      }),
    });

    await act(async () => {
      render(
        <AssignmentSummaryTable
          assignment_id={1}
          course_id={1}
          is_instructor={false}
          lti_deployments={[]}
        />
      );
    });
    await screen.findByText("group_0001", {exact: false});
  });

  describe("For the Group Column", () => {
    it("filters rows as the user types in the Group search box", () => {
      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[0], {
        target: {value: "0001"},
      });

      expect(screen.queryByText(/group_0001/)).toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).not.toBeInTheDocument();
    });

    it("restores all rows when the Group search query is cleared", () => {
      const searchInput = screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[0];
      fireEvent.change(searchInput, {target: {value: "0001"}});
      fireEvent.change(searchInput, {target: {value: ""}});

      expect(screen.queryByText(/group_0001/)).toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).toBeInTheDocument();
    });

    it("shows no rows when the Group search query matches nothing", () => {
      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[0], {
        target: {value: "zzznomatch"},
      });

      expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).not.toBeInTheDocument();
    });
  });

  describe("For the Graders Column", () => {
    it("filters rows as the user types in the Graders search box", () => {
      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[2], {
        target: {value: "Mark"},
      });

      expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).toBeInTheDocument();

      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[2], {
        target: {value: "Varoquaux"},
      });

      expect(screen.queryByText(/group_0001/)).toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).not.toBeInTheDocument();

      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[2], {
        target: {value: "c6gehwol"},
      });

      expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).toBeInTheDocument();
    });

    it("restores all rows when the Graders search query is cleared", () => {
      const searchInput = screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[2];
      fireEvent.change(searchInput, {target: {value: "Rada"}});
      fireEvent.change(searchInput, {target: {value: ""}});

      expect(screen.queryByText(/group_0001/)).toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).toBeInTheDocument();
    });

    it("shows no rows when the Graders search query matches nothing", () => {
      fireEvent.change(screen.getAllByPlaceholderText(defaultSearchPlaceholderText())[2], {
        target: {value: "zzznomatch"},
      });

      expect(screen.queryByText(/group_0001/)).not.toBeInTheDocument();
      expect(screen.queryByText(/group_0002/)).not.toBeInTheDocument();
    });
  });
});
