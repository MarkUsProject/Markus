import {render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {MarksPanel} from "../Result/marks_panel";

import CheckboxCriterionInput from "../Result/checkbox_criterion_input";
import {FlexibleCriterionInput} from "../Result/flexible_criterion_input";
import RubricCriterionInput from "../Result/rubric_criterion_input";

const convertToKebabCase = {
  CheckboxCriterion: "checkbox_criterion",
  FlexibleCriterion: "flexible_criterion",
  RubricCriterion: "rubric_criterion",
};

describe("MarksPanel", () => {
  let basicProps;
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
    const {container} = render(<MarksPanel {...basicProps} />);
    expect(container.querySelector(".marks-list").children.length).toBe(0);
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
      levels: [],
    });
    basicProps.old_marks[65] = {};

    const {container} = render(<MarksPanel {...basicProps} />);
    basicProps.marks.forEach(mark => {
      expect(
        container.querySelector(`#${convertToKebabCase[mark.criterion_type]}_${mark.id}`)
      ).toBeTruthy();
    });
  });
});

describe("CheckboxCriterionInput", () => {
  let basicProps, rerender;
  beforeEach(() => {
    basicProps = {
      id: 67,
      name: "criterion",
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
    const rendered = render(<CheckboxCriterionInput {...basicProps} />);
    rerender = rendered.rerender;
  });

  it("should toggle expand and contract upon clicking the expand/contract button", async () => {
    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("it delete upon the delete button being pressed", async () => {
    basicProps.unassigned = false;
    basicProps.mark = 1;
    await rerender(<CheckboxCriterionInput {...basicProps} />);

    await userEvent.click(
      screen.getByRole("link", {
        name: I18n.t("helpers.submit.delete", {model: I18n.t("activerecord.models.mark.one")}),
      })
    );
    expect(basicProps.destroyMark).toHaveBeenCalled();
  });

  it("correctly updates mark to max_mark and 0 when clicking on respective buttons", async () => {
    const no_button = screen.getByLabelText(I18n.t("checkbox_criteria.answer_no"));
    const yes_button = screen.getByLabelText(I18n.t("checkbox_criteria.answer_yes"));

    await userEvent.click(yes_button);
    expect(basicProps.mark).toEqual(basicProps.max_mark);

    await userEvent.click(no_button);
    expect(basicProps.mark).toEqual(0);
  });

  it("should show bonus if bonus is true", async () => {
    rerender(<CheckboxCriterionInput {...basicProps} bonus={true} />);
    const bonusText = await screen.findByText(I18n.t("activerecord.attributes.criterion.bonus"), {
      exact: false,
    });
    expect(bonusText).toBeTruthy();
  });

  it("should not let you update mark if released to students", async () => {
    await rerender(<CheckboxCriterionInput {...basicProps} released_to_students={true} />);

    expect(screen.queryAllByRole("link")).toEqual([]);
    expect(screen.queryByLabelText(I18n.t("checkbox_criteria.answer_no"))).toBeNull();
    expect(screen.queryByLabelText(I18n.t("checkbox_criteria.answer_yes"))).toBeNull();
  });

  it("should display oldMark.mark", async () => {
    basicProps.oldMark = {mark: 1};
    await rerender(<CheckboxCriterionInput {...basicProps} />);

    expect(screen.queryByText(`(${I18n.t("results.remark.old_mark")}: 1)`)).toBeTruthy();
  });

  it("renders CheckboxCriterionInput", () => {
    render(<CheckboxCriterionInput {...basicProps} />);
  });
});

describe("FlexibleCriterionInput", () => {
  let basicProps;
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

      name: "criterion",
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

  it("should toggle expand and contract upon clicking the expand/contract button", async () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("should show bonus if bonus is true", async () => {
    basicProps.bonus = true;
    render(<FlexibleCriterionInput {...basicProps} />);

    const bonusText = await screen.findByText(I18n.t("activerecord.attributes.criterion.bonus"), {
      exact: false,
    });
    expect(bonusText).toBeTruthy;
  });

  it("should show list deductions correctly when there is a deduction", async () => {
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
    render(<FlexibleCriterionInput {...basicProps} />);

    const deductionLink = screen.getByRole("link", {name: "-1"});
    expect(deductionLink).toBeTruthy();
    await userEvent.click(deductionLink);
    expect(basicProps.findDeductiveAnnotation).toHaveBeenCalledWith(
      "filename",
      basicProps.id,
      1,
      basicProps.id + 1
    );
  });

  it("should notify if the mark is overridden", () => {
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
    render(<FlexibleCriterionInput {...basicProps} />);

    expect(
      screen.queryByText("(" + I18n.t("results.overridden_deductions") + ") ", {exact: false})
    ).toBeTruthy();
  });

  it("should display oldMark if it exists", () => {
    basicProps.oldMark = {mark: 1};
    render(<FlexibleCriterionInput {...basicProps} />);

    expect(
      screen.queryByText(`(${I18n.t("results.remark.old_mark")}: ${basicProps.oldMark.mark})`)
    ).toBeTruthy();
  });

  it("should display oldMark with override if it exists", () => {
    basicProps.oldMark = {mark: 1, override: true};
    render(<FlexibleCriterionInput {...basicProps} />);

    expect(
      screen.queryByText(
        `(${I18n.t("results.remark.old_mark")}: (${I18n.t("results.overridden_deductions")}) ${
          basicProps.oldMark.mark
        })`
      )
    ).toBeTruthy();
  });

  it("should call handleChange on change and set rawText to new value", async () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    let input = screen.getByRole("textbox");
    await userEvent.type(input, "1");
    input = screen.getByRole("textbox");
    expect(Number(input.value)).toEqual(1);
    expect(input.classList.contains("invalid")).toBeFalsy();
  });

  it("should set the mark as invalid if it is greater than max_mark", async () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    const input = screen.getByRole("textbox");
    await userEvent.type(input, "999");
    expect(Number(input.value)).toEqual(999);
    expect(input.classList.contains("invalid")).toBeTruthy();
  });

  it("should set the mark as invalid if it is not a number", async () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    const input = screen.getByRole("textbox");
    await userEvent.clear(input);
    await userEvent.type(input, "Hi Prof Liu");
    expect(input.value).toEqual("Hi Prof Liu");
    expect(input.classList.contains("invalid")).toBeTruthy();
  });

  it("should set the mark as valid if it has a decimal", async () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    const input = screen.getByRole("textbox");
    await userEvent.type(input, "1.5");
    expect(Number(input.value)).toEqual(1.5);
    expect(input.classList.contains("invalid")).toBeFalsy();
  });

  it("should delete a mark correctly", async () => {
    basicProps.mark = 1;
    basicProps.override = true;
    render(<FlexibleCriterionInput {...basicProps} />);

    const destroyer = screen.getByRole("link", {
      name: I18n.t("helpers.submit.delete", {model: I18n.t("activerecord.models.mark.one")}),
    });
    await userEvent.click(destroyer);

    expect(basicProps.destroyMark).toHaveBeenCalled();
  });

  it("should revert a mark correctly", async () => {
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
    render(<FlexibleCriterionInput {...basicProps} />);

    const reverter = screen.getByRole("link", {name: I18n.t("results.cancel_override")});
    await userEvent.click(reverter);

    expect(basicProps.revertToAutomaticDeductions).toHaveBeenCalledWith(basicProps.id);
  });

  it("should have no input fields when marks are released", () => {
    basicProps.released_to_students = true;
    render(<FlexibleCriterionInput {...basicProps} />);
    expect(screen.queryAllByRole("textbox")).toEqual([]);
  });

  it("renders FlexibleCriterionInput", () => {
    render(<FlexibleCriterionInput {...basicProps} />);
  });
});

