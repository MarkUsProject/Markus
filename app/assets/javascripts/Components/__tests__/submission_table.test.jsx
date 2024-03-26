/***
 * Tests for SubmissionTable Component
 */

import {SubmissionTable} from "../submission_table";
import {screen, fireEvent} from "@testing-library/react";
import {mount} from "enzyme";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

describe("For the SubmissionTable's display of inactive groups", () => {
  let groups_sample, wrapper;
  beforeEach(() => {
    groups_sample = [
      {
        _id: 1,
        max_mark: 21.0,
        group_name: "group_0001",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 1,
        final_grade: 12.0,
        members: [
          ["c6scriab", true],
          ["g5dalber", true],
        ],
        grace_credits_used: 1,
      },
      {
        _id: 2,
        max_mark: 21.0,
        group_name: "group_0002",
        tags: [],
        marking_state: "released",
        submission_time: "Monday, March 25, 2024, 01:49:14 PM EDT",
        result_id: 2,
        final_grade: 7.0,
        members: [
          ["g8butter", false],
          ["g6duparc", false],
        ],
        section: "LEC0101",
        grace_credits_used: 1,
      },
    ];
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        groupings: groups_sample,
        sections: {},
      }),
    });

    wrapper = mount(
      <SubmissionTable
        assignment_id={1}
        course_id={1}
        show_grace_tokens={true}
        show_sections={true}
        is_timed={false}
        is_scanned_exam={false}
        release_with_urls={false}
        can_collect={true}
        can_run_tests={false}
        defaultFiltered={[{id: "", value: ""}]}
      />
    );
  });

  it("contains the correct amount of inactive groups in the hidden tooltip", () => {
    wrapper.update();

    expect(wrapper.find({"data-testid": "show_inactive_groups_tooltip"}).prop("title")).toEqual(
      "1 inactive group"
    );
  });

  it("initially contains the active group", () => {
    wrapper.update();

    expect(wrapper.text().includes("group_0002")).toBe(true);
  });

  it("initially does not contain the inactive group", () => {
    wrapper.update();

    expect(wrapper.text().includes("group_0001")).toBe(false);
  });

  it("contains the inactive group after a single toggle", () => {
    wrapper.update();

    wrapper
      .find({"data-testid": "show_inactive_groups"})
      .simulate("change", {target: {checked: true}});

    expect(wrapper.text().includes("group_0001")).toBe(true);
  });

  it("doesn't contain the inactive group after two toggles", () => {
    wrapper.update();

    wrapper
      .find({"data-testid": "show_inactive_groups"})
      .simulate("change", {target: {checked: true}});
    wrapper
      .find({"data-testid": "show_inactive_groups"})
      .simulate("change", {target: {checked: false}});

    expect(wrapper.text().includes("group_0001")).toBe(false);
  });
});
