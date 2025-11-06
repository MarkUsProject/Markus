import React from "react";
import PropTypes from "prop-types";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import safe_marked from "../../common/safe_marked";

export default function RubricCriterionInput({
  bonus,
  destroyMark,
  expanded,
  id,
  levels,
  mark,
  max_mark,
  name,
  oldMark,
  released_to_students,
  toggleExpanded,
  unassigned,
  updateMark,
}) {
  // The parameter `level` is the level object selected
  const handleChange = level => {
    updateMark(id, level.mark);
  };

  // The parameter `level` is the level object selected
  const renderRubricLevel = level => {
    const levelMark = level.mark.toFixed(2);
    let selectedClass = "";
    let oldMarkClass = "";
    if (mark !== undefined && mark !== null && levelMark === mark.toFixed(2)) {
      selectedClass = "selected";
    }
    if (
      oldMark !== undefined &&
      oldMark.mark !== undefined &&
      levelMark === oldMark.mark.toFixed(2)
    ) {
      oldMarkClass = "old-mark";
    }

    return (
      <tr
        onClick={() => handleChange(level)}
        key={`${id}-${levelMark}`}
        className={`rubric-level ${selectedClass} ${oldMarkClass}`}
      >
        <td className="level-description">
          <strong>{level.name}</strong>
          <span dangerouslySetInnerHTML={{__html: safe_marked(level.description)}} />
        </td>
        <td className={"mark"}>
          {levelMark}
          &nbsp;/&nbsp;
          {max_mark}
        </td>
      </tr>
    );
  };

  const rubricLevels = levels.map(renderRubricLevel);
  const expandedClass = expanded ? "expanded" : "collapsed";
  const unassignedClass = unassigned ? "unassigned" : "";

  return (
    <li
      id={`rubric_criterion_${id}`}
      className={`rubric_criterion ${expandedClass} ${unassignedClass}`}
    >
      <div data-testid={id}>
        <div className="criterion-name" onClick={toggleExpanded}>
          <FontAwesomeIcon
            className="chevron-expandable"
            icon={expanded ? "fa-chevron-up" : "fa-chevron-down"}
          />
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
        <table className="rubric-levels">
          <tbody>{rubricLevels}</tbody>
        </table>
      </div>
    </li>
  );
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