describe("RubricCriterionInput", () => {
  let basicProps;
  beforeEach(() => {
    basicProps = {
      expanded: false,
      unassigned: false,
      released_to_students: false,
      bonus: false,

      id: 66,
      name: "criterion",
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

  it("should toggle expand and contract upon clicking the expand/contract button", async () => {
    render(<RubricCriterionInput {...basicProps} />);

    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeTruthy();

    await userEvent.click(screen.getByText("criterion"));
    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBeFalsy();
  });

  it("should destroy properly upon clicking destroy", async () => {
    render(<RubricCriterionInput {...basicProps} />);

    await userEvent.click(
      screen.getByRole("link", {
        name: I18n.t("helpers.submit.delete", {model: I18n.t("activerecord.models.mark.one")}),
      })
    );
    expect(basicProps.destroyMark).toHaveBeenCalled();
  });

  it("should mark as bonus", () => {
    basicProps.bonus = true;
    render(<RubricCriterionInput {...basicProps} />);

    expect(
      screen.getByText(` (${I18n.t("activerecord.attributes.criterion.bonus")})`, {exact: false})
    ).toBeTruthy();
  });

  it("should display as many rubric levels as in levels", () => {
    render(<RubricCriterionInput {...basicProps} />);

    expect(screen.queryByText("level 1")).toBeTruthy();
    expect(screen.queryByText("level 2")).toBeTruthy();
  });

  it("should handleChange on clicking a rubric level", async () => {
    render(<RubricCriterionInput {...basicProps} />);

    const level1 = screen.getByText("level 1");
    const level2 = screen.getByText("level 2");

    await userEvent.click(level1);
    expect(basicProps.updateMark).toHaveBeenCalledWith(basicProps.id, 1);

    await userEvent.click(level2);
    expect(basicProps.updateMark).toHaveBeenCalledWith(basicProps.id, 2);
  });

  it("should not show a class is selected or an old-mark by default", () => {
    const {container} = render(<RubricCriterionInput {...basicProps} />);
    expect(container.querySelector(".old-mark")).toBeNull();
    expect(container.querySelector(".selected")).toBeNull();
  });

  it("should show a level is selected when a mark has been entered", () => {
    basicProps.mark = 1;
    render(<RubricCriterionInput {...basicProps} />);

    const levels = screen.getAllByRole("row");
    expect(levels[0].classList.contains("selected")).toBeTruthy();
  });

  it("should show a level is selected when an old mark has been entere", () => {
    basicProps.oldMark.mark = 1;
    render(<RubricCriterionInput {...basicProps} />);

    const levels = screen.getAllByRole("row");
    expect(levels[0].classList.contains("old-mark")).toBeTruthy();
  });

  it("should not let you destroy if released_to_students", () => {
    basicProps.released_to_students = true;
    render(<RubricCriterionInput {...basicProps} />);

    expect(screen.queryAllByRole("link")).toEqual([]);
  });

  it("renders RubricCriterionInput", () => {
    render(<RubricCriterionInput {...basicProps} />);
  });
});
