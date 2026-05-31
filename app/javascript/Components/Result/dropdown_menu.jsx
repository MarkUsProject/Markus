import React, {useState} from "react";

import safe_marked from "../../common/safe_marked";

export const DropDownMenu = React.memo(function DropDownMenu({header, items, onItemClick}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <li
      className="dropdown_menu"
      onMouseEnter={() => setExpanded(true)}
      onMouseLeave={() => setExpanded(false)}
      onMouseDown={e => e.preventDefault()}
    >
      <div className="dropdown-header">{header}</div>

      {expanded && (
        <ul>
          {items.map(item => (
            <li
              key={item.id}
              onClick={e => {
                e.preventDefault();
                onItemClick(item.id);
              }}
            >
              <span
                className={"text-content"}
                dangerouslySetInnerHTML={{__html: safe_marked(item.content).slice(0, 70)}}
              />
              <span className={"red-text"}>{!item.deduction ? "" : "-" + item.deduction}</span>
            </li>
          ))}
        </ul>
      )}
    </li>
  );
});
