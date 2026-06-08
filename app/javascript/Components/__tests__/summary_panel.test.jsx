import React from "react";
import {fireEvent, screen, waitFor} from "@testing-library/react";
import {SummaryPanel} from "../Result/summary_panel";
import {renderInResultContext} from "./result_context_renderer";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => <span />,
}));

jest.mock("react-chartjs-2", () => ({
  Bar: ({data}) => <div data-labels={data.labels.join(",")} data-testid="marks-chart" />,
}));

describe("SummaryPanel", () => {
  let props;

  beforeEach(() => {
    props = {
      assignment_max_mark: 10,
      criterionSummaryData: [{criterion: "Question 1", mark: 8, max_mark: 10}],
      createExtraMark: jest.fn(),
      deleteGraceTokenDeduction: jest.fn(),
      destroyExtraMark: jest.fn(),
      extra_marks: [],
      extraMarkSubtotal: 0,
      graceTokenDeductions: [],
      marks: [{id: 1, name: "Question 1", mark: 8, max_mark: 10}],
      old_marks: {},
      released_to_students: true,
      remark_submitted: false,
      subtotal: 8,
      total: 8,
    };
  });

  it("opens the marks chart in a React modal", async () => {
    renderInResultContext(<SummaryPanel {...props} />, {is_reviewer: false});

    expect(screen.queryByTestId("marks-chart")).not.toBeInTheDocument();

    fireEvent.click(screen.getByText(I18n.t("results.marks_chart")));

    const chart = await screen.findByTestId("marks-chart");
    expect(chart).toHaveAttribute("data-labels", "Question 1");
    expect(document.getElementById("marks_chart")).toHaveClass(
      "react-modal",
      "markus-dialog",
      "data-chart-container"
    );

    fireEvent.click(document.querySelector(".ReactModal__Overlay"));

    await waitFor(() => {
      expect(screen.queryByTestId("marks-chart")).not.toBeInTheDocument();
    });
  });
});
