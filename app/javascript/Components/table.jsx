import React from "react";

import {
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";

export default function Table({columns, data, noDataText}) {
  const [columnFilters, setColumnFilters] = React.useState([]);
  const [columnSizing, setColumnSizing] = React.useState({});

  const table = useReactTable({
    data,
    columns,
    filterFns: {},
    state: {
      columnFilters,
      columnSizing,
    },
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
    getFacetedRowModel: getFacetedRowModel(),
    debugColumns: false,
    enableSortingRemoval: false,
    enableColumnResizing: true,
    columnResizeMode: "onChange",
    onColumnSizingChange: setColumnSizing,
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
                  }[header.column.getIsSorted()];
                return (
                  <div
                    className={class_name}
                    role="columnheader"
                    tabIndex="-1"
                    key={header.id}
                    style={{flex: "100 0 auto", width: header.getSize()}}
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
                    className="rt-th"
                    key={header.id}
                    role="columnheader"
                    tabIndex="-1"
                    style={{flex: "100 0 auto", width: header.getSize()}}
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
              <div className="rt-tr-group" role="rowgroup">
                <div className="rt-tr -odd" role="row" key={row.id}>
                  {row.getVisibleCells().map(cell => {
                    return (
                      <div
                        className="rt-td"
                        role="gridcell"
                        style={{flex: "100 0 auto", width: cell.column.getSize()}}
                        key={cell.id}
                      >
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
          {!table.getRowModel().rows.length && (
            <p className="rt-no-data">{noDataText || "No rows found"}</p>
          )}
        </div>
      </div>
    </div>
  );
}

function Filter({column}) {
  const {filterVariant} = column.columnDef.meta ?? {};

  return filterVariant === "select" ? (
    <SelectFilter column={column} />
  ) : (
    <SearchFilter column={column} />
  );
}

function SearchFilter({column}) {
  return (
    <input
      placeholder={`Search`}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={column.getFilterValue()?.toString()}
      style={{width: "100%"}}
      aria-label="Search"
    />
  );
}

function SelectFilter({column}) {
  const uniqueValuesMap = column.getFacetedUniqueValues();

  const sortedUniqueValues = React.useMemo(() => {
    return Array.from(uniqueValuesMap.keys()).sort();
  }, [uniqueValuesMap]);

  const totalRowCount = React.useMemo(() => {
    return [...uniqueValuesMap.values()].reduce((sum, count) => sum + count, 0);
  }, [uniqueValuesMap]);

  return (
    <select
      onChange={e => column.setFilterValue(e.target.value)}
      value={column.getFilterValue()?.toString()}
      style={{width: "100%"}}
    >
      <option value="">All ({totalRowCount})</option>
      {sortedUniqueValues.map(value => (
        <option value={value} key={value}>
          {value} ({uniqueValuesMap.get(value).toString()})
        </option>
      ))}
    </select>
  );
}
