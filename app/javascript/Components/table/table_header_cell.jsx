import React from "react";
import {flexRender} from "@tanstack/react-table";

function TableHeaderCell({header, size, isSorted, isResizing}) {
  const resizable = header.column.columnDef.enableResizing !== false;
  const sortable = header.column.columnDef.enableSorting !== false;

  let class_name = "rt-th";
  if (resizable) {
    class_name += " rt-resizable-header rt-resizable-header-content";
  }
  if (sortable) {
    class_name += " -cursor-pointer";
    class_name += {asc: " -sort-asc", desc: " -sort-desc", false: ""}[isSorted];
  }

  return (
    <div
      className={`${class_name} ${header.column.columnDef.meta?.headerClassName || ""}`}
      role="columnheader"
      tabIndex="-1"
      style={{
        width: size,
        maxWidth: header.column.columnDef.maxSize || "none",
      }}
    >
      <div
        className="rt-resizable-header-content"
        onClick={header.column.getToggleSortingHandler()}
      >
        {flexRender(header.column.columnDef.header, header.getContext())}
      </div>
      {resizable && (
        <div
          onMouseDown={header.getResizeHandler()}
          onTouchStart={header.getResizeHandler()}
          className={`rt-resizer resizer ${isResizing ? "isResizing" : ""}`}
        />
      )}
    </div>
  );
}

export default React.memo(TableHeaderCell);
