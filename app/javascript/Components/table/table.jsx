import React from "react";
import {Grid} from "react-loader-spinner";

import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  getExpandedRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import Filter from "./filter";

export const defaultNoDataText = () => I18n.t("table.no_data");

const columnHelper = createColumnHelper();
export const expanderColumn = columnHelper.display({
  id: "expander",
  header: () => null,
  size: 32,
  cell: ({row}) => {
    return row.getCanExpand() ? (
      <div
        className={`rt-expander ${row.getIsExpanded() ? "-open" : ""}`}
        onClick={row.getToggleExpandedHandler()}
        data-testid="expander-button"
      ></div>
    ) : null;
  },
});

export default function Table({
  columns,
  data,
  noDataText,
  initialState,
  renderSubComponent,
  getRowCanExpand,
  columnFilters: externalColumnFilters,
}) {
  const [columnFilters, setColumnFilters] = React.useState([]);
  const [columnSizing, setColumnSizing] = React.useState({});
  const [columnVisibility, setColumnVisibility] = React.useState({inactive: false});
  const [expanded, setExpanded] = React.useState({});

  React.useEffect(() => {
    if (externalColumnFilters !== undefined) {
      setColumnFilters(externalColumnFilters);
    }
  }, [externalColumnFilters]);

  const finalColumns = renderSubComponent ? [expanderColumn, ...columns] : columns;

  const table = useReactTable({
    data,
    columns: finalColumns,
    state: {
      columnFilters,
      columnSizing,
      columnVisibility,
      expanded,
    },
    initialState: initialState,
    onColumnFiltersChange: setColumnFilters,
    onColumnSizingChange: setColumnSizing,
    onColumnVisibilityChange: setColumnVisibility,
    onExpandedChange: setExpanded,
    getCoreRowModel: getCoreRowModel(),
    getExpandedRowModel: getExpandedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
    getFacetedRowModel: getFacetedRowModel(),
    getRowCanExpand,
    enableSortingRemoval: false,
    enableColumnResizing: true,
    columnResizeMode: "onChange",
  });

  return (
    <div className="Table -highlight" style={{maxHeight: "500px"}}>
      <div className="rt-table" role="grid">
        <div className="rt-thead -header" style={{minWidth: table.getCenterTotalSize()}}>
          {table.getHeaderGroups().map(headerGroup => (
            <div className="rt-tr" role="row" key={headerGroup.id}>
              {headerGroup.headers.map(header => {
                let class_name =
                  "rt-th rt-resizable-header --cursor-pointer" +
                  {
                    asc: " rt-resizable-header-content -sort-asc",
                    desc: " rt-resizable-header-content -sort-desc",
                    false: "",
                  }[header.column.getIsSorted()];
                return (
                  <div
                    className={`${class_name} ${header.column.columnDef.meta?.headerClassName || ""}`}
                    role="columnheader"
                    tabIndex="-1"
                    key={header.id}
                    style={{width: header.getSize()}}
                  >
                    <div
                      className="rt-resizable-header-content"
                      {...{
                        onClick: header.column.getToggleSortingHandler(),
                      }}
                    >
                      {flexRender(header.column.columnDef.header, header.getContext())}
                    </div>
                    <div
                      {...{
                        onMouseDown: header.getResizeHandler(),
                        onTouchStart: header.getResizeHandler(),
                      }}
                      className={`rt-resizer resizer ${
                        header.column.getIsResizing() ? "isResizing" : ""
                      }`}
                    />
                  </div>
                );
              })}
            </div>
          ))}
        </div>
        <div className="rt-thead -filters" style={{minWidth: table.getCenterTotalSize()}}>
          {table.getHeaderGroups().map(headerGroup => (
            <div className="rt-tr" role="row" key={headerGroup.id}>
              {headerGroup.headers.map(header => {
                return (
                  <div
                    className={`rt-th ${header.column.columnDef.meta?.headerClassName || ""}`}
                    key={header.id}
                    role="columnheader"
                    tabIndex="-1"
                    style={{width: header.getSize()}}
                  >
                    {header.column.getCanFilter() ? <Filter column={header.column} /> : null}
                  </div>
                );
              })}
            </div>
          ))}
        </div>
        <div className="rt-tbody" style={{minWidth: table.getCenterTotalSize()}}>
          {table.getRowModel().rows.map(row => {
            return (
              <div className="rt-tr-group" role="rowgroup" key={row.id}>
                <div className="rt-tr -odd" role="row" key={row.id}>
                  {row.getVisibleCells().map(cell => {
                    const metaClass = cell.column.columnDef.meta?.className || "";
                    return (
                      <div
                        className={`rt-td ${metaClass}`}
                        role="gridcell"
                        style={{flex: "100 0 auto", width: cell.column.getSize()}}
                        key={cell.id}
                      >
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </div>
                    );
                  })}
                </div>
                {row.getIsExpanded() && <div>{renderSubComponent({row})}</div>}
              </div>
            );
          })}
          {!table.getRowModel().rows.length &&
            (noDataText === "" ? (
              <div
                className="flex gap-4"
                style={{
                  display: "flex",
                  justifyContent: "center",
                  alignItems: "center",
                  height: "50px",
                }}
              >
                <Grid
                  visible={true}
                  height="25"
                  width="25"
                  color="#31649B"
                  ariaLabel="grid-loading"
                  radius="12.5"
                  wrapperStyle={{}}
                  wrapperClass="grid-wrapper"
                />
              </div>
            ) : (
              <p className="rt-no-data">{noDataText || defaultNoDataText()}</p>
            ))}
        </div>
      </div>
    </div>
  );
}
