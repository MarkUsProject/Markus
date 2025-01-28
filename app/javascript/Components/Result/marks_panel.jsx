import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../../common/safe_marked";

export class MarksPanel extends React.Component {
  static defaultProps = {
    marks: [],
  };

  constructor(props) {
    super(props);
    this.state = {
      expanded: new Set(),
    };
  }

  componentDidMount() {
    if (!this.props.released_to_students) {
      // TODO: Convert this to pure React
      // Capture the mouse event to add "active-criterion" to the clicked element
      $(document).on("click", ".rubric_criterion, .flexible_criterion, .checkbox_criterion", e => {
        let criterion = $(e.target).closest(
          ".rubric_criterion, .flexible_criterion, .checkbox_criterion"
        );
        if (!criterion.hasClass("unassigned")) {
          e.preventDefault();
          activeCriterion(criterion);
        }
      });
    }
  }

  componentDidUpdate(prevProps) {
    if (prevProps.marks !== this.props.marks) {
      // Expand by default if a mark has not yet been given, and the current user can give the mark.
      let expanded = new Set();
      this.props.marks.forEach(data => {
        const key = data.id;
        if (
          (data.mark === null || data.mark === undefined) &&
          (this.props.assigned_criteria === null || this.props.assigned_criteria.includes(key))
        ) {
          expanded.add(key);
        }
      });
      this.setState({expanded});
    }
  }

  expandAll = onlyUnmarked => {
    let expanded = new Set();
    this.props.marks.forEach(markData => {
      if (!onlyUnmarked || markData.mark === null || markData.mark === undefined) {
        expanded.add(markData.id);
      }
    });
    this.setState({expanded});
  };

  collapseAll = () => {
    this.setState({expanded: new Set()});
  };

  toggleExpanded = key => {
    if (this.state.expanded.has(key)) {
      this.state.expanded.delete(key);
    } else {
      this.state.expanded.add(key);
    }
    this.setState({expanded: this.state.expanded});
  };

  updateMark = (criterion_id, mark) => {
    let result = this.props.updateMark(criterion_id, mark);
    if (result !== undefined) {
      result.then(() => {
        this.state.expanded.delete(criterion_id);
        this.setState({expanded: this.state.expanded});
      });
    }
  };

  destroyMark = (e, criterion_id) => {
    e.stopPropagation();
    this.props.destroyMark(criterion_id);
  };

  renderMarkComponent = markData => {
    const key = markData.id;
    const unassigned =
      this.props.assigned_criteria !== null && !this.props.assigned_criteria.includes(key);

    const props = {
      key: key,
      released_to_students: this.props.released_to_students,
      unassigned: unassigned,
      updateMark: this.updateMark,
      destroyMark: this.destroyMark,
      expanded: this.state.expanded.has(key),
      oldMark: this.props.old_marks[markData.id],
      toggleExpanded: () => this.toggleExpanded(key),
      annotations: this.props.annotations,
      revertToAutomaticDeductions: this.props.revertToAutomaticDeductions,
      findDeductiveAnnotation: this.props.findDeductiveAnnotation,
      ...markData,
    };
    if (markData.criterion_type === "CheckboxCriterion") {
      return <CheckboxCriterionInput {...props} />;
    } else if (markData.criterion_type === "FlexibleCriterion") {
      return <FlexibleCriterionInput {...props} />;
    } else if (markData.criterion_type === "RubricCriterion") {
      return <RubricCriterionInput {...props} />;
    } else {
      return null;
    }
  };

  render() {
    const markComponents = this.props.marks.map(this.renderMarkComponent);

    return (
      <div id="mark_viewer" className="flex-col">
        {!this.props.released_to_students && (
          <div className="text-center">
            <button className="inline-button" onClick={() => this.expandAll()}>
              {I18n.t("results.expand_all")}
            </button>
            <button className="inline-button" onClick={() => this.expandAll(true)}>
              {I18n.t("results.expand_unmarked")}
            </button>
            <button className="inline-button" onClick={() => this.collapseAll()}>
              {I18n.t("results.collapse_all")}
            </button>
          </div>
        )}
        <div id="mark_criteria">
          <ul className="marks-list">{markComponents}</ul>
        </div>
      </div>
    );
  }
}

