/***
 * Tests for TestRunTable Component
 */

import {TestRunTable} from "../test_run_table";
import {render, screen} from "@testing-library/react";
import {expect} from "@jest/globals";

describe("For the TestRunTable's display of status", () => {
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

  it("displays the matching status when run the autotest", async () => {
    const expectedText = I18n.t(
      `automated_tests.test_runs_statuses.${test_run_data[0]["test_runs.status"]}`
    );
    await screen.findByText(expectedText);
    expect(screen.getByText(expectedText)).toBeInTheDocument();
  });
});

describe("For the TestRunTable's display of timeout error type", () => {
  let test_run_data;

  beforeEach(async () => {
    test_run_data = [
      {
        "test_runs.id": 55,
        "test_runs.created_at": "Thursday, November 13, 2025, 08:22:22 PM EST",
        "test_runs.status": "",
        "users.user_name": "c5bennet",
        test_results: [
          {
            "test_groups.id": 2,
            "test_groups.name": "tg2",
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
    const timeoutText = I18n.t("automated_tests.test_runs_statuses.timeout");
    await screen.findByText(timeoutText);
    expect(screen.getByText(timeoutText)).toBeInTheDocument();
  });
});
