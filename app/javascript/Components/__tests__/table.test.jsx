import React from "react";
import {render, screen, within} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import {expect, describe, it, beforeEach} from "@jest/globals";

import {defaultSearchPlaceholderText} from "../table/search_filter";
import {defaultNoDataText} from "../table/table";
import Table from "../table/table";

function mockColumns() {
  return [
    {accessorKey: "col1", header: "col1", enableColumnFilter: true},
    {accessorKey: "col2", header: "col2", enableColumnFilter: true},
    {
      accessorKey: "col3",
      header: "col3",
      enableColumnFilter: true,
      meta: {filterVariant: "select"},
    },
  ];
}

function mockData() {
  return [
    {col1: "a", col2: "pqrs", col3: "David"},
    {col1: "ab", col2: "pqr", col3: "David"},
    {col1: "abc", col2: "pq", col3: "David"},
    {col1: "abcd", col2: "p", col3: "Ivan"},
  ];
}

function renderTableWithMockData() {
  return renderTable(mockColumns(), mockData());
}

function renderTableWithoutData() {
  return renderTable(mockColumns(), [], null);
}

function renderTableWithoutDataCustomText() {
  const customNoDataText = "custom no data text";
  const result = renderTable(mockColumns(), [], customNoDataText);
  return {...result, noDataText: customNoDataText};
}

function renderTable(columns, data, noDataText) {
  const {container, rerender} = render(
    <Table columns={columns} data={data} {...(noDataText != null && {noDataText})} />
  );
  return {table: container, columns: columns, data: data, rerender: rerender};
}

function expectTextInDocument(text) {
  screen.getAllByText(text).forEach(element => expect(element).toBeInTheDocument());
}

function expectTextNotInDocument(text) {
  expect(screen.queryByText(text)).toBeNull();
}

function expectColumnsInDocument(columns) {
  columns.forEach(({header}) => expectTextInDocument(header));
}

function expectDataInDocument(data, columns) {
  columns.forEach(({header}) => {
    data.forEach(row => {
      expectTextInDocument(row[header]);
    });
  });
}

function expectDataNotInDocument(data, columns) {
  columns.forEach(({header}) => {
    data.forEach(row => {
      expectTextNotInDocument(row[header]);
    });
  });
}

function expectRowsInTableInOrder(table, columns, rows) {
  const tableRows = table.querySelectorAll(".rt-tbody .rt-tr");

  expect(tableRows).toHaveLength(rows.length);

  columns.forEach(({header}) => {
    tableRows.forEach((tableRow, index) => {
      const rowCell = rows[index][header];

      expect(within(tableRow).getByText(rowCell)).toBeInTheDocument();
    });
  });
}

function expectClassesInDocument(classes) {
  classes.forEach(klass => expect(document.querySelector(klass)).toBeInTheDocument());
}

function expectNoDataComponentInDocument(table) {
  expect(noDataComponent(table)).toBeInTheDocument();
}

function expectNoDataComponentNotInDocument(table) {
  expect(noDataComponent(table)).toBeNull();
}

function expectNoDataComponentHasText(table, text) {
  expect(noDataComponent(table)).toHaveTextContent(text);
}

function expectSearchInputCount(count) {
  expect(searchInputs()).toHaveLength(count);
}

function noDataComponent(table) {
  return table.querySelector(".rt-no-data");
}

function searchInputs() {
  return screen.getAllByPlaceholderText(defaultSearchPlaceholderText());
}

async function clickHeader(headerText) {
  await user.click(screen.getByText(headerText));
}

function sortDataByKey(data, key, reverse) {
  data.sort((a, b) => a[key].localeCompare(b[key]));

  if (reverse) data.reverse();
}

let user;