export class CheckboxCriterionInput extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const unassignedClass = this.props.unassigned ? "unassigned" : "";
    const expandedClass = this.props.expanded ? "expanded" : "collapsed";
    return (
      <li
        id={`checkbox_criterion_${this.props.id}`}
        className={`checkbox_criterion ${expandedClass} ${unassignedClass}`}
      >
        <div>
          <div className="criterion-name" onClick={this.props.toggleExpanded}>
            <div
              className={this.props.expanded ? "arrow-up" : "arrow-down"}
              style={{float: "left"}}
            />
            {this.props.name}
            {this.props.bonus && ` (${I18n.t("activerecord.attributes.criterion.bonus")})`}
            {!this.props.released_to_students &&
              !this.props.unassigned &&
              this.props.mark !== null && (
                <a
                  href="#"
                  onClick={e => this.props.destroyMark(e, this.props.id)}
                  style={{float: "right"}}
                >
                  {I18n.t("helpers.submit.delete", {
                    model: I18n.t("activerecord.models.mark.one"),
                  })}
                </a>
              )}
          </div>
          <div>
            {!this.props.released_to_students && (
              <span className="checkbox-criterion-inputs">
                <label
                  onClick={() => this.props.updateMark(this.props.id, this.props.max_mark)}
                  className={`check_correct_${this.props.id}`}
                >
                  <input
                    type="radio"
                    readOnly={true}
                    checked={this.props.mark === this.props.max_mark}
                    disabled={this.props.released_to_students || this.props.unassigned}
                  />
                  {I18n.t("checkbox_criteria.answer_yes")}
                </label>
                <label
                  onClick={() => this.props.updateMark(this.props.id, 0)}
                  className={`check_no_${this.props.id}`}
                >
                  <input
                    type="radio"
                    readOnly={true}
                    checked={this.props.mark === 0}
                    disabled={this.props.released_to_students || this.props.unassigned}
                  />
                  {I18n.t("checkbox_criteria.answer_no")}
                </label>
              </span>
            )}
            <span className="mark">
              {this.props.mark === null ? "-" : this.props.mark}
              &nbsp;/&nbsp;
              {this.props.max_mark}
            </span>
          </div>
          {this.props.oldMark !== undefined && this.props.oldMark.mark !== undefined && (
            <div className="old-mark">{`(${I18n.t("results.remark.old_mark")}: ${
              this.props.oldMark.mark
            })`}</div>
          )}
          <div
            className="criterion-description"
            dangerouslySetInnerHTML={{__html: safe_marked(this.props.description)}}
          />
        </div>
      </li>
    );
  }
}

CheckboxCriterionInput.propTypes = {
  description: PropTypes.string.isRequired,
  destroyMark: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
  id: PropTypes.number.isRequired,
  mark: PropTypes.number,
  max_mark: PropTypes.number.isRequired,
  oldMark: PropTypes.object,
  released_to_students: PropTypes.bool.isRequired,
  toggleExpanded: PropTypes.func.isRequired,
  unassigned: PropTypes.bool.isRequired,
  updateMark: PropTypes.func.isRequired,
};

