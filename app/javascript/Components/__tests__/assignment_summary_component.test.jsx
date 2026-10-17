import {render, screen} from "@testing-library/react";
import {makeAssignmentSummary} from "../assignment_summary";
import {AssignmentSummaryTable} from "../assignment_summary_table";
import {AssignmentChart} from "../assignment_chart";

const mockRootRender = jest.fn();

jest.mock("react-dom/client", () => ({
  createRoot: jest.fn(() => ({render: mockRootRender})),
}));

jest.mock("../assignment_summary_table", () => ({
  AssignmentSummaryTable: jest.fn(() => <div data-testid="assignment-summary-table" />),
}));

jest.mock("../assignment_chart", () => ({
  AssignmentChart: jest.fn(() => <div data-testid="assignment-chart" />),
}));

jest.mock("react-tabs", () => ({
  Tabs: ({children}) => <div>{children}</div>,
  TabList: ({children}) => <div>{children}</div>,
  Tab: ({children}) => <div>{children}</div>,
  TabPanel: ({children}) => <div>{children}</div>,
}));

const defaultProps = {
  assessment_id: 2,
  can_view_assigned_submissions_only: true,
  course_id: 1,
  encodings: ["UTF-8"],
  initial_show_assigned_submissions_only: false,
  is_instructor: true,
  lti_deployments: [{id: 3}],
};

const renderAssignmentSummary = props => {
  makeAssignmentSummary(document.createElement("div"), props);
  render(mockRootRender.mock.calls[0][0]);
};

describe("AssignmentSummary", () => {
  it("renders the summary table and statistics chart for instructors", () => {
    renderAssignmentSummary(defaultProps);

    expect(screen.getByTestId("assignment-summary-table")).toBeInTheDocument();
    expect(screen.getByTestId("assignment-chart")).toBeInTheDocument();
    expect(AssignmentSummaryTable).toHaveBeenCalledWith(
      expect.objectContaining({
        assignment_id: 2,
        can_view_assigned_submissions_only: true,
        course_id: 1,
        encodings: ["UTF-8"],
        initial_show_assigned_submissions_only: false,
        is_instructor: true,
        lti_deployments: [{id: 3}],
      }),
      undefined
    );
    expect(AssignmentChart).toHaveBeenCalledWith(
      {
        assessment_id: 2,
        course_id: 1,
        show_criteria_stats: true,
      },
      undefined
    );
  });

  it("renders only the summary table for non-instructors", () => {
    renderAssignmentSummary({...defaultProps, is_instructor: false});

    expect(screen.getByTestId("assignment-summary-table")).toBeInTheDocument();
    expect(screen.queryByTestId("assignment-chart")).not.toBeInTheDocument();
    expect(AssignmentChart).not.toHaveBeenCalled();
  });
});
