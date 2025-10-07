import {render} from "@testing-library/react";
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
    section: "",
  },
];
const studentMock = [
  {
    assigned: true,
    first_name: "Magnard",
    hidden: false,
    id: 8,
    last_name: "Alberic",
    user_name: "c9magnar",
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
        students: studentMock,
        clone_assignments: [],
      }),
    });
    const props = {
      course_id: 1,
      assignment_id: 2,
    };
    render(<GroupsManager {...props} ref={wrapper} />);
  });

  describe("DueDateExtensions", () => {
    beforeEach(() => {
      filter_method =
        wrapper.current.groupsTable.wrapped.checkboxTable.props.columns[5].filterMethod;
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
        const rowMock = {_original: {extension: {weeks: 1}}};
        const filterOptionsMock = JSON.stringify({withExtension: false});
        expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
      });
    });

    describe("withExtension: true", () => {
      describe("withLateSubmission: true", () => {
        it("returns true when assignments have a late submission rule applied", () => {
          const rowMock = {_original: {extension: {weeks: 1, apply_penalty: true}}};
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
          const rowMock = {_original: {extension: {weeks: 1, apply_penalty: true}}};
          const filterOptionsMock = JSON.stringify({
            withExtension: true,
            withLateSubmission: false,
          });
          expect(filter_method({value: filterOptionsMock}, rowMock)).toEqual(false);
        });

        it("returns false when assignments have a late submission rule applied", () => {
          const rowMock = {_original: {extension: {weeks: 1, apply_penalty: true}}};
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
