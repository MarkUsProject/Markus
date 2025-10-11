import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../../common/safe_marked";

export default function CheckboxCriterionInput({
  description,
  destroyMark,
  expanded,
  id,
  mark,
  max_mark,
  oldMark,
  released_to_students,
  toggleExpanded,
  unassigned,
  updateMark,
  name,
  bonus,
}) {
  const unassignedClass = unassigned ? "unassigned" : "";
  const expandedClass = expanded ? "expanded" : "collapsed";

  return (
    <li
      id={`checkbox_criterion_${id}`}
      className={`checkbox_criterion ${expandedClass} ${unassignedClass}`}
    >
      <div>
        <div className="criterion-name" onClick={toggleExpanded}>
          <div className={expanded ? "arrow-up" : "arrow-down"} style={{float: "left"}} />
          {name}
          {bonus && ` (${I18n.t("activerecord.attributes.criterion.bonus")})`}
          {!released_to_students && !unassigned && mark !== null && (
            <a href="#" onClick={e => destroyMark(e, id)} style={{float: "right"}}>
              {I18n.t("helpers.submit.delete", {
                model: I18n.t("activerecord.models.mark.one"),
              })}
            </a>
          )}
        </div>
        <div>
          {!released_to_students && (
            <span className="checkbox-criterion-inputs">
              <label onClick={() => updateMark(id, max_mark)} className={`check_correct_${id}`}>
                <input
                  type="radio"
                  readOnly={true}
                  checked={mark === max_mark}
                  disabled={released_to_students || unassigned}
                />
                {I18n.t("checkbox_criteria.answer_yes")}
              </label>
              <label onClick={() => updateMark(id, 0)} className={`check_no_${id}`}>
                <input
                  type="radio"
                  readOnly={true}
                  checked={mark === 0}
                  disabled={released_to_students || unassigned}
                />
                {I18n.t("checkbox_criteria.answer_no")}
              </label>
            </span>
          )}
          <span className="mark">
            {mark === null ? "-" : mark}
            &nbsp;/&nbsp;
            {max_mark}
          </span>
        </div>
        {oldMark !== undefined && oldMark.mark !== undefined && (
          <div className="old-mark">{`(${I18n.t("results.remark.old_mark")}: ${
            oldMark.mark
          })`}</div>
        )}
        <div
          className="criterion-description"
          dangerouslySetInnerHTML={{__html: safe_marked(description)}}
        />
      </div>
    </li>
  );
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
