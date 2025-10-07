import {render, screen} from "@testing-library/react";
import {GroupsManager} from "../groups_manager";
import {beforeEach, describe, expect, it} from "@jest/globals";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

const groupMock = [
  {
    group_name: "c6scriab",
    inactive: false,
    instructor_approved: true,
    members: [
      {
        0: "c6scriab",
        1: "inviter",
        2: false,
        display_label: "(inviter)",
      },
    ],
    extension: {
      apply_penalty: false,
      grouping_id: 22,
      id: null,
      note: "",
    },
    section: "",
  },
  {
    group_name: "student1",
    inactive: false,
    instructor_approved: true,
    members: [
      {
        0: "student1",
        1: "inviter",
        2: false,
        display_label: "(inviter)",
      },
    ],
    section: "",
    extension: {
      apply_penalty: true,
      days: 2,
      grouping_id: 16,
      hours: 0,
      id: 51,
      minutes: 0,
      note: "",
      weeks: 0,
    },
  },
];
const studentMock = [
  {
    assigned: true,
    first_name: "coolStudent",
    hidden: false,
    id: 8,
    last_name: "Alberic",
    user_name: "student1",
  },
];

describe("GroupsManager", () => {
  let filter_method = null;
  let wrapper = React.createRef();

  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        templates: [],
        groups: groupMock,
        exam_templates: [],
        students: studentMock,
        clone_assignments: [],
      }),
    });
    const props = {
      course_id: 1,
      timed: false,
      assignment_id: 2,
      scanned_exam: false,
      examTemplates: [],
      times: ["weeks", "days", "hours", "minutes"],
    };
    render(<GroupsManager {...props} ref={wrapper} />);
    // wait for page to load and render content
    await screen.findByText("abcd").catch(err => err);
    // to view screen render: screen.debug(undefined, 300000)
  });

  describe("DueDateExtensions", () => {
    beforeEach(() => {
      filter_method =
        wrapper.current.groupsTable.wrapped.checkboxTable.props.columns[5].filterMethod;
    });

    it("append (Late Submissions Accepted) to assignments with extensions", async () => {
      const searchTerm = I18n.t("groups.late_submissions_accepted");
      expect(await screen.getByText(new RegExp(searchTerm, "i"))).toBeInTheDocument();
    });

    it("returns true when the selected value is all", () => {
      expect(filter_method({value: "all"})).toEqual(true);
    });

    describe("withExtension: false", () => {
      it("returns true when assignments without an extension are present", () => {
        const rowMock = {_original: {extension: {}}};
        const filterOptionsMock = JSON.stringify({withExtension: false});
        expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(true);
      });
      it("returns false when assignments with an extension are present", () => {
        const rowMock = {_original: {extension: {hours: 1}}};
        const filterOptionsMock = JSON.stringify({withExtension: false});
        expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
      });
    });

    describe("withExtension: true", () => {
      describe("withLateSubmission: true", () => {
        it("returns true when assignments have a late submission rule applied", () => {
          const rowMock = {_original: {extension: {hours: 1, apply_penalty: true}}};
          const filterOptionsMock = JSON.stringify({withExtension: true, withLateSubmission: true});
          expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(true);
        });
        it("returns false when assignments are missing an extension", () => {
          const rowMock = {_original: {extension: {apply_penalty: true}}};
          const filterOptionsMock = JSON.stringify({withExtension: true, withLateSubmission: true});
          expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
        });
      });
      describe("withLateSubmission: false", () => {
        it("returns true when assignments are missing an extension", () => {
          const rowMock = {_original: {extension: {hours: 1, apply_penalty: true}}};
          const filterOptionsMock = JSON.stringify({
            withExtension: true,
            withLateSubmission: false,
          });
          expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
        });

        it("returns false when assignments have a late submission rule applied", () => {
          const rowMock = {_original: {extension: {hours: 1, apply_penalty: true}}};
          const filterOptionsMock = JSON.stringify({
            withExtension: true,
            withLateSubmission: false,
          });
          expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
        });
      });
    });
  });
});
