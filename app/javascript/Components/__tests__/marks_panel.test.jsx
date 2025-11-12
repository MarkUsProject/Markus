import {render, screen, waitFor, fireEvent} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {MarksPanel} from "../Result/marks_panel";

import CheckboxCriterionInput from "../Result/checkbox_criterion_input";
import FlexibleCriterionInput from "../Result/flexible_criterion_input";
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

  it("does not set an active criterion if marks is empty", () => {
    const {container} = render(<MarksPanel {...basicProps} />);

    // No criterion should be marked active
    const active = container.querySelector(".active-criterion");
    expect(active).toBeNull();
  });

  it("sets the first criterion as active on mount if marks exists", () => {
    const props = {
      ...basicProps,
      assigned_criteria: null,
      marks: [
        {
          criterion_type: "CheckboxCriterion",
          id: 67,
          name: "Criterion 1",
          mark: 0,
          max_mark: 1,
          description: "testing",
        },
        {
          criterion_type: "FlexibleCriterion",
          id: 66,
          name: "Criterion 2",
          mark: 0,
          max_mark: 2,
          description: "testing",
        },
      ],
      old_marks: {67: {}, 66: {}},
    };

    render(<MarksPanel {...props} />);

    const firstCriterion = document.querySelector("#checkbox_criterion_67");
    expect(firstCriterion).toHaveClass("active-criterion");
  });

  it("changes active criterion when clicked", () => {
    const props = {
      ...basicProps,
      assigned_criteria: null,
      marks: [
        {
          criterion_type: "CheckboxCriterion",
          id: 67,
          name: "Criterion 1",
          mark: 0,
          max_mark: 1,
          description: "testing",
        },
        {
          criterion_type: "FlexibleCriterion",
          id: 66,
          name: "Criterion 2",
          mark: 0,
          max_mark: 2,
          description: "testing",
        },
      ],
      old_marks: {67: {}, 66: {}},
    };

    render(<MarksPanel {...props} />);

    const firstCriterion = document.querySelector("#checkbox_criterion_67");
    const secondCriterion = document.querySelector("#flexible_criterion_66");

    expect(firstCriterion).toHaveClass("active-criterion");
    expect(secondCriterion).not.toHaveClass("active-criterion");

    // Click on second criterion
    fireEvent.click(secondCriterion);

    expect(firstCriterion).not.toHaveClass("active-criterion");
    expect(secondCriterion).toHaveClass("active-criterion");
  });

  it("navigates to next criterion using window.marksPanel.nextCriterion", async () => {
    const props = {
      ...basicProps,
      assigned_criteria: null,
      marks: [
        {
          criterion_type: "CheckboxCriterion",
          id: 67,
          name: "Criterion 1",
          mark: 0,
          max_mark: 1,
          description: "testing",
        },
        {
          criterion_type: "FlexibleCriterion",
          id: 66,
          name: "Criterion 2",
          mark: 0,
          max_mark: 2,
          description: "testing",
        },
      ],
      old_marks: {67: {}, 66: {}},
    };

    render(<MarksPanel {...props} />);

    const firstCriterion = document.querySelector("#checkbox_criterion_67");
    const secondCriterion = document.querySelector("#flexible_criterion_66");

    expect(firstCriterion).toHaveClass("active-criterion");

    // Navigate to next
    window.marksPanel.nextCriterion();

    await waitFor(() => {
      expect(firstCriterion).not.toHaveClass("active-criterion");
      expect(secondCriterion).toHaveClass("active-criterion");
    });
  });

  it("navigates to previous criterion using window.marksPanel.prevCriterion", async () => {
    const props = {
      ...basicProps,
      assigned_criteria: null,
      marks: [
        {
          criterion_type: "CheckboxCriterion",
          id: 67,
          name: "Criterion 1",
          mark: 0,
          max_mark: 1,
          description: "testing",
        },
        {
          criterion_type: "FlexibleCriterion",
          id: 66,
          name: "Criterion 2",
          mark: 0,
          max_mark: 2,
          description: "testing",
        },
      ],
      old_marks: {67: {}, 66: {}},
    };

    render(<MarksPanel {...props} />);

    const firstCriterion = document.querySelector("#checkbox_criterion_67");
    const secondCriterion = document.querySelector("#flexible_criterion_66");

    expect(firstCriterion).toHaveClass("active-criterion");

    window.marksPanel.prevCriterion();

    await waitFor(() => {
      expect(firstCriterion).not.toHaveClass("active-criterion");
      expect(secondCriterion).toHaveClass("active-criterion");
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

  it("renders CheckboxCriterionInput with radio buttons", () => {
    render(<CheckboxCriterionInput {...basicProps} />);

    // Check at least 1 criterion label renders
    expect(screen.getAllByText(/criterion/i).length).toBeGreaterThan(0);

    // Check at least 1 radio button pair render (yes/no)
    const radios = screen.getAllByRole("radio");
    expect(radios.length).toBeGreaterThanOrEqual(2);
  });

  it("shows Delete Mark link when mark exists and not released", () => {
    render(<CheckboxCriterionInput {...basicProps} mark={1} />);

    // Check at least one delete link renders
    const deleteLinks = screen.getAllByText(/delete mark/i);
    expect(deleteLinks.length).toBeGreaterThan(0);
  });

  it("auto-expands when active prop changes", () => {
    const {rerender} = render(<CheckboxCriterionInput {...basicProps} active={false} />);

    // Initially not active & not expanded
    expect(basicProps.expanded).toBe(false);

    // Make component active
    rerender(<CheckboxCriterionInput {...basicProps} active={true} />);
    expect(basicProps.expanded).toBe(true);
  });
  it("focuses the checked input when active or the first input if none checked", () => {
    // Case 1: First input (Yes) checked
    basicProps.mark = 1;
    basicProps.active = false;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    const yesInput = document.querySelector(`.check_correct_${basicProps.id} input`);
    const noInput = document.querySelector(`.check_no_${basicProps.id} input`);

    basicProps.active = true;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    expect(document.activeElement).toBe(yesInput);

    // Case 2: Second input (No) checked
    basicProps.mark = 0;
    basicProps.active = false;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    basicProps.active = true;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    expect(document.activeElement).toBe(noInput);

    // Case 3: No input checked (mark is null) - should focus first input
    basicProps.mark = null;
    basicProps.active = false;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    basicProps.active = true;
    rerender(<CheckboxCriterionInput {...basicProps} />);

    expect(document.activeElement).toBe(yesInput);
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
    await waitFor(() => {
      expect(input.classList.contains("invalid")).toBeTruthy();
    });
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

  it("renders FlexibleCriterionInput with input field", () => {
    render(<FlexibleCriterionInput {...basicProps} />);

    // Check input box for marks renders
    const input = screen.getByRole("textbox");
    expect(input).toBeInTheDocument();
  });

  it("updates input value when mark prop changes", () => {
    const {rerender} = render(<FlexibleCriterionInput {...basicProps} mark={2} />);

    const input = screen.getByRole("textbox");
    expect(input.value).toBe("2");

    // Re-render with new mark
    rerender(<FlexibleCriterionInput {...basicProps} mark={5} />);
    expect(input.value).toBe("5");

    // Re-render with null mark (should clear it)
    rerender(<FlexibleCriterionInput {...basicProps} mark={null} />);
    expect(input.value).toBe("");
  });

  it("auto-expands when becoming active while collapsed", () => {
    const props = {...basicProps, expanded: false, active: false};
    const {rerender} = render(<FlexibleCriterionInput {...props} />);

    expect(basicProps.expanded).toBe(false);

    // Make component active
    rerender(<FlexibleCriterionInput {...{...props, active: true}} />);

    expect(basicProps.toggleExpanded).toHaveBeenCalled();
    expect(basicProps.expanded).toBe(true);
  });

  it("does not focus input when active but not expanded", () => {
    const props = {...basicProps, expanded: false, active: false};
    const {rerender} = render(<FlexibleCriterionInput {...props} />);

    const input = screen.getByRole("textbox");

    // Make component active
    rerender(<FlexibleCriterionInput {...{...props, active: true}} />);

    // Input shouldn't be focused yet because expanded is still false in this render
    expect(document.activeElement).not.toBe(input);
  });

  it("does not focus input when expanded but not active", () => {
    const props = {...basicProps, expanded: true, active: false};
    render(<FlexibleCriterionInput {...props} />);

    const input = screen.getByRole("textbox");
    expect(document.activeElement).not.toBe(input);
  });

  it("focuses input when active and expanded", () => {
    const props = {...basicProps, expanded: true};
    const {rerender} = render(<FlexibleCriterionInput {...props} active={false} />);

    const input = screen.getByRole("textbox");
    expect(input).toBeInTheDocument();

    // Make component active
    rerender(<FlexibleCriterionInput {...props} active={true} />);
    expect(document.activeElement).toBe(input);
  });

  it("places cursor at the end of input when focused", () => {
    const props = {...basicProps, mark: 1.5, expanded: true};
    const {rerender} = render(<FlexibleCriterionInput {...props} active={false} />);
    const input = screen.getByRole("textbox");

    rerender(<FlexibleCriterionInput {...props} active={true} />);

    expect(document.activeElement).toBe(input);
    expect(input.selectionStart).toBe(3); // '1.5' has length 3
    expect(input.selectionEnd).toBe(3);
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

  it("renders RubricCriterionInput with rubric levels", () => {
    render(<RubricCriterionInput {...basicProps} />);

    // Check criterion label renders
    expect(screen.getByText(/criterion/i)).toBeInTheDocument();

    // Check rubric levels render
    expect(screen.getByText(/level 1/i)).toBeInTheDocument();
    expect(screen.getByText(/level 2/i)).toBeInTheDocument();

    // Check rubric description renders
    const descriptions = screen.getAllByText(/description/i);
    expect(descriptions).toHaveLength(2);
  });

  it("auto-expands when active becomes true", () => {
    const {rerender} = render(<RubricCriterionInput {...basicProps} active={false} />);

    // Initially not active & not expanded
    expect(basicProps.expanded).toBe(false);

    // Make component active
    rerender(<RubricCriterionInput {...basicProps} active={true} />);
    expect(basicProps.expanded).toBe(true);
  });

  it("highlights the selected rubric level based on mark", () => {
    // Select the one with mark = 2
    const props = {...basicProps, mark: 2};

    render(<RubricCriterionInput {...props} />);

    const selectedRow = screen.getByText("level 2").closest("tr");
    expect(selectedRow).toHaveClass("selected");

    const unselectedRow = screen.getByText("level 1").closest("tr");
    expect(unselectedRow).not.toHaveClass("selected");
  });

  it("adds active-rubric class to selected level when active", () => {
    const props = {...basicProps, mark: 2, active: true};
    render(<RubricCriterionInput {...props} />);

    const selectedRow = screen.getByText("level 2").closest("tr");
    expect(selectedRow).toHaveClass("selected");
    expect(selectedRow).toHaveClass("active-rubric");

    const unselectedRow = screen.getByText("level 1").closest("tr");
    expect(unselectedRow).not.toHaveClass("active-rubric");
  });

  it("adds active-rubric class to first level when active and no level selected", () => {
    const props = {...basicProps, mark: null, active: true};
    render(<RubricCriterionInput {...props} />);

    const firstRow = screen.getByText("level 1").closest("tr");
    expect(firstRow).toHaveClass("active-rubric");
    expect(firstRow).not.toHaveClass("selected");

    const secondRow = screen.getByText("level 2").closest("tr");
    expect(secondRow).not.toHaveClass("active-rubric");
  });

  it("does not add active-rubric class when not active", () => {
    const props = {...basicProps, mark: 2, active: false};
    render(<RubricCriterionInput {...props} />);

    const selectedRow = screen.getByText("level 2").closest("tr");
    expect(selectedRow).toHaveClass("selected");
    expect(selectedRow).not.toHaveClass("active-rubric");
  });
});
