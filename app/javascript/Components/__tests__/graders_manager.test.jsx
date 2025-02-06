/***
 * Tests for GradersManager Component
 */

import {GradersManager} from "../graders_manager";
import {render, screen, fireEvent} from "@testing-library/react";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("For the GradersManager's display of inactive groups", () => {
  let groups_sample;
  beforeEach(async () => {
    groups_sample = [
      {
        _id: 15,
        members: [
          ["c9nielse", "inviter", true],
          ["c8szyman", "accepted", true],
        ],
        inactive: false,
        grace_credits: 5,
        remaining_grace_credits: 4,
        group_name: "group_0015",
        graders: [],
        criteria_coverage_count: 0,
      },
      {
        _id: 15,
        members: [
          ["d2lifese", "inviter", false],
          ["a3kjcbod", "accepted", false],
        ],
        inactive: false,
        grace_credits: 5,
        remaining_grace_credits: 4,
        group_name: "group_0014",
        graders: [],
        criteria_coverage_count: 0,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        graders: [],
        criteria: [],
        assign_graders_to_criteria: false,
        loading: false,
        sections: {},
        anonymize_groups: false,
        hide_unassigned_criteria: false,
        isGraderDistributionModalOpen: false,
        groups: groups_sample,
      }),
    });
    render(<GradersManager sections={{}} course_id={1} assignment_id={1} />);

    await screen.findByText("group_0014"); // Wait for data to be rendered
  });

  it("contains the correct amount of inactive groups in the hidden tooltip", () => {
    expect(screen.getByTestId("show_hidden_groups_tooltip").getAttribute("title")).toEqual(
      "1 inactive group"
    );
  });

  it("initially doesn't contain the inactive group", () => {
    expect(screen.queryByText("group_0015")).not.toBeInTheDocument();
  });

  it("contains the inactive group after a single toggle", () => {
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    expect(screen.getByText("group_0015")).toBeInTheDocument();
  });

  it("doesn't contain the inactive group after two toggles", () => {
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    fireEvent.click(screen.getByTestId("show_hidden_groups"));
    expect(screen.queryByText("group_0015")).not.toBeInTheDocument();
  });
});
