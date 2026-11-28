import React from "react";
import {flexRender} from "@tanstack/react-table";
import {getCellId} from "./table";

function TableCell({cell, width}) {
  const metaClass = cell.column.columnDef.meta?.className || "";
  const isRowHeader = cell.column.columnDef.meta?.rowheader;
  return (
    <div
      // Row selection checkboxes refer to their row's header cells by id
      id={isRowHeader ? getCellId(cell) : undefined}
      className={`rt-td ${metaClass}`}
      role={isRowHeader ? "rowheader" : "gridcell"}
      style={{
        flex: "100 0 auto",
        width: width,
        maxWidth: cell.column.columnDef.maxSize || "none",
      }}
    >
      {flexRender(cell.column.columnDef.cell, cell.getContext())}
    </div>
  );
}

export default React.memo(TableCell);
