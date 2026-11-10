import React from "react";
import TableCell from "./table_cell";
import {SELECTION_COLUMN_ID} from "./table";

function TableRow({
  row,
  index,
  ariaRowIndex,
  measureRow,
  isSelected,
  isGrouped,
  isExpanded,
  renderSubComponent,
}) {
  return (
    <div className="rt-tr-group" role="rowgroup" ref={measureRow} data-index={index}>
      <div
        className="rt-tr -odd"
        role="row"
        aria-rowindex={ariaRowIndex}
        data-row-number={index + 1}
      >
        {row.getVisibleCells().map(cell => {
          // Only pass isSelected to the selection column. This prevents other cells from re-rendering
          // if the row selection status changes.
          const cellSelection =
            cell.column.columnDef.id === SELECTION_COLUMN_ID ? isSelected : null;
          return (
            <TableCell
              cell={cell}
              isSelected={cellSelection}
              isExpanded={isExpanded}
              key={cell.id}
              width={cell.column.getSize()}
            />
          );
        })}
      </div>
      {isExpanded && !isGrouped && <div>{renderSubComponent({row})}</div>}
    </div>
  );
}

export default React.memo(
  TableRow,
  (prev, next) =>
    // react-table creates new row objects when filter values change.
    // We compare row.original rather than row to determine whether to re-render.
    prev.row.original === next.row.original &&
    prev.index === next.index &&
    prev.ariaRowIndex === next.ariaRowIndex &&
    prev.measureRow === next.measureRow &&
    prev.isGrouped === next.isGrouped &&
    prev.isSelected === next.isSelected &&
    prev.isExpanded === next.isExpanded &&
    prev.columnSizing === next.columnSizing &&
    prev.columns === next.columns
);
