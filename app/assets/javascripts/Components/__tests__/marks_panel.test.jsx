import {shallow} from "enzyme";

import {
  MarksPanel,
  CheckboxCriterionInput,
  FlexibleCriterionInput,
  RubricCriterionInput,
} from "../Result/marks_panel";

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
      max_mark: 1,
      description: "testing",
    });
    basicProps.old_marks[67] = {};
    basicProps.marks.push({
      criterion_type: "FlexibleCriterion",
      id: 66,
      mark: 0,
      max_mark: 2,
      description: "testing",
    });
    basicProps.old_marks[66] = {};
    basicProps.marks.push({
      criterion_type: "RubricCriterion",
      id: 65,
      mark: 0,
      max_mark: 2,
      description: "testing",
    });
    basicProps.old_marks[65] = {};
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
      updateMark: jest.fn().mockImplementation((id, new_mark) => {
        basicProps.mark = new_mark;
      }),
      destroyMark: jest.fn(),
      toggleExpanded: jest.fn().mockImplementation(() => {
        basicProps.expanded = !basicProps.expanded;
      }),
    };
    wrapper = shallow(<CheckboxCriterionInput {...basicProps} />);
  });

  it("should toggle expand and contract upon clicking the expand/contract button", () => {
    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("it delete upon the delete button being pressed", () => {
    basicProps.unassigned = false;
    basicProps.mark = 1;
    wrapper.setProps(basicProps);

    wrapper.find(`a`).simulate("click");
    expect(basicProps.destroyMark).toHaveBeenCalledWith(undefined, basicProps.id);
  });

  it("correctly updates mark to max_mark and 0 when clicking on respective buttons", () => {
    const no_button = wrapper.find(`.check_no_${basicProps.id}`);
    const yes_button = wrapper.find(`.check_correct_${basicProps.id}`);

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

  it("should not let you update mark if released to students", () => {
    wrapper.setProps({
      released_to_students: true,
    });

    expect(wrapper.find(`a`).exists()).toBeFalsy();
    expect(wrapper.find(`.check_no_${basicProps.id}`).exists()).toBeFalsy();
    expect(wrapper.find(`.check_correct_${basicProps.id}`).exists()).toBeFalsy();
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

      oldMark: {override: false},

      annotations: [{annotation: "annotation"}],

      findDeductiveAnnotation: jest.fn(),
      revertToAutomaticDeductions: jest.fn(),
      updateMark: jest.fn().mockImplementation((id, new_mark) => {
        basicProps.mark = new_mark;
      }),
      destroyMark: jest.fn(),
      toggleExpanded: jest.fn().mockImplementation(() => {
        basicProps.expanded = !basicProps.expanded;
      }),
    };
  });

  it("should toggle expand and contract upon clicking the expand/contract button", () => {
    const wrapper = getWrapper(basicProps);

    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("should show bonus if bonus is true", () => {
    basicProps.bonus = true;
    const wrapper = getWrapper(basicProps);

    expect(wrapper.html()).toContain(I18n.t("activerecord.attributes.criterion.bonus"));
  });

  it("should show list deductions correctly when there is a deduction", () => {
    basicProps.annotations = [
      {
        deduction: 1,
        criterion_id: basicProps.id,
        submission_file_id: basicProps.id,
        id: basicProps.id + 1,
        line_start: 1,
        is_remark: false,
        filename: "filename",
      },
    ];
    const wrapper = getWrapper(basicProps);

    const deductionLink = wrapper.find(`.red-text`);
    expect(deductionLink.exists()).toBeTruthy();
    deductionLink.simulate("click");
    expect(basicProps.findDeductiveAnnotation).toHaveBeenCalledWith(
      "filename",
      basicProps.id,
      1,
      basicProps.id + 1
    );
  });

  it("should notify if the mark is overriden", () => {
    basicProps.annotations = [
      {
        deduction: 1,
        criterion_id: basicProps.id,
        submission_file_id: basicProps.id,
        id: basicProps.id + 1,
        line_start: 1,
        is_remark: false,
        filename: "filename",
      },
    ];
    basicProps.override = true;
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".mark-deductions").text()).toContain(
      "(" + I18n.t("results.overridden_deductions") + ") "
    );
  });

  it("should display oldMark if it exists", () => {
    basicProps.oldMark = {mark: 1};
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".old-mark").exists()).toBeTruthy();
    expect(wrapper.find(".old-mark").text()).toBe(
      `(${I18n.t("results.remark.old_mark")}: ${basicProps.oldMark.mark})`
    );
  });

  it("should display oldMark with override if it exists", () => {
    basicProps.oldMark = {mark: 1, override: true};
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".old-mark").exists()).toBeTruthy();
    expect(wrapper.find(".old-mark").text()).toBe(
      `(${I18n.t("results.remark.old_mark")}: (${I18n.t("results.overridden_deductions")}) ${
        basicProps.oldMark.mark
      })`
    );
  });

  it("should call handleChange on change and set rawText to new value", () => {
    const wrapper = getWrapper(basicProps);

    const input = wrapper.find(`input[size=4]`);
    input.simulate("change", {target: {value: 1}});
    expect(wrapper.state().rawText).toBe(1);
  });

  it("should set the mark as invalid if it is greater than max_mark", () => {
    const wrapper = getWrapper(basicProps);

    const input = wrapper.find(`input[size=4]`);
    input.simulate("change", {target: {value: 999}});
    expect(wrapper.state().rawText).toBe(999);
    expect(wrapper.state().invalid).toBeTruthy();
  });

  it("should set the mark as invalid if it is not a number", () => {
    const wrapper = getWrapper(basicProps);

    const input = wrapper.find(`input[size=4]`);
    input.simulate("change", {target: {value: "Hi Prof Liu"}});
    expect(wrapper.state().rawText).toBe("Hi Prof Liu");
    expect(wrapper.state().invalid).toBeTruthy();
  });

  it("should set the mark as valid if it has a decimal", () => {
    const wrapper = getWrapper(basicProps);

    const input = wrapper.find(`input[size=4]`);
    input.simulate("change", {target: {value: 2.0}});
    expect(wrapper.state().rawText).toBe(2.0);
    expect(wrapper.state().invalid).toBeFalsy();
  });

  it("should delete a mark correctly", () => {
    basicProps.mark = 1;
    basicProps.override = true;
    const wrapper = getWrapper(basicProps);

    const destroyer = wrapper.find(`a`);

    destroyer.simulate("click");

    expect(basicProps.destroyMark).toHaveBeenCalledWith(undefined, basicProps.id);
  });

  it("should revert a mark correctly", () => {
    basicProps.mark = 1;
    basicProps.override = true;
    basicProps.annotations = [
      {
        deduction: 1,
        criterion_id: basicProps.id,
        submission_file_id: basicProps.id,
        id: basicProps.id + 1,
        line_start: 1,
        is_remark: false,
        filename: "filename",
      },
    ];
    const wrapper = getWrapper(basicProps);

    const reverter = wrapper.find(`.flexible-revert`);

    reverter.simulate("click");

    expect(basicProps.revertToAutomaticDeductions).toHaveBeenCalledWith(basicProps.id);
  });

  it("should have no number input fields", () => {
    basicProps.released_to_students = true;
    const wrapper = getWrapper(basicProps);
    expect(wrapper.find("input[number]").length).toBe(0);
  });
});

