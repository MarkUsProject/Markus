/***
 * Tests for TestRunTable Component
 */

import {TestRunTable} from "../test_run_table";
import {render, screen} from "@testing-library/react";
import {expect} from "@jest/globals";

describe("For the TestRunTable's display of correct data", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 47,
        "test_runs.created_at": "Thursday, November 13, 2025, 08:12:15 PM EST",
        "test_runs.status": "complete",
        "users.user_name": "c8mahler",
        test_results: [
          {
            "test_groups.id": 1,
            "test_groups.name": "tg1",
            "test_group_results.error_type": null,
            "test_results.marks_earned": 5,
            "test_results.marks_total": 10,
            feedback_files: [],
          },
        ],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays the date and time the test was created", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:12:15 PM EST");
    expect(screen.getByText("Thursday, November 13, 2025, 08:12:15 PM EST")).toBeInTheDocument();
  });

  it("displays the username with the 'Run by' label", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:12:15 PM EST");
    const userLabel = I18n.t("activerecord.attributes.test_run.user");
    const expectedText = `${userLabel} c8mahler`;
    expect(screen.getByText(expectedText)).toBeInTheDocument();
  });

  it("displays complete matching status when run the autotest", async () => {
    const status = test_run_data[0]["test_runs.status"]; // "complete"
    const statusKey = I18n.t(`automated_tests.test_runs_statuses.${status}`);

    expect(statusKey).toEqual(I18n.t("automated_tests.test_runs_statuses.complete"));

    await screen.findByText(statusKey);
    expect(screen.getByText(statusKey)).toBeInTheDocument();
  });

  it("displays marks earned out of total when error_type is null", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:12:15 PM EST");
    const marksElements = await screen.findAllByText(/5.*\/.*10/);
    expect(marksElements.length).toBeGreaterThan(0);
  });

  it("does not display test run problems when they are not present", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:12:15 PM EST");
    expect(screen.queryByText("Test runs problems")).not.toBeInTheDocument();
  });
});

describe("For the TestRunTable's display of failed status", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 48,
        "test_runs.created_at": "Thursday, November 13, 2025, 08:13:29 PM EST",
        "test_runs.status": "failed",
        "users.user_name": "c8mahler",
        test_results: [
          {
            "test_groups.id": 2,
            "test_groups.name": "tg2",
            "test_group_results.error_type": null,
            "test_results.marks_earned": 1,
            "test_results.marks_total": 2,
            feedback_files: [],
          },
        ],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays failed status when run the autotest", async () => {
    const status = test_run_data[0]["test_runs.status"]; // "failed"
    const statusKey = I18n.t(`automated_tests.test_runs_statuses.${status}`);
    expect(statusKey).toEqual(I18n.t("automated_tests.test_runs_statuses.failed")); // "error"

    const [statusCell] = await screen.findAllByText(statusKey, {
      selector: "div.rt-td",
    });
    expect(statusCell).toBeInTheDocument();
  });
});

describe("For the TestRunTable's display of cancelled status", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 49,
        "test_runs.created_at": "Friday, November 14, 2025, 09:00:00 AM EST",
        "test_runs.status": "cancelled",
        "users.user_name": "c9debuss",
        test_results: [
          {
            "test_groups.id": 3,
            "test_groups.name": "tg3",
            "test_group_results.error_type": null,
            "test_results.marks_earned": 0,
            "test_results.marks_total": 1,
            feedback_files: [],
          },
        ],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays cancelled status when a run is cancelled without timeout", async () => {
    const status = test_run_data[0]["test_runs.status"]; // "cancelled"
    const statusKey = I18n.t(`automated_tests.test_runs_statuses.${status}`);

    expect(statusKey).toEqual(I18n.t("automated_tests.test_runs_statuses.cancelled"));

    await screen.findByText(statusKey);
    expect(screen.getByText(statusKey)).toBeInTheDocument();
  });
});

describe("For the TestRunTable's display of in_progress status", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 50,
        "test_runs.created_at": "Friday, November 14, 2025, 09:05:00 AM EST",
        "test_runs.status": "in_progress",
        "users.user_name": "c9yoyo",
        test_results: [
          {
            "test_groups.id": 4,
            "test_groups.name": "tg4",
            "test_group_results.error_type": null,
            "test_results.marks_earned": 0,
            "test_results.marks_total": 0,
            feedback_files: [],
          },
        ],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays in progress status when a test is running", async () => {
    const status = test_run_data[0]["test_runs.status"]; // "in progress"
    const statusKey = I18n.t(`automated_tests.test_runs_statuses.${status}`);

    expect(statusKey).toEqual(I18n.t("automated_tests.test_runs_statuses.in_progress"));

    await screen.findByText(statusKey);
    expect(screen.getByText(statusKey)).toBeInTheDocument();
  });
});

describe("For the TestRunTable's display of timeout error type", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 51,
        "test_runs.created_at": "Thursday, November 13, 2025, 08:22:22 PM EST",
        "test_runs.status": "",
        "users.user_name": "c5bennet",
        test_results: [
          {
            "test_groups.id": 5,
            "test_groups.name": "tg5",
            "test_group_results.error_type": "timeout",
            "test_results.marks_earned": 0,
            "test_results.marks_total": 0,
            feedback_files: [],
          },
        ],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays timeout when any test group result has error_type timeout", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:22:22 PM EST");
    const timeoutText = I18n.t("activerecord.attributes.test_group_result.timeout");
    await screen.findByText(timeoutText);
    expect(screen.getByText(timeoutText)).toBeInTheDocument();
  });
});

describe("For the TestRunTable's SubComponent display of problems", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 52,
        "test_runs.created_at": "Thursday, November 13, 2025, 08:45:25 PM EST",
        "test_runs.status": "failed",
        "test_runs.problems": "Test runs problems",
        "users.user_name": "c8mahler",
        test_results: [],
      },
    ];

    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(test_run_data),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays problems text when test_runs.problems is present", async () => {
    await screen.findByText("Thursday, November 13, 2025, 08:45:25 PM EST");
    expect(screen.getByText("Test runs problems")).toBeInTheDocument();
  });
});

describe("For the TestRunTable's display when no data is available", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce([]),
    });

    render(
      <TestRunTable
        course_id={1}
        result_id={1}
        submission_id={1}
        assignment_id={1}
        grouping_id={1}
        instructor_run={true}
        instructor_view={true}
      />
    );
  });

  it("displays no data text when there are no test runs", async () => {
    const noResultsText = I18n.t("automated_tests.no_results");
    await screen.findByText(noResultsText);
    expect(screen.getByText(noResultsText)).toBeInTheDocument();
  });
});
