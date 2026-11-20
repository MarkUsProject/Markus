import React from "react";
import {flexRender} from "@tanstack/react-table";

const ARIA_SORT = {asc: "ascending", desc: "descending"};

function TableHeaderCell({header, size, isSorted, sortIndex, isResizing, allRowsSelected}) {
  const resizable = header.column.columnDef.enableResizing !== false;
  const sortable = header.column.getCanSort();
  const content = flexRender(header.column.columnDef.header, header.getContext());

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
      // ARIA expects aria-sort on one header at a time, so only the primary sort column gets it
      aria-sort={sortIndex === 0 ? ARIA_SORT[isSorted] : undefined}
      style={{
        width: size,
        maxWidth: header.column.columnDef.maxSize || "none",
      }}
    >
      {sortable ? (
        <button
          type="button"
          className="rt-resizable-header-content rt-sort-button"
          onClick={header.column.getToggleSortingHandler()}
        >
          {content}
        </button>
      ) : (
        <div className="rt-resizable-header-content">{content}</div>
      )}
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