export class FlexibleCriterionInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      rawText: this.props.mark === null ? "" : String(this.props.mark),
      invalid: false,
    };
    this.typing_timer = undefined;
  }

  listDeductions = () => {
    let label = I18n.t("annotations.list_deductions");
    let deductiveAnnotations = this.props.annotations.filter(a => {
      return !!a.deduction && a.criterion_id === this.props.id && !a.is_remark;
    });

    if (deductiveAnnotations.length === 0) {
      return "";
    }

    let hyperlinkedDeductions = deductiveAnnotations.map((a, index) => {
      let full_path = a.path ? a.path + "/" + a.filename : a.filename;
      return (
        <span key={a.id}>
          <a
            onClick={() =>
              this.props.findDeductiveAnnotation(
                full_path,
                a.submission_file_id,
                a.line_start,
                a.id
              )
            }
            href="#"
            className={"red-text"}
          >
            {"-" + a.deduction}
          </a>
          {index !== deductiveAnnotations.length - 1 ? ", " : ""}
        </span>
      );
    });

    if (this.props.override) {
      label = "(" + I18n.t("results.overridden_deductions") + ") " + label;
    }

    return (
      <div className={"mark-deductions"}>
        {label}
        {hyperlinkedDeductions}
      </div>
    );
  };

  deleteManualMarkLink = () => {
    if (!this.props.released_to_students && !this.props.unassigned) {
      if (
        this.props.annotations.some(a => !!a.deduction && a.criterion_id === this.props.id) &&
        this.props.override
      ) {
        return (
          <a
            href="#"
            className="flexible-revert"
            onClick={_ => this.props.revertToAutomaticDeductions(this.props.id)}
            style={{float: "right"}}
          >
            {I18n.t("results.cancel_override")}
          </a>
        );
      } else if (this.props.mark !== null && this.props.override) {
        return (
          <a
            href="#"
            onClick={e => this.props.destroyMark(e, this.props.id)}
            style={{float: "right"}}
          >
            {I18n.t("helpers.submit.delete", {
              model: I18n.t("activerecord.models.mark.one"),
            })}
          </a>
        );
      }
    }
    return "";
  };

  renderOldMark = () => {
    if (this.props.oldMark === undefined || this.props.oldMark.mark === undefined) {
      return null;
    }
    let label = String(this.props.oldMark.mark);

    if (this.props.oldMark.override) {
      label = `(${I18n.t("results.overridden_deductions")}) ${label}`;
    }

    return <div className="old-mark">{`(${I18n.t("results.remark.old_mark")}: ${label})`}</div>;
  };

  handleChange = event => {
    if (this.typing_timer) {
      clearTimeout(this.typing_timer);
    }

    const mark = parseFloat(event.target.value);
    if (event.target.value !== "" && isNaN(mark)) {
      this.setState({rawText: event.target.value, invalid: true});
    } else if (mark === this.props.mark) {
      // This can happen if the user types a decimal point at the end of the input.
      this.setState({rawText: event.target.value, invalid: false});
    } else if (mark > this.props.max_mark) {
      this.setState({rawText: event.target.value, invalid: true});
    } else {
      this.setState({rawText: event.target.value, invalid: false});

      this.typing_timer = setTimeout(() => {
        this.props.updateMark(this.props.id, isNaN(mark) ? null : mark);
      }, 300);
    }
  };

  componentDidUpdate(oldProps) {
    if (oldProps.mark !== this.props.mark) {
      this.setState({
        rawText: this.props.mark === null ? "" : String(this.props.mark),
        invalid: false,
      });
    }
  }

  render() {
    const unassignedClass = this.props.unassigned ? "unassigned" : "";
    const expandedClass = this.props.expanded ? "expanded" : "collapsed";

    let markElement;
    if (this.props.released_to_students) {
      // Student view
      markElement = this.props.mark;
    } else {
      markElement = (
        <input
          className={this.state.invalid ? "invalid" : ""}
          type="text"
          size={4}
          value={this.state.rawText}
          onChange={this.handleChange}
          disabled={this.props.unassigned}
        />
      );
    }

    return (
      <li
        id={`flexible_criterion_${this.props.id}`}
        className={`flexible_criterion ${expandedClass} ${unassignedClass}`}
      >
        <div data-testid={this.props.id}>
          <div className="criterion-name" onClick={this.props.toggleExpanded}>
            <div
              className={this.props.expanded ? "arrow-up" : "arrow-down"}
              style={{float: "left"}}
            />
            {this.props.name}
            {this.props.bonus && ` (${I18n.t("activerecord.attributes.criterion.bonus")})`}
            {this.deleteManualMarkLink()}
          </div>
          <div
            className="criterion-description"
            dangerouslySetInnerHTML={{__html: safe_marked(this.props.description)}}
          />
          <span className="mark">
            {markElement}
            &nbsp;/&nbsp;
            {this.props.max_mark}
          </span>
          {this.listDeductions()}
          {this.renderOldMark()}
        </div>
      </li>
    );
  }
}

