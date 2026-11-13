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
import {useVirtualizer} from "@tanstack/react-virtual";
import FilterCell from "./filter";
import TableHeaderCell from "./table_header_cell";
import TableRow from "./table_row";

export const defaultNoDataText = () => I18n.t("table.no_data");

const columnHelper = createColumnHelper();
export const SELECTION_COLUMN_ID = "select";
const FILTER_VARIANT_SELECT = "select";
const VIRTUALIZATION_THRESHOLD = 50;
const STATUS_MESSAGE_DELAY = 500;

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
  id: SELECTION_COLUMN_ID,
  header: ({table}) => {
    const checkboxRef = React.useRef(null);

    React.useEffect(() => {
      if (checkboxRef.current) {
        checkboxRef.current.indeterminate =
          table.getIsSomeRowsSelected() && !table.getIsAllRowsSelected();
      }
    }, [table.getIsSomeRowsSelected(), table.getIsAllRowsSelected()]);

    return (
      <div style={{textAlign: "center"}}>
        <input
          ref={checkboxRef}
          type="checkbox"
          checked={table.getIsAllRowsSelected()}
          onChange={table.getToggleAllRowsSelectedHandler()}
        />
      </div>
    );
  },
  size: 30,
  maxSize: 30,
  enableResizing: false,
  enableSorting: false,
  cell: ({row}) => (
    <div style={{textAlign: "center"}}>
      <input
        type="checkbox"
        checked={row.getIsSelected()}
        disabled={!row.getCanSelect()}
        onChange={row.getToggleSelectedHandler()}
      />
    </div>
  ),
});

