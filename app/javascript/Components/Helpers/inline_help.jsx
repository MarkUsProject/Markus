import React, {useState} from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {faCircleQuestion} from "@fortawesome/free-regular-svg-icons";

/**
 * A help icon that toggles the display of its help text when clicked.
 *
 * This is the React equivalent of the `.inline-help` markup used in ERB views. Those elements are
 * set up by `common/help-system.js` when the page loads, which runs before React components render.
 */
export default function InlineHelp({children}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="inline-help" onClick={() => setIsOpen(open => !open)}>
      <FontAwesomeIcon icon={faCircleQuestion} />
      <p style={{display: isOpen ? "block" : "none"}}>{children}</p>
    </div>
  );
}