FlexibleCriterionInput.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object).isRequired,
  bonus: PropTypes.bool,
  description: PropTypes.string.isRequired,
  destroyMark: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
  findDeductiveAnnotation: PropTypes.func.isRequired,
  id: PropTypes.number.isRequired,
  mark: PropTypes.number,
  max_mark: PropTypes.number.isRequired,
  oldMark: PropTypes.object,
  override: PropTypes.bool,
  released_to_students: PropTypes.bool.isRequired,
  revertToAutomaticDeductions: PropTypes.func.isRequired,
  toggleExpanded: PropTypes.func.isRequired,
  unassigned: PropTypes.bool.isRequired,
  updateMark: PropTypes.func.isRequired,
};

export class RubricCriterionInput extends React.Component {
  constructor(props) {
    super(props);
  }

  // The parameter `level` is the level object selected
  handleChange = level => {
    this.props.updateMark(this.props.id, level.mark);
  };

  // The parameter `level` is the level object selected
  renderRubricLevel = level => {
    const levelMark = level.mark.toFixed(2);
    let selectedClass = "";
    let oldMarkClass = "";
    if (
      this.props.mark !== undefined &&
      this.props.mark !== null &&
      levelMark === this.props.mark.toFixed(2)
    ) {
      selectedClass = "selected";
    }
    if (
      this.props.oldMark !== undefined &&
      this.props.oldMark.mark !== undefined &&
      levelMark === this.props.oldMark.mark.toFixed(2)
    ) {
      oldMarkClass = "old-mark";
    }

    return (
      <tr
        onClick={() => this.handleChange(level)}
        key={`${this.props.id}-${levelMark}`}
        className={`rubric-level ${selectedClass} ${oldMarkClass}`}
      >
        <td className="level-description">
          <strong>{level.name}</strong>
          <span dangerouslySetInnerHTML={{__html: safe_marked(level.description)}} />
        </td>
        <td className={"mark"}>
          {levelMark}
          &nbsp;/&nbsp;
          {this.props.max_mark}
        </td>
      </tr>
    );
  };

  render() {
    const levels = this.props.levels.map(this.renderRubricLevel);
    const expandedClass = this.props.expanded ? "expanded" : "collapsed";
    const unassignedClass = this.props.unassigned ? "unassigned" : "";
    return (
      <li
        id={`rubric_criterion_${this.props.id}`}
        className={`rubric_criterion ${expandedClass} ${unassignedClass}`}
      >
        <div data-testid={this.props.id}>
          <div className="criterion-name" onClick={this.props.toggleExpanded}>
            <div
              className={this.props.expanded ? "arrow-up" : "arrow-down"}
              style={{float: "left"}}
            />
            {this.props.name}
            {this.props.bonus && ` (${I18n.t("activerecord.attributes.criterion.bonus")})`}
            {!this.props.released_to_students &&
              !this.props.unassigned &&
              this.props.mark !== null && (
                <a
                  href="#"
                  onClick={e => this.props.destroyMark(e, this.props.id)}
                  style={{float: "right"}}
                >
                  {I18n.t("helpers.submit.delete", {
                    model: I18n.t("activerecord.models.mark.one"),
                  })}
                </a>
              )}
          </div>
          <table className="rubric-levels">
            <tbody>{levels}</tbody>
          </table>
        </div>
      </li>
    );
  }
}

RubricCriterionInput.propTypes = {
  bonus: PropTypes.bool,
  destroyMark: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
  id: PropTypes.number.isRequired,
  levels: PropTypes.array,
  mark: PropTypes.number,
  max_mark: PropTypes.number,
  oldMark: PropTypes.object,
  released_to_students: PropTypes.bool.isRequired,
  toggleExpanded: PropTypes.func.isRequired,
  unassigned: PropTypes.bool.isRequired,
  updateMark: PropTypes.func.isRequired,
};
