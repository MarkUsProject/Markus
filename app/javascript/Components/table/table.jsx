import React from "react";
import {Grid, TailSpin, LineWave, Oval} from "react-loader-spinner";

import {
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import Filter from "./filter";

export const defaultNoDataText = () => I18n.t("table.no_data");

export default function Table({columns, data, noDataText, initialState}) {
  const [columnFilters, setColumnFilters] = React.useState([]);
  const [columnSizing, setColumnSizing] = React.useState({});

  const table = useReactTable({
    data,
    columns,
    state: {
      columnFilters,
      columnSizing,
    },
    initialState: initialState,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
    getFacetedRowModel: getFacetedRowModel(),
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
                    false: "",
                  }[header.column.getIsSorted()];
                return (
                  <div
                    className={class_name}
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
                    className="rt-th"
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
          {!table.getRowModel().rows.length &&
            (noDataText === "Loading" ? (
              <div
                className="flex gap-4"
                style={{
                  display: "flex",
                  justifyContent: "center",
                  alignItems: "center",
                  height: "50px",
                }}
              >
                {/*<Grid*/}
                {/*  visible={true}*/}
                {/*  height="25"*/}
                {/*  width="25"*/}
                {/*  color="#31649B"*/}
                {/*  ariaLabel="grid-loading"*/}
                {/*  radius="12.5"*/}
                {/*  wrapperStyle={{}}*/}
                {/*  wrapperClass="grid-wrapper"*/}
                {/*/>*/}
                {/*<LineWave*/}
                {/*  visible={true}*/}
                {/*  height="50"*/}
                {/*  width="70"*/}
                {/*  color="#31649B"*/}
                {/*  ariaLabel="line-wave-loading"*/}
                {/*  wrapperStyle={{}}*/}
                {/*  wrapperClass=""*/}
                {/*  firstLineColor=""*/}
                {/*  middleLineColor=""*/}
                {/*  lastLineColor=""*/}
                {/*/>*/}
                {/*<Oval*/}
                {/*  visible={true}*/}
                {/*  height="25"*/}
                {/*  width="25"*/}
                {/*  color="#31649B"*/}
                {/*  ariaLabel="oval-loading"*/}
                {/*  wrapperStyle={{}}*/}
                {/*  wrapperClass=""*/}
                {/*/>*/}
                <TailSpin
                  visible={true}
                  height="25"
                  width="25"
                  color="#31649B"
                  ariaLabel="tail-spin-loading"
                  radius="1"
                  wrapperStyle={{}}
                  wrapperClass=""
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
