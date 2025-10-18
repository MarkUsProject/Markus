import React from "react";

import CheckboxCriterionInput from "./checkbox_criterion_input";
import FlexibleCriterionInput from "./flexible_criterion_input";
import RubricCriterionInput from "./rubric_criterion_input";

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
