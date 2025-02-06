/***
 * Tests for AssignmentSummaryTable Component
 */

import {AssignmentSummaryTable} from "../assignment_summary_table";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";

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
      expect(screen.getByText(/download test results/i)).toBeInTheDocument();
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
      expect(screen.queryByText(/download test results/i)).not.toBeInTheDocument();
    });
  });
});
