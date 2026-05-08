import {render, screen, fireEvent} from "@testing-library/react";
import {GroupsManager} from "../groups_manager";
import {beforeEach, describe, expect, it} from "@jest/globals";
import {getTimeExtension} from "../Helpers/table_helpers";

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
    group_name: "group2",
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

    it("append (late submissions accepted) to assignments with extensions", async () => {
      const groupWithExtension = groupMock[1];
      const timePeriods = ["weeks", "days", "hours", "minutes"];
      const timeExtension = getTimeExtension(groupWithExtension.extension, timePeriods);
      const searchTerm = `${timeExtension} (${I18n.t("groups.late_submissions_accepted")})`;
      expect(await screen.getByRole("link", {name: searchTerm})).toBeInTheDocument();
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

describe("For the GroupsManager's group name search", () => {
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
    render(<GroupsManager {...props} />);
    await screen.findByText("c6scriab");
  });

  it("is case-sensitive by default", () => {
    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "C6"}});

    expect(screen.queryByText("c6scriab")).not.toBeInTheDocument();
    expect(screen.queryByText("group2")).not.toBeInTheDocument();
  });

  it("matches case-sensitively when given exact case", () => {
    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "c6"}});

    expect(screen.getByText("c6scriab")).toBeInTheDocument();
    expect(screen.queryByText("group2")).not.toBeInTheDocument();
  });

  it("becomes case-insensitive when the toggle is unchecked", () => {
    fireEvent.click(screen.getByTestId("group_name_case_sensitive"));

    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "C6"}});

    expect(screen.getByText("c6scriab")).toBeInTheDocument();
    expect(screen.queryByText("group2")).not.toBeInTheDocument();
  });

  it("returns to case-sensitive when toggled back", () => {
    const toggle = screen.getByTestId("group_name_case_sensitive");
    fireEvent.click(toggle); // off
    fireEvent.click(toggle); // on again

    const groupSearch = screen.getByRole("textbox", {
      name: `${I18n.t("search")} ${I18n.t("activerecord.models.group.one")}`,
    });
    fireEvent.change(groupSearch, {target: {value: "C6"}});

    expect(screen.queryByText("c6scriab")).not.toBeInTheDocument();
    expect(screen.queryByText("group2")).not.toBeInTheDocument();
  });
});
