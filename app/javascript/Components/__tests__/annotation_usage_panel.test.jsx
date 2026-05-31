/***
 * Tests for AnnotationUsagePanel Component
 */

import {AnnotationUsagePanel} from "../annotation_usage_panel";
import {render, screen, fireEvent} from "@testing-library/react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => null,
}));

describe("For the AnnotationUsagePanel's group name search", () => {
  beforeEach(async () => {
    const applications = [
      {
        result_id: 1,
        user_name: "alice",
        first_name: "Alice",
        last_name: "First",
        group_name: "Alpha_001",
        count: 1,
      },
      {
        result_id: 2,
        user_name: "bob",
        first_name: "Bob",
        last_name: "Second",
        group_name: "alpha_002",
        count: 1,
      },
      {
        result_id: 3,
        user_name: "carol",
        first_name: "Carol",
        last_name: "Third",
        group_name: "Beta_003",
        count: 1,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce(applications),
    });

    render(<AnnotationUsagePanel course_id={1} assignment_id={1} annotation_id={1} num_used={3} />);

    fireEvent.click(screen.getByText(I18n.t("annotations.usage")));
    await screen.findByText("(alice) Alice First");
  });

  it("is case-insensitive by default", () => {
    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.submission.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "alpha"}});

    expect(screen.getByText("(alice) Alice First")).toBeInTheDocument();
    expect(screen.getByText("(bob) Bob Second")).toBeInTheDocument();
    expect(screen.queryByText("(carol) Carol Third")).not.toBeInTheDocument();
  });

  it("becomes case-sensitive when the toggle is checked", () => {
    fireEvent.click(screen.getByTestId("group_name_case_sensitive"));

    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.submission.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "Alpha"}});

    expect(screen.getByText("(alice) Alice First")).toBeInTheDocument();
    expect(screen.queryByText("(bob) Bob Second")).not.toBeInTheDocument();
    expect(screen.queryByText("(carol) Carol Third")).not.toBeInTheDocument();
  });
});
