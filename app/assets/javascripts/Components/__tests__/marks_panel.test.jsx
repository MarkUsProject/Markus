import {shallow} from "enzyme";

import {
  MarksPanel,
  CheckboxCriterionInput,
  FlexibleCriterionInput,
  RubricCriterionInput,
} from "../Result/marks_panel";
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
});
describe("CheckboxCriterionInput", () => {
  let wrapper, basicProps;
  beforeEach(() => {
    basicProps = {
      id: 67,
      mark: 0,
      max_mark: 1,
      expanded: false,
      unassigned: false,
      released_to_students: false,
      oldMark: {},
      description: " ",
      updateMark: jest.fn(),
      destroyMark: jest.fn(),
      toggleExpanded: jest.fn(),
    };
    wrapper = shallow(<CheckboxCriterionInput {...basicProps} />);
  });
  it("should toggle expand and contract upon clicking the expand/contract button", () => {
    basicProps.toggleExpanded.mockImplementation(() => {
      basicProps.expanded = !basicProps.expanded;
    });
    wrapper.find(`#checkbox_criterion_${basicProps.id}_expand`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    wrapper.find(`#checkbox_criterion_${basicProps.id}_expand`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });
  it("it delete upon the delete button being pressed", () => {
    basicProps.unassigned = false;
    basicProps.mark = 1;
    wrapper.setProps(basicProps);

    wrapper.find(`#checkbox_criterion_${basicProps.id}_destroy`).simulate("click");
    expect(basicProps.destroyMark).toHaveBeenCalledWith(undefined, basicProps.id);
  });
  it("correctly updates mark to max_mark and 0 when clicking on respective buttons", () => {
    basicProps.updateMark.mockImplementation((id, new_mark) => {
      basicProps.mark = new_mark;
    });

    const no_button = wrapper.find(`#check_no_${basicProps.id}`);
    const yes_button = wrapper.find(`#check_correct_${basicProps.id}`);

    yes_button.simulate("click");

    expect(basicProps.mark).toBe(basicProps.max_mark);

    no_button.simulate("click");

    expect(basicProps.mark).toBe(0);
  });
  it("should show bonus if bonus is true", () => {
    wrapper.setProps({
      bonus: true,
    });

    expect(wrapper.html()).toContain(I18n.t("activerecord.attributes.criterion.bonus"));
  });
  it("should not let you update mark if released to studnets", () => {
    wrapper.setProps({
      released_to_students: true,
    });

    expect(wrapper.find(`#checkbox_criterion_${basicProps.id}_destroy`).exists()).toBeFalsy();
    expect(wrapper.find(`#check_no_${basicProps.id}`).exists()).toBeFalsy();
    expect(wrapper.find(`#check_correct_${basicProps.id}`).exists()).toBeFalsy();
  });
  it("should display oldMark.mark", () => {
    wrapper.setProps({
      oldMark: {
        mark: 1,
      },
    });

    expect(wrapper.find(".old-mark").text()).toBe(`(${I18n.t("results.remark.old_mark")}: 1)`);
  });
});
describe("FlexibleCriterionInput", () => {
  let basicProps;
  const getWrapper = props => {
    return shallow(<FlexibleCriterionInput {...props} />);
  };
  beforeEach(() => {
    basicProps = {
      expanded: false,
      unassigned: false,
      released_to_students: false,
      bonus: false,
      override: false,

      id: 66,
      mark: 0,
      max_mark: 2,

      description: " ",

      oldMark: {},

      annotations: [],

      findDeductiveAnnotation: jest.fn(),
      toggleExpanded: jest.fn(),
      revertToAutomaticDeductions: jest.fn(),
      destroyMark: jest.fn(),
      updateMark: jest.fn(),
    };
  });
  it("should toggle expand and contract upon clicking the expand/contract button", () => {
    basicProps.toggleExpanded.mockImplementation(() => {
      basicProps.expanded = !basicProps.expanded;
    });
    const wrapper = getWrapper(basicProps);

    wrapper.find(`#flexible_criterion_${basicProps.id}_expand`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    wrapper.find(`#flexible_criterion_${basicProps.id}_expand`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });
});
