import React from "react";
import {render, screen} from "@testing-library/react";
import {GradeBreakdownChart} from "../Assessment_Chart/grade_breakdown_chart";

jest.mock("react-chartjs-2", () => ({
  Bar: () => <div data-testid="bar-chart">Bar Chart</div>,
}));

jest.mock("../Assessment_Chart/fraction_stat", () => ({
  FractionStat: ({numerator, denominator}) => (
    <div data-testid="fraction-stat">
      {numerator}/{denominator}
    </div>
  ),
}));

jest.mock("../Assessment_Chart/core_statistics", () => ({
  CoreStatistics: () => <div data-testid="core-statistics" />,
}));

jest.mock("../table/table", () => {
  return function MockTable(props) {
    const firstRow = props.data[0];
    const averageColumn = props.columns.find(
      // find the "average" column
      col => col.id === "average" || col.accessorKey === "average"
    );

    return (
      <div data-testid="mock-table">
        <div data-testid="table-columns">{props.columns.length} columns</div>
        <div data-testid="table-data">{props.data.length} rows</div>
        {averageColumn?.cell?.({
          row: {original: firstRow},
        })}
        {props.renderSubComponent && props.renderSubComponent({row: {original: firstRow}})}
      </div>
    );
  };
});

describe("GradeBreakdownChart when summary data exists", () => {
  const defaultProps = {
    show_stats: true,
    summary: [
      {
        name: "Quiz 1",
        position: 1,
        average: 85,
        median: 87,
        max_mark: 100,
        standard_deviation: 10,
        num_zeros: 2,
      },
      {
        name: "Quiz 2",
        position: 2,
        average: 90,
        median: 92,
        max_mark: 100,
        standard_deviation: 8,
        num_zeros: 1,
      },
    ],
    chart_title: "Grade Distribution",
    distribution_data: {
      labels: ["0-10", "11-20", "21-30"],
      datasets: [{data: [5, 10, 15]}],
    },
    item_name: "Test Quiz",
    num_groupings: 50,
    create_link: "/quizzes/new",
  };

  it("renders the bar chart", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    expect(screen.getByTestId("bar-chart")).toBeInTheDocument();
  });

  it("renders the summary table when show_stats is true", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    expect(screen.getByTestId("mock-table")).toBeInTheDocument();
  });

  it("does not render the summary table when show_stats is false", () => {
    render(<GradeBreakdownChart {...defaultProps} show_stats={false} />);
    expect(screen.queryByTestId("mock-table")).not.toBeInTheDocument();
  });

  it("passes correct number of columns to table", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    // 3 columns: position (hidden), name, average
    expect(screen.getByTestId("table-columns")).toHaveTextContent("3 columns");
  });

  it("passes summary data to table", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    expect(screen.getByTestId("table-data")).toHaveTextContent("2 rows");
  });

  it("renders FractionStat for average column", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    expect(screen.getByTestId("fraction-stat")).toHaveTextContent("85/100");
  });

  it("renders CoreStatistics when row is expanded", () => {
    render(<GradeBreakdownChart {...defaultProps} />);
    expect(screen.getByTestId("core-statistics")).toBeInTheDocument();
  });
});

describe("GradeBreakdownChart when summary data is empty", () => {
  const emptyProps = {
    show_stats: true,
    summary: [],
    chart_title: "Grade Distribution",
    distribution_data: {
      labels: ["0-10", "11-20", "21-30"],
      datasets: [{data: [5, 10, 15]}],
    },
    item_name: "Test Quiz",
    num_groupings: 50,
    create_link: "/quizzes/new",
  };
  it("does not render the summary table", () => {
    render(<GradeBreakdownChart {...emptyProps} />);
    expect(screen.queryByTestId("mock-table")).not.toBeInTheDocument();
  });
});
