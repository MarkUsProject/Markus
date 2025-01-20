import {render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {SubmissionSelector} from "../Result/submission_selector";
import {ResultContext} from "../Result/result_context";
import {renderInResultContext} from "./result_context_renderer";

let props;
const INITIAL_FILTER_MODAL_STATE = {
  ascending: true,
  orderBy: "group_name",
  annotationText: "",
  tas: [],
  tags: [],
  section: "",
  markingState: "",
  totalMarkRange: {
    min: "",
    max: "",
  },
  totalExtraMarkRange: {
    min: "",
    max: "",
  },
  criteria: {},
};

const basicProps = {
  assignment_max_mark: 100,
  available_tags: [],
  can_release: false,
  criterionSummaryData: [],
  current_tags: [],
  filterData: INITIAL_FILTER_MODAL_STATE,
  fullscreen: false,
  group_name: "group",
  marking_state: "incomplete",
  marks: [],
  nextSubmission: jest.fn(),
  num_collected: 0,
  num_marked: 0,
  previousSubmission: jest.fn(),
  released_to_students: false,
  sections: [],
  setReleasedToStudents: jest.fn().mockImplementation(() => (props.released_to_students = true)),
  toggleFullscreen: jest.fn().mockImplementation(() => (props.fullscreen = !props.fullscreen)),
  toggleMarkingState: jest.fn().mockImplementation(() => {
    props.marking_state === "complete"
      ? (props.marking_state = "incomplete")
      : (props.marking_state = "complete");
  }),
  total: 0,
};

describe("SubmissionSelector", () => {
  beforeEach(() => {
    props = {...basicProps};
  });

  it("should not show anything if it is being viewed by a non-reviewer student", () => {
    renderInResultContext(<SubmissionSelector {...props} />, {role: "Student", is_reviewer: false});
    expect(screen.queryByTestId("submission-selector-container")).toBeNull();
  });

  it("should call nextSubmission when the next-button is pressed", async () => {
    renderInResultContext(<SubmissionSelector {...props} />);
    const button = screen.getByTitle(I18n.t("results.next_submission"), {exact: false});
    await userEvent.click(button);

    expect(props.nextSubmission).toHaveBeenCalled();
  });

  it("should call previousSubmission when the next-button is pressed", async () => {
    renderInResultContext(<SubmissionSelector {...props} />);
    const button = screen.getByTitle(I18n.t("results.previous_submission"), {exact: false});
    await userEvent.click(button);

    expect(props.previousSubmission).toHaveBeenCalled();
  });

  it("should display the group name", () => {
    renderInResultContext(<SubmissionSelector {...props} />);
    expect(screen.getByText(props.group_name)).toBeTruthy();
  });

  it("should show filter modal when filter-button is pressed", async () => {
    renderInResultContext(<SubmissionSelector {...props} />);
    const button = screen.getByTitle(I18n.t("results.filter_submissions"));
    await userEvent.click(button);

    const modal = await screen.findByRole("dialog", {hidden: true});
    expect(modal.classList.contains("filter-modal")).toBeTruthy();
  });

  it("should pass correct values to the progress meter", () => {
    props.num_marked = 50;
    props.num_collected = 100;
    renderInResultContext(<SubmissionSelector {...props} />);
    const meter = screen.getByTestId("progress-bar");
    expect(meter).toHaveAttribute("value", String(props.num_marked));
    expect(meter).toHaveAttribute("min", "0");
    expect(meter).toHaveAttribute("max", String(props.num_collected));
    expect(meter).toHaveAttribute("low", String(props.num_collected * 0.35));
    expect(meter).toHaveAttribute("high", String(props.num_collected * 0.75));
    expect(meter).toHaveAttribute("optimum", String(props.num_collected));
    expect(meter).toHaveTextContent(`${props.num_marked}/${props.num_collected}`);
  });

  it("should display the total correctly", () => {
    props.total = 50;
    props.assignment_max_mark = 100;
    renderInResultContext(<SubmissionSelector {...props} />);
    const expected_display = `${Math.round(props.total * 100) / 100} / ${
      props.assignment_max_mark
    }`;
    expect(screen.getByText(expected_display)).toBeTruthy();
  });

  it("can toggle into fullscreen", async () => {
    renderInResultContext(<SubmissionSelector {...props} />);
    const button = screen.getByTitle(I18n.t("results.fullscreen_enter"), {exact: false});
    await userEvent.click(button);

    expect(props.toggleFullscreen).toHaveBeenCalled();
  });

  it("can toggle out of fullscreen", async () => {
    props.fullscreen = true;
    renderInResultContext(<SubmissionSelector {...props} />);
    const button = screen.getByTitle(I18n.t("results.fullscreen_exit"), {exact: false});
    await userEvent.click(button);

    expect(props.toggleFullscreen).toHaveBeenCalled();
  });

  it("should not allow release if can_release is false", () => {
    props.can_release = false;
    renderInResultContext(<SubmissionSelector {...props} />);
    expect(screen.queryByText(I18n.t("submissions.release_marks"))).toBeNull();
  });

  it("should set the text as unrelease if it has already been released", () => {
    props.released_to_students = true;
    props.can_release = true;
    renderInResultContext(<SubmissionSelector {...props} />);
    const element = screen.queryByRole("button", {name: I18n.t("submissions.unrelease_marks")});
    expect(element).toBeTruthy();
  });

  it("should set the text as release if it has not already been released and disable it if marking state is not complete", () => {
    props.released_to_students = false;
    props.can_release = true;
    renderInResultContext(<SubmissionSelector {...props} />);
    const element = screen.getByRole("button", {name: I18n.t("submissions.release_marks")});
    expect(element).toBeDisabled();
  });

  it("should not disable the release if marking is complete", () => {
    props.released_to_students = false;
    props.can_release = true;
    props.marking_state = "complete";
    renderInResultContext(<SubmissionSelector {...props} />);
    const element = screen.getByRole("button", {name: I18n.t("submissions.release_marks")});
    expect(element).toBeEnabled();
  });

  it("should call props.setReleasedToStudents when release button is clicked", async () => {
    props.marking_state = "complete";
    props.released_to_students = false;
    props.can_release = true;
    renderInResultContext(<SubmissionSelector {...props} />);
    const element = screen.getByRole("button", {name: I18n.t("submissions.release_marks")});
    await userEvent.click(element);

    expect(props.setReleasedToStudents).toHaveBeenCalled();
  });

  it("should have the marking state button function as expected when marking_state is complete", () => {
    props.marking_state = "complete";
    props.released_to_students = false;
    renderInResultContext(<SubmissionSelector {...props} />);

    const button = screen.queryByRole("button", {name: I18n.t("results.set_to_incomplete")});
    expect(button).toBeTruthy();
    expect(button).toBeEnabled();
  });

  it("should have the marking state button function as expected when marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    renderInResultContext(<SubmissionSelector {...props} />);

    const button = screen.queryByRole("button", {name: I18n.t("results.set_to_complete")});
    expect(button).toBeTruthy();
  });

  it("should have the marking state button enabled if props.marks have no unmarked marks and marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    props.marks = [{mark: 5}];
    renderInResultContext(<SubmissionSelector {...props} />);

    const button = screen.queryByRole("button", {name: I18n.t("results.set_to_complete")});
    expect(button).toBeEnabled();
  });

  it("should have the marking state button disabled if props.marks has at least 1 mark with no mark and marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    props.marks = [{mark: 5}, {mark: null}];
    renderInResultContext(<SubmissionSelector {...props} />);

    const button = screen.queryByRole("button", {name: I18n.t("results.set_to_complete")});
    expect(button).toBeDisabled();
  });
});