describe("tests for the table component", () => {
  beforeEach(() => {
    user = userEvent.setup();
  });

  describe("rendering of data and columns", () => {
    it("has all columns", () => {
      const {columns} = renderTableWithMockData();

      expectColumnsInDocument(columns);
    });

    it("has all data", () => {
      const {columns, data} = renderTableWithMockData();

      expectDataInDocument(data, columns);
    });

    it("has expected css classes", () => {
      renderTableWithMockData();

      expectClassesInDocument([
        ".Table.-highlight",
        ".rt-table",
        ".rt-thead.-header",
        ".rt-thead.-filters",
        ".rt-tbody",
      ]);
    });

    it("has all data in order", () => {
      const {table, columns, data} = renderTableWithMockData();

      expectRowsInTableInOrder(table, columns, data);
    });
  });

  describe("rendering of the no-data component when data is empty", () => {
    it("shows default no data message", () => {
      const {table} = renderTableWithoutData();

      expectNoDataComponentInDocument(table);
      expectNoDataComponentHasText(table, defaultNoDataText());
    });

    it("show custom no data message", () => {
      const {table, noDataText} = renderTableWithoutDataCustomText();

      expectNoDataComponentInDocument(table);
      expectNoDataComponentHasText(table, noDataText);
    });

    it("does not show no data message when data exists", () => {
      const {table} = renderTableWithMockData();

      expectNoDataComponentNotInDocument(table);
    });
  });

  describe("sorting", () => {
    it("toggles between sort orders when the header is clicked", async () => {
      const {table, columns, data} = renderTableWithMockData();

      const header = columns[0].header;
      for (const reverse of [false, true, false]) {
        await clickHeader(header);
        sortDataByKey(data, header, reverse);
        expectRowsInTableInOrder(table, columns, data);
      }
    });

    it("does not change order when clicking a column with disabled sorting", async () => {
      const data = mockData();
      const columns = mockColumns();
      columns[0].enableSorting = false;

      const {table} = renderTable(columns, data);

      const header = columns[0].header;
      for (let i = 0; i < 3; i++) {
        await clickHeader(header);
        expectRowsInTableInOrder(table, columns, data);
      }
    });
  });

  describe("filtering", () => {
    it("shows search inputs for filterable columns", () => {
      renderTableWithMockData();

      expectSearchInputCount(2);
    });

    it("does not render a search filter for columns with disabled filtering", () => {
      const columns = mockColumns();
      columns[1].enableColumnFilter = false;
      columns[2].enableColumnFilter = false;

      renderTable(columns, mockData());

      expectSearchInputCount(1);
    });

    it("filters data", async () => {
      const {columns} = renderTableWithMockData();
      columns.pop();

      const inputs = searchInputs();
      await user.type(inputs[0], "c");

      expectDataInDocument(
        [
          {col1: "abc", col2: "pq"},
          {col1: "abcd", col2: "p"},
        ],
        columns
      );
      expectDataNotInDocument(
        [
          {col1: "a", col2: "pqrs"},
          {col1: "ab", col2: "pqr"},
        ],
        columns
      );
    });

    it("resets the filter when the search query is erased", async () => {
      const {data, columns} = renderTableWithMockData();

      const inputs = searchInputs();
      await user.type(inputs[1], "s");
      await user.type(inputs[1], "{backspace}");

      expectDataInDocument(data, columns);
    });

    it("filters data when multiple filters are used", async () => {
      const {columns} = renderTableWithMockData();
      columns.pop();

      const inputs = searchInputs();
      await user.type(inputs[0], "c");
      await user.type(inputs[1], "q");

      expectDataInDocument([{col1: "abc", col2: "pq"}], columns);
      expectDataNotInDocument(
        [
          {col1: "a", col2: "pqrs"},
          {col1: "ab", col2: "pqr"},
          {col1: "abcd", col2: "p"},
        ],
        columns
      );
    });

    it("filters data with when a select filter is used", async () => {
      const {columns} = renderTableWithMockData();
      columns.shift();
      columns.shift();

      const selectFilter = screen.getByRole("combobox");

      await user.selectOptions(selectFilter, "David");
      expectDataInDocument([{col3: "David"}, {col3: "David"}, {col3: "David"}], columns);
      expectDataNotInDocument([{col3: "Ivan"}], columns);

      await user.selectOptions(selectFilter, "Ivan");
      expectDataInDocument([{col3: "Ivan"}], columns);
      expectDataNotInDocument([{col3: "David"}, {col3: "David"}, {col3: "David"}], columns);
    });

    it("shows row counts in the select filter label", async () => {
      renderTableWithMockData();

      const selectFilter = screen.getByRole("combobox");
      const options = selectFilter.querySelectorAll("option");

      expect(options[0].textContent).toContain("All (4)");
      expect(options[1].textContent).toContain("David (3)");
      expect(options[2].textContent).toContain("Ivan (1)");
    });

    it("filtering and sorting work together", async () => {
      const {table, columns} = renderTableWithMockData();

      const inputs = searchInputs();
      await user.type(inputs[0], "abc");
      await clickHeader("col3");
      await clickHeader("col3");

      expectRowsInTableInOrder(table, columns, [
        {col1: "abcd", col2: "p", col3: "Ivan"},
        {col1: "abc", col2: "pq", col3: "David"},
      ]);
    });
  });
});
