import React from "react";
import {flexRender} from "@tanstack/react-table";

function TableCell({cell, width}) {
  const metaClass = cell.column.columnDef.meta?.className || "";
  return (
    <div
      className={`rt-td ${metaClass}`}
      role="gridcell"
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