export default function Table({
  columns,
  data,
  noDataText,
  initialState,
  loading,
  renderSubComponent,
  renderSubRows,
  getRowCanExpand,
  getRowId,
  enableRowSelection,
  rowSelection: externalRowSelection,
  columnFilters: externalColumnFilters,
  onColumnFiltersChange: externalOnColumnFiltersChange,
  onRowSelectionChange,
  showRowNumbers = false,
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
    if (renderSubComponent || renderSubRows) {
      cols = [expanderColumn, ...cols];
    }
    return cols;
  }, [columns, enableRowSelection, renderSubComponent, renderSubRows]);

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
    groupedColumnMode: false,
    enableSortingRemoval: false,
    enableColumnResizing: true,
    enableRowSelection: enableRowSelection,
    columnResizeMode: "onChange",
  });

  const centerTotalSize = table.getCenterTotalSize();
  const tableMinWidth = showRowNumbers
    ? `calc(${centerTotalSize}px + var(--row-number-gutter-width))`
    : centerTotalSize;
  const rows = table.getRowModel().rows;
  const bodyRef = React.useRef(null);
  const virtualizeRows = rows.length > VIRTUALIZATION_THRESHOLD;
  const rowVirtualizer = useVirtualizer({
    enabled: virtualizeRows,
    count: rows.length,
    getScrollElement: () => bodyRef.current,
    getItemKey: React.useCallback(index => rows[index].id, [rows]),
    estimateSize: () => 34,
    overscan: 5,
  });
  const virtualRows = rowVirtualizer.getVirtualItems();
  const topSpacerHeight = virtualRows[0]?.start ?? 0;
  const bottomSpacerHeight = virtualizeRows
    ? rowVirtualizer.getTotalSize() - (virtualRows.at(-1)?.end ?? 0)
    : 0;

  const showFilters = React.useMemo(
    () => table.getAllColumns().some(column => column.getCanFilter()),
    [table, finalColumns]
  );
  const headerGroups = table.getHeaderGroups();
  const headerRowCount = headerGroups.length * (showFilters ? 2 : 1);

  // Counts the rows shown before any are expanded, so a grouped table counts its groups
  const rowCount = table.getPreExpandedRowModel().rows.length;
  const [statusMessage, setStatusMessage] = React.useState("");
  const hasLoaded = React.useRef(false);

  // Tells screen readers when the table is loading and how many rows it shows after a change.
  // The first load is not announced, so that pages with several tables stay quiet when they open.
  React.useEffect(() => {
    if (!hasLoaded.current) {
      hasLoaded.current = !loading;
      return;
    }
    if (loading) {
      setStatusMessage(I18n.t("working"));
      return;
    }
    // Cleared first, so that the same count is announced again after a filter change
    setStatusMessage("");
    const timeout = setTimeout(
      () => setStatusMessage(I18n.t("table.row_count", {count: rowCount})),
      STATUS_MESSAGE_DELAY
    );
    return () => clearTimeout(timeout);
  }, [loading, rowCount, columnFilters]);

  const renderRow = (row, index) => (
    <TableRow
      row={row}
      index={index}
      ariaRowIndex={headerRowCount + index + 1}
      measureRow={virtualizeRows ? rowVirtualizer.measureElement : undefined}
      isExpanded={row.getIsExpanded()}
      isGrouped={row.getIsGrouped()}
      isSelected={row.getIsSelected()}
      key={row.id}
      renderSubComponent={renderSubComponent}
      // columnSizing is not used directly in TableRow, but is passed to trigger
      // re-render when column sizes change
      columnSizing={columnSizing}
      columns={finalColumns}
    />
  );

  const tableHeaders = (
    <div className="rt-thead -header" style={{minWidth: tableMinWidth}}>
      {headerGroups.map((headerGroup, index) => (
        <div className="rt-tr" role="row" aria-rowindex={index + 1} key={headerGroup.id}>
          {headerGroup.headers.map(header => (
            <TableHeaderCell
              key={header.id}
              header={header}
              size={header.getSize()}
              isSorted={header.column.getIsSorted()}
              isResizing={header.column.getIsResizing()}
              allRowsSelected={
                header.column.id === SELECTION_COLUMN_ID ? table.getIsAllRowsSelected() : undefined
              }
            />
          ))}
        </div>
      ))}
    </div>
  );

  const tableFilters = showFilters && (
    <div className="rt-thead -filters" style={{minWidth: tableMinWidth}}>
      {headerGroups.map((headerGroup, index) => (
        <div
          className="rt-tr"
          role="row"
          aria-rowindex={headerGroups.length + index + 1}
          key={headerGroup.id}
        >
          {headerGroup.headers.map(header => (
            <FilterCell
              key={header.id}
              size={header.getSize()}
              column={header.column}
              filterValue={header.column.getFilterValue()}
              facetedUniqueValues={
                header.column.columnDef.meta?.filterVariant === FILTER_VARIANT_SELECT
                  ? header.column.getFacetedUniqueValues()
                  : null
              }
            />
          ))}
        </div>
      ))}
    </div>
  );

  const loadingSpinner = (
    <Grid
      visible={true}
      height="25"
      width="25"
      color="#31649B"
      ariaLabel={I18n.t("working")}
      radius="12.5"
      wrapperStyle={{}}
      wrapperClass="grid-wrapper"
    />
  );

  return (
    <div
      className={`Table -highlight${showRowNumbers ? " -show-row-numbers" : ""}`}
      style={{maxHeight: "500px"}}
    >
      <div
        className="rt-table"
        role="grid"
        // An empty table has one row, which holds the no data message or the loading spinner
        aria-rowcount={headerRowCount + (rows.length || 1)}
        // Only rows that are being reloaded are marked busy, so that the spinner in an empty
        // table is not hidden from screen readers that skip busy content
        aria-busy={(loading && rows.length > 0) || undefined}
      >
        {tableHeaders}
        {tableFilters}
        <div
          className="rt-tbody"
          style={{minWidth: tableMinWidth, overflowAnchor: virtualizeRows ? "none" : undefined}}
          ref={bodyRef}
        >
          {topSpacerHeight > 0 && (
            <div aria-hidden="true" style={{flex: `0 0 ${topSpacerHeight}px`}} />
          )}
          {virtualizeRows
            ? virtualRows.map(({index}) => renderRow(rows[index], index))
            : rows.map(renderRow)}
          {bottomSpacerHeight > 0 && (
            <div aria-hidden="true" style={{flex: `0 0 ${bottomSpacerHeight}px`}} />
          )}
          {!rows.length && (
            <div role="row" aria-rowindex={headerRowCount + 1}>
              <div role="gridcell" aria-colspan={table.getVisibleLeafColumns().length || undefined}>
                {loading ? (
                  <div className="loading-spinner">{loadingSpinner}</div>
                ) : (
                  <p className="rt-no-data">{noDataText || defaultNoDataText()}</p>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
      {loading && rows.length > 0 && (
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
          {loadingSpinner}
        </div>
      )}
      <div className="visually-hidden" role="status">
        {statusMessage}
      </div>
    </div>
  );
}
