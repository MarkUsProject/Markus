import {render, screen} from "@testing-library/react";
import {Bar} from "react-chartjs-2";
import {AssessmentChart} from "../Assessment_Chart/assessment_chart";
import {CoreStatistics} from "../Assessment_Chart/core_statistics";
import {FractionStat} from "../Assessment_Chart/fraction_stat";

jest.mock("react-chartjs-2", () => ({
  Bar: jest.fn(() => <div data-testid="bar-chart" />),
}));

describe("AssessmentChart", () => {
  it("renders the distribution, core statistics, and additional statistics", () => {
    const assessmentData = {
      labels: ["0-10", "11-20"],
      datasets: [{data: [1, 2]}],
    };

    render(
      <AssessmentChart
        assessment_data={assessmentData}
        summary={{
          average: 75,
          groupings_size: 10,
          max_mark: 100,
          median: 80,
          num_fails: 2,
          num_zeros: 1,
          standard_deviation: 5,
        }}
        additional_assessment_stats={<span>Additional statistics</span>}
        outstanding_remark_request_link={<a href="/remarks">Remark requests</a>}
      />
    );

    expect(screen.getByTestId("bar-chart")).toBeInTheDocument();
    expect(screen.getByText("Additional statistics")).toBeInTheDocument();
    expect(screen.getByRole("link", {name: "Remark requests"})).toHaveAttribute("href", "/remarks");
    expect(screen.getByText("75 / 100 (75.00%)")).toBeInTheDocument();
    expect(Bar.mock.calls[0][0]).toEqual(
      expect.objectContaining({
        data: assessmentData,
        height: "450",
        width: "500",
      })
    );
  });
});

describe("CoreStatistics", () => {
  const defaultProps = {
    average: 75,
    max_mark: 100,
    median: 80,
    num_fails: 2,
    num_groupings: 10,
    num_zeros: 1,
    standard_deviation: 5,
  };

  it("renders calculated statistics, including the optional failed count", () => {
    const {container} = render(<CoreStatistics {...defaultProps} />);

    expect(container).toHaveTextContent("75 / 100 (75.00%)");
    expect(container).toHaveTextContent("80 / 100 (80.00%)");
    expect(container).toHaveTextContent("5.00 (5.00%)");
    expect(container).toHaveTextContent("2 / 10 (20.00%)");
    expect(container).toHaveTextContent("1 / 10 (10.00%)");
  });

  it("omits the failed count when it is not provided", () => {
    const {num_fails, ...props} = defaultProps;
    render(<CoreStatistics {...props} />);

    expect(screen.queryByText(I18n.t("num_failed"))).not.toBeInTheDocument();
  });

  it("avoids division by zero for the standard deviation percentage", () => {
    const {container} = render(<CoreStatistics {...defaultProps} max_mark={0} />);

    expect(container).toHaveTextContent("5.00 (0.00%)");
  });
});

describe("FractionStat", () => {
  it("rounds displayed values and calculates the percentage from the original values", () => {
    render(<FractionStat numerator={1.234} denominator={4.567} />);

    expect(screen.getByText("1.23 / 4.57 (27.02%)")).toBeInTheDocument();
  });

  it("normalizes invalid values and avoids division by zero", () => {
    render(<FractionStat numerator="invalid" denominator={0} />);

    expect(screen.getByText("0 / 0 (0.00%)")).toBeInTheDocument();
  });
});
