import React, {useEffect, useRef, useState} from "react";
import Mousetrap from "mousetrap";
import PropTypes from "prop-types";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import safe_marked from "../../common/safe_marked";

export default function RubricCriterionInput({
  active,
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
  setActive,
  toggleExpanded,
  unassigned,
  updateMark,
}) {
  const [hoveredLevelIndex, setHoveredLevelIndex] = useState(null);

  // Refs so keybinding handlers always see current values without re-binding
  const hoveredRef = useRef(null);
  hoveredRef.current = hoveredLevelIndex;

  const handleChange = level => {
    updateMark(id, level.mark);
  };
  const handleChangeRef = useRef(handleChange);
  handleChangeRef.current = handleChange;

  // Set initial hover position when this criterion becomes active / inactive
  useEffect(() => {
    if (active) {
      const selectedIndex =
        mark !== null && mark !== undefined
          ? levels.findIndex(l => l.mark.toFixed(2) === mark.toFixed(2))
          : -1;
      setHoveredLevelIndex(selectedIndex >= 0 ? selectedIndex : 0);
    } else {
      setHoveredLevelIndex(null);
    }
    // Intentionally omit `mark` and `levels` — we only want to reset when
    // the active criterion changes, not on every mark update.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active]);

  // Bind up/down/enter for rubric-level navigation while this criterion is active
  useEffect(() => {
    if (active && !unassigned) {
      const isTextSelected = () =>
        "getSelection" in window && window.getSelection().type === "Range";

      Mousetrap.bind("up", e => {
        if (!isTextSelected()) {
          e.preventDefault?.();
          setHoveredLevelIndex(i => (i === 0 ? levels.length - 1 : i - 1));
          return false;
        }
      });
      Mousetrap.bind("down", e => {
        if (!isTextSelected()) {
          e.preventDefault?.();
          setHoveredLevelIndex(i => (i === levels.length - 1 ? 0 : i + 1));
          return false;
        }
      });
      Mousetrap.bind("enter", e => {
        e.preventDefault?.();
        const idx = hoveredRef.current;
        if (idx !== null && levels[idx]) {
          handleChangeRef.current(levels[idx]);
        }
      });

      return () => {
        Mousetrap.unbind(["up", "down", "enter"]);
      };
    }
  }, [active, unassigned]);

  useEffect(() => {
    if (active && !expanded) {
      toggleExpanded();
    }
  }, [active, expanded]);

  const renderRubricLevel = (level, index) => {
    const levelMark = level.mark.toFixed(2);
    let selectedClass = "";
    let oldMarkClass = "";
    let activeRubricClass = "";
    if (mark !== undefined && mark !== null && levelMark === mark.toFixed(2)) {
      selectedClass = "selected";
    }
    if (active && index === hoveredLevelIndex) {
      activeRubricClass = "active-rubric";
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
        className={`rubric-level ${selectedClass} ${activeRubricClass} ${oldMarkClass}`}
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

  const rubricLevels = levels.map((level, index) => renderRubricLevel(level, index));
  const expandedClass = expanded ? "expanded" : "collapsed";
  const unassignedClass = unassigned ? "unassigned" : "";

  return (
    <li
      id={`rubric_criterion_${id}`}
      className={`rubric_criterion ${expandedClass} ${unassignedClass} ${active ? "active-criterion" : ""}`}
      onClick={setActive}
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