describe("RubricCriterionInput", () => {
  let basicProps;
  const getWrapper = props => {
    return shallow(<RubricCriterionInput {...props} />);
  };
  beforeEach(() => {
    basicProps = {
      expanded: false,
      unassigned: false,
      released_to_students: false,
      bonus: false,

      id: 66,
      mark: 0,
      max_mark: 1,

      oldMark: {},
      levels: [
        {mark: 1, name: "level 1", description: "description"},
        {mark: 2, name: "level 2", description: "description2"},
      ],

      updateMark: jest.fn().mockImplementation((id, new_mark) => {
        if (basicProps.released_to_students) {
          return;
        }
        basicProps.mark = new_mark;
      }),
      destroyMark: jest.fn(),
      toggleExpanded: jest.fn().mockImplementation(() => {
        basicProps.expanded = !basicProps.expanded;
      }),
    };
  });

  it("should toggle expand and contract upon clicking the expand/contract button", () => {
    const wrapper = getWrapper(basicProps);

    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    wrapper.find(`.criterion-name`).simulate("click");
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("should destroy properly upon clicking destroy", () => {
    const wrapper = getWrapper(basicProps);

    wrapper.find(`a`).simulate("click");
    expect(basicProps.destroyMark).toHaveBeenCalledWith(undefined, basicProps.id);
  });

  it("should mark as bonus", () => {
    basicProps.bonus = true;

    const wrapper = getWrapper(basicProps);

    expect(wrapper.html()).toContain(` (${I18n.t("activerecord.attributes.criterion.bonus")})`);
  });

  it("should display as many rubric levels as in levels", () => {
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".level-description").length).toBe(2);
  });

  it("should handleChange on clicking a rubric level", () => {
    const wrapper = getWrapper(basicProps);
    console.log(wrapper.find(".rubric-level"));
    const level1 = wrapper.find(`.rubric-level`).at(0);
    const level2 = wrapper.find(`.rubric-level`).at(1);

    level1.simulate("click");

    expect(basicProps.updateMark).toHaveBeenCalledWith(basicProps.id, 1);

    level2.simulate("click");

    expect(basicProps.updateMark).toHaveBeenCalledWith(basicProps.id, 2);
  });

  it("should not show a class is selected or an old-mark by default", () => {
    const wrapper = getWrapper(basicProps);
    expect(wrapper.find(".old-mark").exists()).toBeFalsy();
    expect(wrapper.find(".selected").exists()).toBeFalsy();
  });

  it("should show a class is selected", () => {
    basicProps.mark = 1;
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".selected").exists()).toBeTruthy();
  });

  it("should show a class is selected", () => {
    basicProps.oldMark.mark = 1;
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(".old-mark").exists()).toBeTruthy();
  });

  it("should not let you destroy if released_to_students", () => {
    basicProps.released_to_students = true;
    const wrapper = getWrapper(basicProps);

    expect(wrapper.find(`a`).exists()).toBeFalsy();
  });
});
