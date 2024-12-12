import {shallow} from "enzyme";

import {SubmissionSelector} from "../Result/submission_selector";

let props, wrapper;

const basicProps = {
  assignment_max_mark: 100,
  can_release: false,
  course_id: 1,
  fullscreen: false,
  group_name: "group",
  is_reviewer: false,
  marking_state: "incomplete",
  marks: [],
  nextSubmission: jest.fn(),
  num_collected: 0,
  num_marked: 0,
  previousSubmission: jest.fn(),
  released_to_students: false,
  result_id: 1,
  role: "user",
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
  const getWrapper = props => shallow(<SubmissionSelector {...props} />);
  beforeEach(() => {
    props = {...basicProps};
  });

  it("should not show anything if it is being viewed by a non-reviewer student", () => {
    props.role = "Student";
    wrapper = getWrapper(props);
    expect(wrapper.find(".submission-selector-container").exists()).toBeFalsy();
  });

  it("should call nextSubmission when the next-button is pressed", () => {
    wrapper = getWrapper(props);
    expect(wrapper.find(".next").exists()).toBeTruthy();
    wrapper.find(".next").simulate("click");

    expect(props.nextSubmission).toHaveBeenCalled();
  });

  it("should call previousSubmission when the next-button is pressed", () => {
    wrapper = getWrapper(props);
    expect(wrapper.find(".previous").exists()).toBeTruthy();
    wrapper.find(".previous").simulate("click");

    expect(props.previousSubmission).toHaveBeenCalled();
  });

  it("should display the group name", () => {
    wrapper = getWrapper(props);
    expect(wrapper.find(".group-name").text()).toBe(props.group_name);
  });

  it("should show filter modal when filter-button is pressed", () => {
    wrapper = getWrapper(props);
    expect(wrapper.find(".filter").exists()).toBeTruthy();
    wrapper.find(".filter").simulate("click");
    const modal = wrapper.find("FilterModal");

    expect(modal.exists()).toBeTruthy();
  });

  it("should pass correct values to the progress meter", () => {
    props.num_marked = 50;
    props.num_collected = 100;
    wrapper = getWrapper(props);
    const meter = wrapper.find("meter");

    expect(meter.props().value).toBe(props.num_marked);
    expect(meter.props().min).toBe(0);
    expect(meter.props().max).toBe(props.num_collected);
    expect(meter.props().low).toBe(props.num_collected * 0.35);
    expect(meter.props().high).toBe(props.num_collected * 0.75);
    expect(meter.props().optimum).toBe(props.num_collected);
    expect(meter.text()).toBe(`${props.num_marked}/${props.num_collected}`);
  });

  it("should display the total correctly", () => {
    props.total = 50;
    props.assignment_max_mark = 100;
    wrapper = getWrapper(props);
    const expected_display = `${Math.round(props.total * 100) / 100} / ${
      props.assignment_max_mark
    }`;
    expect(wrapper.find(".total").text()).toBe(expected_display);
  });

  it("can toggle into fullscreen", () => {
    wrapper = getWrapper(props);
    expect(wrapper.find(".fullscreen-enter").exists()).toBeTruthy();

    wrapper.find(".fullscreen-enter").simulate("click");
    expect(props.toggleFullscreen).toHaveBeenCalled();
  });

  it("can toggle into fullscreen", () => {
    props.fullscreen = true;
    wrapper = getWrapper(props);
    expect(wrapper.find(".fullscreen-exit").exists()).toBeTruthy();

    wrapper.find(".fullscreen-exit").simulate("click");
    expect(props.toggleFullscreen).toHaveBeenCalled();
  });

  it("should not allow release if can_release is false", () => {
    props.can_release = false;
    wrapper = getWrapper(props);
    expect(wrapper.find(".release").exists()).toBeFalsy();
  });

  it("should set the text as unrelease if it has already been released", () => {
    props.released_to_students = true;
    props.can_release = true;
    wrapper = getWrapper(props);
    expect(wrapper.find(".release").exists()).toBeTruthy();
    expect(wrapper.find(".release").text()).toBe(I18n.t("submissions.unrelease_marks"));
    expect(wrapper.find(".release").props().disabled).toBe(false);
  });

  it("should set the text as release if it has not already been released and disable it if marking state is not complete", () => {
    props.released_to_students = false;
    props.can_release = true;
    wrapper = getWrapper(props);
    expect(wrapper.find(".release").exists()).toBeTruthy();
    expect(wrapper.find(".release").text()).toBe(I18n.t("submissions.release_marks"));
    expect(wrapper.find(".release").props().disabled).toBe(true);
  });

  it("should not disable the release if marking is complete", () => {
    props.released_to_students = false;
    props.can_release = true;
    props.marking_state = "complete";
    wrapper = getWrapper(props);
    expect(wrapper.find(".release").exists()).toBeTruthy();
    expect(wrapper.find(".release").text()).toBe(I18n.t("submissions.release_marks"));
    expect(wrapper.find(".release").props().disabled).toBe(false);
  });

  it("should call toggleMarkingState when release button is clicked", () => {
    props.released_to_students = false;
    props.can_release = true;
    wrapper = getWrapper(props);
    wrapper.find(".release").simulate("click");
    expect(props.setReleasedToStudents).toHaveBeenCalled();
  });

  it("should have the marking state button function as expected when marking_state is complete", () => {
    props.marking_state = "complete";
    props.released_to_students = false;
    wrapper = getWrapper(props);

    const button = wrapper.find(".set-incomplete");

    expect(button.exists()).toBeTruthy();
    expect(button.disabled).toBeFalsy;
    expect(button.text()).toBe(I18n.t("results.set_to_incomplete"));
  });

  it("should have the marking state button function as expected when marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    wrapper = getWrapper(props);

    const button = wrapper.find(".set-complete");

    expect(button.exists()).toBeTruthy();
    expect(button.text()).toBe(I18n.t("results.set_to_complete"));
  });

  it("should have the marking state button enabled if props.marks have no unmarked marks and marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    props.marks = [{mark: 5}];
    wrapper = getWrapper(props);

    const button = wrapper.find(".set-complete");

    expect(button.props().disabled).toBeFalsy();
  });

  it("should have the marking state button disabled if props.marks has at least 1 mark with no mark and marking_state is incomplete", () => {
    props.marking_state = "incomplete";
    props.marks = [{mark: 5}, {mark: null}];
    wrapper = getWrapper(props);

    const button = wrapper.find(".set-complete");

    expect(button.props().disabled).toBeTruthy();
  });
});
