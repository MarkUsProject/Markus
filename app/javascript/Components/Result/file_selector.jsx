import React, {useState} from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export const FileSelector = React.memo(function FileSelector({
  fileData,
  onSelectFile,
  selectedFile,
}) {
  const [expanded, setExpanded] = useState(null);

  const selectFile = (e, fullPath, id, type) => {
    e.stopPropagation();
    onSelectFile(fullPath, id, type);
    setExpanded(null);
  };

  const selectDirectory = (e, path) => {
    e.stopPropagation();
    setExpanded(path);
  };

  const hashToHTMLList = (hash, exp) => {
    let dirs = [];
    let newExpanded, displayStyle;
    if (exp === null) {
      newExpanded = null;
      displayStyle = "none";
    } else if (hash["name"] === "") {
      newExpanded = exp;
      displayStyle = "block";
    } else {
      newExpanded = exp.slice(1);
      displayStyle = hash["name"] === exp[0] ? "block" : "none";
    }

    for (let d in hash["directories"]) {
      if (hash["directories"].hasOwnProperty(d)) {
        let dir = hash["directories"][d];
        dirs.push(
          <li
            className="nested-submenu"
            key={dir.path.join("/")}
            onClick={e => selectDirectory(e, dir.path)}
          >
            <a key={`${dir.path.join("/")}-a`}>{dir.name}</a>
            {hashToHTMLList(dir, newExpanded)}
          </li>
        );
      }
    }

    return (
      <ul className="nested-folder" style={{display: displayStyle}}>
        {dirs}
        {hash["files"].map(f => {
          const [name, id, type] = f;
          const fullPath = hash.path.concat([name]).join("/");
          return (
            <li
              className="file_item"
              key={fullPath}
              onClick={e => selectFile(e, fullPath, id, type)}
            >
              <a key={`${fullPath}-a`}>{f[0]}</a>
            </li>
          );
        })}
      </ul>
    );
  };

  const fileSelector = hashToHTMLList(fileData, expanded);

  let arrow, expandTarget;
  if (expanded !== null) {
    arrow = <FontAwesomeIcon className="arrow-up" icon="fa-chevron-up" />;
    expandTarget = null;
  } else {
    arrow = <FontAwesomeIcon className="arrow-down" icon="fa-chevron-down" />;
    expandTarget = [];
  }

  let selectorLabel;
  if (!fileData.files.length && !Object.keys(fileData.directories).length) {
    selectorLabel = I18n.t("submissions.no_files_available");
  } else if (selectedFile !== null) {
    selectorLabel = selectedFile[0];
  } else {
    selectorLabel = "";
  }

  return (
    <div
      className="dropdown"
      onClick={e => {
        e.stopPropagation();
        setExpanded(expandTarget);
      }}
      onBlur={() => setExpanded(null)}
      tabIndex={-1}
    >
      <a>{selectorLabel}</a>
      {arrow}
      {expanded && <div>{fileSelector}</div>}
    </div>
  );
});
