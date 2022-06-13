import {shallow, mount} from "enzyme";

import {MarksPanel} from "../Result/marks_panel";
import {screen} from "@testing-library/dom";

const convertToKebabCase = {
  CheckboxCriterion: "checkbox_criterion",
  FlexibleCriterion: "flexible_criterion",
  RubricCriterion: "rubric_criterion",
};

describe("MarksPanel", () => {
  let basicProps;
  const getWrapper = props => {
    return shallow(<MarksPanel {...props} />);
  };
  beforeEach(() => {
    basicProps = {
      max_mark: 100,
      released_to_students: false,
      old_marks: {},
      marks: [],
      levels: [],
      assigned_criteria: [],
      annotations: [],
      updateMark: jest.fn(),
      revertToAutomaticDeductions: jest.fn(),
      findDeductiveAnnotation: jest.fn(),
    };
  });
  it("displays no criterion if marks is an empty list", () => {
    const wrapper = getWrapper();
    expect(wrapper.find("marks-list").length).toBe(0);
  });
  it("displays a criterion of the right type when given an array of marks", () => {
    basicProps.marks.push({
      criterion_type: "CheckboxCriterion",
      id: 67,
      mark: 0,
      description: "testing",
    });
    basicProps.old_marks[67] = [];
    basicProps.marks.push({
      criterion_type: "FlexibleCriterion",
      id: 66,
      mark: 0,
      description: "testing",
    });
    basicProps.old_marks[66] = [];
    basicProps.marks.push({
      criterion_type: "RubricCriterion",
      id: 65,
      mark: 0,
      description: "testing",
    });
    basicProps.old_marks[65] = [];
    const wrapper = getWrapper(basicProps);
    basicProps.marks.forEach(mark => {
      expect(wrapper.find(`#${convertToKebabCase[mark.criterion_type]}_${mark.id}`)).toBeTruthy();
    });
  });
  describe("CheckboxCriterionInput", () => {
    const getWrapper = props => {
      return mount(<MarksPanel {...props} />);
    };
    beforeEach(() => {
      basicProps = {
        released_to_students: false,
        old_marks: {67: []},
        marks: [
          {
            criterion_type: "CheckboxCriterion",
            id: 67,
            mark: 0,
            description: "testing_criterion_description",
          },
        ],
        assigned_criteria: [],
        annotations: [],
        updateMark: jest.fn(),
        revertToAutomaticDeductions: jest.fn(),
        findDeductiveAnnotation: jest.fn(),
      };
    });
    it("it should toggle expand and contract upon clicking the expand/contract button", () => {
      const wrapper = getWrapper(basicProps);

      wrapper.find(`#checkbox_criterion_${basicProps.marks[0].id}_expand`).simulate("click");
      expect(wrapper.state().expanded.has(basicProps.marks[0].id)).toBe(true);

      wrapper.find(`#checkbox_criterion_${basicProps.marks[0].id}_expand`).simulate("click");
      expect(wrapper.state().expanded.has(basicProps.marks[0].id)).toBe(false);
    });
  });
});
