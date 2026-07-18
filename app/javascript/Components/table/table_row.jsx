import React from "react";
import TableCell from "./table_cell";
import {SELECTION_COLUMN_ID} from "./table";

function TableRow({row, isSelected, isExpanded, renderSubComponent}) {
  return (
    <div className="rt-tr-group" role="rowgroup">
      <div className="rt-tr -odd" role="row">
        {row.getVisibleCells().map(cell => {
          // Only pass isSelected to the selection column. This prevents other cells from re-rendering
          // if the row selection status changes.
          const cellSelection =
            cell.column.columnDef.id === SELECTION_COLUMN_ID ? isSelected : null;
          return (
            <TableCell
              cell={cell}
              isSelected={cellSelection}
              key={cell.id}
              width={cell.column.getSize()}
            />
          );
        })}
      </div>
      {isExpanded && <div>{renderSubComponent({row})}</div>}
    </div>
  );
}

export default React.memo(
  TableRow,
  (prev, next) =>
    // react-table creates new row objects when filter values change.
    // We compare row.original rather than row to determine whether to re-render.
    prev.row.original === next.row.original &&
    prev.isSelected === next.isSelected &&
    prev.isExpanded === next.isExpanded &&
    prev.columnSizing === next.columnSizing &&
    prev.columns === next.columns
);
