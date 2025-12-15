import React, {useState, useEffect, useRef} from "react";
import PropTypes from "prop-types";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import safe_marked from "../../common/safe_marked";

export default function FlexibleCriterionInput({
  active,
  annotations,
  bonus,
  description,
  destroyMark,
  expanded,
  findDeductiveAnnotation,
  id,
  mark,
  max_mark,
  name,
  oldMark,
  override,
  released_to_students,
  revertToAutomaticDeductions,
  setActive,
  toggleExpanded,
  unassigned,
  updateMark,
}) {
  const [rawText, setRawText] = useState(mark === null ? "" : String(mark));
  const [invalid, setInvalid] = useState(false);
  const typing_timer = useRef(undefined);
  const inputRef = useRef(null);

  const listDeductions = () => {
    let label = I18n.t("annotations.list_deductions");
    let deductiveAnnotations = annotations.filter(a => {
      return !!a.deduction && a.criterion_id === id && !a.is_remark;
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
              findDeductiveAnnotation(full_path, a.submission_file_id, a.line_start, a.id)
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

    if (override) {
      label = "(" + I18n.t("results.overridden_deductions") + ") " + label;
    }

    return (
      <div className={"mark-deductions"}>
        {label}
        {hyperlinkedDeductions}
      </div>
    );
  };

  const deleteManualMarkLink = () => {
    if (!released_to_students && !unassigned) {
      if (annotations.some(a => !!a.deduction && a.criterion_id === id) && override) {
        return (
          <a
            href="#"
            className="flexible-revert"
            onClick={_ => revertToAutomaticDeductions(id)}
            style={{float: "right"}}
          >
            {I18n.t("results.cancel_override")}
          </a>
        );
      } else if (mark !== null && override) {
        return (
          <a href="#" onClick={e => destroyMark(e, id)} style={{float: "right"}}>
            {I18n.t("helpers.submit.delete", {
              model: I18n.t("activerecord.models.mark.one"),
            })}
          </a>
        );
      }
    }
    return "";
  };

  const renderOldMark = () => {
    if (oldMark === undefined || oldMark.mark === undefined) {
      return null;
    }
    let label = String(oldMark.mark);

    if (oldMark.override) {
      label = `(${I18n.t("results.overridden_deductions")}) ${label}`;
    }

    return <div className="old-mark">{`(${I18n.t("results.remark.old_mark")}: ${label})`}</div>;
  };

  const handleChange = event => {
    if (typing_timer.current) {
      clearTimeout(typing_timer.current);
    }

    const inputMark = parseFloat(event.target.value);
    if (event.target.value !== "" && isNaN(inputMark)) {
      setRawText(event.target.value);
      setInvalid(true);
    } else if (inputMark === mark) {
      // This can happen if the user types a decimal point at the end of the input.
      setRawText(event.target.value);
      setInvalid(false);
    } else if (inputMark > max_mark) {
      setRawText(event.target.value);
      setInvalid(true);
    } else {
      setRawText(event.target.value);
      setInvalid(false);

      typing_timer.current = setTimeout(() => {
        updateMark(id, isNaN(inputMark) ? null : inputMark);
      }, 300);
    }
  };

  useEffect(() => {
    setRawText(mark === null ? "" : String(mark));
    setInvalid(false);
  }, [mark]);

  const unassignedClass = unassigned ? "unassigned" : "";
  const expandedClass = expanded ? "expanded" : "collapsed";

  // Auto-expand if not already when active
  useEffect(() => {
    if (active && !expanded) {
      toggleExpanded();
    }
  }, [active, expanded]);

  useEffect(() => {
    if (active && inputRef.current && expanded) {
      // Focus at end of input
      inputRef.current.focus();
      inputRef.current.setSelectionRange(
        inputRef.current.value.length,
        inputRef.current.value.length
      );
    }
  }, [active, expanded]);

  let markElement;
  if (released_to_students) {
    // Student view
    markElement = mark;
  } else {
    markElement = (
      <input
        ref={inputRef}
        className={invalid ? "invalid" : ""}
        type="text"
        size={4}
        value={rawText}
        onChange={handleChange}
        disabled={unassigned}
      />
    );
  }

  return (
    <li
      id={`flexible_criterion_${id}`}
      className={`flexible_criterion ${expandedClass} ${unassignedClass} ${active ? "active-criterion" : ""}`}
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
          {deleteManualMarkLink()}
        </div>
        <div
          className="criterion-description"
          dangerouslySetInnerHTML={{__html: safe_marked(description)}}
        />
        <span className="mark">
          {markElement}
          &nbsp;/&nbsp;
          {max_mark}
        </span>
        {listDeductions()}
        {renderOldMark()}
      </div>
    </li>
  );
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
