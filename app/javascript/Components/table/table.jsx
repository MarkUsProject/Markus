import React from "react";
import {Grid} from "react-loader-spinner";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {
  createColumnHelper,
  getCoreRowModel,
  getExpandedRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getGroupedRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import FilterCell from "./filter";
import TableHeaderCell from "./table_header_cell";
import TableRow from "./table_row";

export const defaultNoDataText = () => I18n.t("table.no_data");

const columnHelper = createColumnHelper();
export const expanderColumn = columnHelper.display({
  id: "expander",
  header: () => null,
  size: 30,
  maxSize: 30,
  cell: ({row}) => {
    const icon = row.getIsExpanded() ? "fa-chevron-up" : "fa-chevron-down";
    const title = row.getIsExpanded() ? I18n.t("table.hide_details") : I18n.t("table.show_details");
    return row.getCanExpand() ? (
      <div
        className={`rt-expandable ${row.getIsExpanded() ? "-open" : ""}`}
        onClick={row.getToggleExpandedHandler()}
        data-testid="expander-button"
      >
        <FontAwesomeIcon icon={icon} title={title} />
      </div>
    ) : null;
  },
});

export const selectionColumn = columnHelper.display({
  id: "select",
  header: ({table}) => {
    const checkboxRef = React.useRef(null);

    React.useEffect(() => {
      if (checkboxRef.current) {
        checkboxRef.current.indeterminate =
          table.getIsSomeRowsSelected() && !table.getIsAllRowsSelected();
      }
    }, [table.getIsSomeRowsSelected(), table.getIsAllRowsSelected()]);

    return (
      <input
        ref={checkboxRef}
        type="checkbox"
        checked={table.getIsAllRowsSelected()}
        onChange={table.getToggleAllRowsSelectedHandler()}
      />
    );
  },
  size: 30,
  maxSize: 30,
  enableResizing: false,
  enableSorting: false,
  cell: ({row}) => (
    <input
      type="checkbox"
      checked={row.getIsSelected()}
      disabled={!row.getCanSelect()}
      onChange={row.getToggleSelectedHandler()}
    />
  ),
});

export default function Table({
  columns,
  data,
  noDataText,
  initialState,
  loading,
  renderSubComponent,
  getRowCanExpand,
  getRowId,
  enableRowSelection,
  rowSelection: externalRowSelection,
  columnFilters: externalColumnFilters,
  onColumnFiltersChange: externalOnColumnFiltersChange,
  onRowSelectionChange,
}) {
  const [internalColumnFilters, setInternalColumnFilters] = React.useState([]);
  const [columnSizing, setColumnSizing] = React.useState({});
  const [columnVisibility, setColumnVisibility] = React.useState({
    inactive: false,
    ...initialState?.columnVisibility,
  });
  const [expanded, setExpanded] = React.useState({});
  const [internalRowSelection, setInternalRowSelection] = React.useState({});
  const [grouping, setGrouping] = React.useState(initialState?.grouping ?? []);

  const columnFilters = React.useMemo(
    () => (externalColumnFilters !== undefined ? externalColumnFilters : internalColumnFilters),
    [externalColumnFilters, internalColumnFilters]
  );

  const handleColumnFiltersChange = React.useMemo(
    () =>
      externalOnColumnFiltersChange !== undefined
        ? externalOnColumnFiltersChange
        : setInternalColumnFilters,
    [externalOnColumnFiltersChange]
  );

  const rowSelection = React.useMemo(
    () => (externalRowSelection !== undefined ? externalRowSelection : internalRowSelection),
    [externalRowSelection, internalRowSelection]
  );

  const handleRowSelectionChange = React.useMemo(
    () => (onRowSelectionChange !== undefined ? onRowSelectionChange : setInternalRowSelection),
    [onRowSelectionChange]
  );

  const finalColumns = React.useMemo(() => {
    let cols = [...columns];
    if (enableRowSelection) {
      cols = [selectionColumn, ...cols];
    }
    if (renderSubComponent) {
      cols = [expanderColumn, ...cols];
    }
    return cols;
  }, [columns, enableRowSelection, renderSubComponent]);

  const table = useReactTable({
    data,
    columns: finalColumns,
    state: {
      columnFilters,
      columnSizing,
      columnVisibility,
      expanded,
      rowSelection,
      grouping,
    },
    initialState: initialState,
    onColumnFiltersChange: handleColumnFiltersChange,
    onColumnSizingChange: setColumnSizing,
    onColumnVisibilityChange: setColumnVisibility,
    onExpandedChange: setExpanded,
    onGroupingChange: setGrouping,
    onRowSelectionChange: handleRowSelectionChange,
    getCoreRowModel: getCoreRowModel(),
    getExpandedRowModel: getExpandedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getGroupedRowModel: getGroupedRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
    getFacetedRowModel: getFacetedRowModel(),
    getRowCanExpand,
    getRowId,
    enableSortingRemoval: false,
    enableColumnResizing: true,
    enableRowSelection: enableRowSelection,
    columnResizeMode: "onChange",
  });

  const centerTotalSize = table.getCenterTotalSize();

  const tableHeaders = (
    <div className="rt-thead -header" style={{minWidth: centerTotalSize}}>
      {table.getHeaderGroups().map(headerGroup => (
        <div className="rt-tr" role="row" key={headerGroup.id}>
          {headerGroup.headers.map(header => (
            <TableHeaderCell
              key={header.id}
              header={header}
              size={header.getSize()}
              isSorted={header.column.getIsSorted()}
              isResizing={header.column.getIsResizing()}
            />
          ))}
        </div>
      ))}
    </div>
  );

  const showFilters = React.useMemo(
    () => table.getAllColumns().some(column => column.getCanFilter()),
    [table, finalColumns]
  );
  const tableFilters = showFilters && (
    <div className="rt-thead -filters" style={{minWidth: centerTotalSize}}>
      {table.getHeaderGroups().map(headerGroup => (
        <div className="rt-tr" role="row" key={headerGroup.id}>
          {headerGroup.headers.map(header => (
            <FilterCell
              key={header.id}
              size={header.getSize()}
              column={header.column}
              filterValue={header.column.getFilterValue()}
              facetedUniqueValues={
                header.column.columnDef.meta?.filterVariant === "select"
                  ? header.column.getFacetedUniqueValues()
                  : null
              }
            />
          ))}
        </div>
      ))}
    </div>
  );

  return (
    <div className="Table -highlight" style={{maxHeight: "500px"}}>
      <div className="rt-table" role="grid">
        {tableHeaders}
        {tableFilters}
        <div className="rt-tbody" style={{minWidth: centerTotalSize}}>
          {table.getRowModel().rows.map(row => (
            <TableRow
              row={row}
              isExpanded={row.getIsExpanded()}
              isSelected={row.getIsSelected()}
              key={row.id}
              renderSubComponent={renderSubComponent}
              // columnSizing is not used directly in TableRow, but is passed to trigger
              // re-render when column sizes change
              columnSizing={columnSizing}
              columns={finalColumns}
            />
          ))}
          {loading && table.getRowModel().rows.length > 0 && (
            <div
              className="loading-spinner"
              style={{
                position: "absolute",
                bottom: 0,
                left: 0,
                right: 0,
                height: "auto",
                backgroundColor: "#fff",
                zIndex: 10,
                border: "solid 1px rgba(0, 0, 0, 0.05)",
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
          )}
          {!table.getRowModel().rows.length &&
            (loading ? (
              <div className="loading-spinner">
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
