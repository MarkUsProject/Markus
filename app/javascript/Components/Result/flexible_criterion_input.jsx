import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../../common/safe_marked";

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
