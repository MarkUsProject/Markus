/***
 * Tests for TestRunTable Component
 */

import {TestRunTable} from "../test_run_table";
import {render, screen} from "@testing-library/react";
import {expect} from "@jest/globals";

describe("For the TestRunTable's display of timeout status", () => {
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
            "test_groups.id": 1,
            "test_groups.name": "tg",
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
