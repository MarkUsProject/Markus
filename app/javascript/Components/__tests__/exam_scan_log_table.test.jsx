import {render, screen, waitForElementToBeRemoved, within} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import {ExamScanLogTable} from "../exam_scan_log_table";
import {defaultSearchPlaceholderText} from "../table/search_filter";

const unassignedPage = {status: "ERROR: QR code not found", group: null, exam_page_number: null};
const newestFirst = ["final-scan.pdf", "midterm-b.pdf", "midterm-a.pdf"];
const scanLogs = [
  {
    exam_template: "Midterm A",
    exam_template_id: 21,
    file_id: 41,
    filename: "midterm-a.pdf",
    date: "Monday, January 05, 2026, 10:00:00 AM EST",
    original_num_pages: 120,
    num_groups_in_complete: 20,
    num_groups_in_incomplete: 0,
    page_data: [],
    group_data: [],
  },
  {
    exam_template: "Midterm B",
    exam_template_id: 22,
    file_id: 42,
    filename: "midterm-b.pdf",
    date: "Tuesday, February 03, 2026, 10:00:00 AM EST",
    original_num_pages: 6,
    num_groups_in_complete: 2,
    num_groups_in_incomplete: 1,
    page_data: [{...unassignedPage, id: 101, raw_page_number: 1}],
    group_data: [{group: "paper_c", missing_pages: [1]}],
  },
  {
    exam_template: "Final",
    exam_template_id: 23,
    file_id: 43,
    filename: "final-scan.pdf",
    date: "Monday, October 05, 2026, 10:00:00 AM EDT",
    original_num_pages: 12,
    num_groups_in_complete: 0,
    num_groups_in_incomplete: 2,
    page_data: [
      {...unassignedPage, id: 201, raw_page_number: 10},
      {id: 202, raw_page_number: 2, status: "FIXED", group: "paper_b", exam_page_number: 2},
      {
        id: 203,
        raw_page_number: 1,
        status: "ERROR: Missing student",
        group: "paper_a",
        exam_page_number: 1,
      },
    ],
    group_data: [
      {group: "paper_b", missing_pages: [1, 3]},
      {group: "paper_a", missing_pages: [2]},
    ],
  },
];

function filenames() {
  return screen.queryAllByRole("link", {name: /\.pdf$/}).map(link => link.textContent);
}

function scanRow(filename) {
  return screen.getByRole("link", {name: filename}).closest('[role="row"]');
}

async function renderLogs(data = scanLogs) {
  fetch.mockResponseOnce(JSON.stringify(data));
  const result = render(<ExamScanLogTable course_id={7} assignment_id={9} />);
  await waitForElementToBeRemoved(() => screen.queryByLabelText("grid-loading"));
  return result;
}

async function expandLog(user, filename) {
  await user.click(within(scanRow(filename)).getByTestId("expander-button"));
  const [, errors, groups] = screen.getAllByRole("grid");
  return {errors, groups};
}

function filterInput(key) {
  return screen.getByRole("textbox", {name: defaultSearchPlaceholderText(I18n.t(key))});
}

function columnValues(table, index) {
  return within(table)
    .getAllByRole("row")
    .slice(1)
    .map(row => within(row).getAllByRole("gridcell")[index].textContent);
}

function fixPath(log, pageId) {
  return Routes.assign_errors_course_exam_template_path(7, log.exam_template_id, {
    split_pdf_log_id: log.file_id,
    split_page_id: pageId,
  });
}

let user;
beforeEach(() => {
  fetch.resetMocks();
  user = userEvent.setup();
});

describe("ExamScanLogTable", () => {
  it("shows an empty state instead of crashing when the logs request is unsuccessful", async () => {
    fetch.mockResponseOnce("", {status: 500});
    render(<ExamScanLogTable course_id={7} assignment_id={9} />);

    expect(await screen.findByText(I18n.t("table.no_data"))).toBeInTheDocument();
    expect(screen.queryByLabelText("grid-loading")).not.toBeInTheDocument();
  });

  it("loads the assignment's scan logs and shows a loading indicator until they arrive", async () => {
    fetch.mockResponseOnce(JSON.stringify(scanLogs));
    render(<ExamScanLogTable course_id={7} assignment_id={9} />);

    expect(screen.getByLabelText("grid-loading")).toBeInTheDocument();
    expect(fetch).toHaveBeenCalledWith(
      Routes.view_logs_course_assignment_exam_templates_path(7, 9),
      {headers: {Accept: "application/json"}}
    );
    await screen.findByRole("link", {name: "final-scan.pdf"});
    expect(screen.queryByLabelText("grid-loading")).not.toBeInTheDocument();
  });

  it("keeps the grouped headers and sorts dates newest first, then toggles to oldest first", async () => {
    await renderLogs();

    for (const key of ["file_information", "pages", "papers_found"]) {
      expect(screen.getByText(I18n.t(`split_pdf_logs.${key}`))).toBeInTheDocument();
    }
    expect(filenames()).toEqual(newestFirst);
    await user.click(screen.getByText(I18n.t("attributes.date")));
    expect(filenames()).toEqual(["midterm-a.pdf", "midterm-b.pdf", "final-scan.pdf"]);
  });

  it("keeps each raw download linked to its own template and scan log", async () => {
    await renderLogs();

    for (const log of scanLogs) {
      expect(screen.getByRole("link", {name: log.filename})).toHaveAttribute(
        "href",
        Routes.download_raw_split_file_course_exam_template_path(7, log.exam_template_id, {
          split_pdf_log_id: log.file_id,
        })
      );
    }
  });

  it("shows the error and fixed counts, with a warning only for pending errors", async () => {
    await renderLogs();

    const cells = within(scanRow("final-scan.pdf")).getAllByRole("gridcell");
    expect(cells.map(cell => cell.textContent)).toEqual([
      "",
      "Final",
      scanLogs[2].date,
      "final-scan.pdf",
      "12",
      "2",
      "1",
      "0",
      "2",
    ]);
    expect(cells[5].querySelector(".error-with-icon svg")).toBeInTheDocument();
    expect(scanRow("midterm-a.pdf").querySelector(".error-with-icon")).not.toBeInTheDocument();
    expect(within(scanRow("midterm-a.pdf")).getAllByRole("gridcell")[5].textContent).toBe("");
  });

  it.each([
    ["activerecord.attributes.split_pdf_log.exam_template", "FINAL", ["final-scan.pdf"]],
    ["attributes.date", "October", ["final-scan.pdf"]],
    ["activerecord.attributes.split_pdf_log.filename", "FINAL", ["final-scan.pdf"]],
    [
      "activerecord.attributes.split_pdf_log.original_num_pages",
      "2",
      ["final-scan.pdf", "midterm-a.pdf"],
    ],
    ["split_pdf_logs.pages_error", "2", ["final-scan.pdf"]],
    ["split_pdf_logs.pages_fixed", "1", ["final-scan.pdf"]],
    ["submissions.state.complete", "2", ["midterm-b.pdf", "midterm-a.pdf"]],
    ["submissions.state.incomplete", "1", ["midterm-b.pdf"]],
  ])("filters %s using a case-insensitive substring match", async (key, value, expected) => {
    await renderLogs();

    const input = filterInput(key);
    await user.type(input, value);
    expect(filenames()).toEqual(expected);
    await user.clear(input);
    expect(filenames()).toEqual(newestFirst);
  });

  it("sorts page counts numerically", async () => {
    await renderLogs();

    await user.click(
      screen.getByText(I18n.t("activerecord.attributes.split_pdf_log.original_num_pages"))
    );
    expect(filenames()).toEqual(["midterm-b.pdf", "final-scan.pdf", "midterm-a.pdf"]);
  });

  it("shows an empty state when the server returns no logs or a filter has no matches", async () => {
    const {unmount} = await renderLogs([]);
    expect(screen.getByText(I18n.t("table.no_data"))).toBeInTheDocument();
    expect(screen.queryByTestId("expander-button")).not.toBeInTheDocument();
    unmount();

    await renderLogs();
    await user.type(
      filterInput("activerecord.attributes.split_pdf_log.exam_template"),
      "no matching template"
    );
    expect(screen.getByText(I18n.t("table.no_data"))).toBeInTheDocument();
    expect(filenames()).toEqual([]);
  });

  it("expands both child tables and uses the selected log's IDs in fix links", async () => {
    await renderLogs();
    expect(screen.getAllByRole("grid")).toHaveLength(1);

    const {errors, groups} = await expandLog(user, "final-scan.pdf");
    expect(within(errors).getByText("FIXED")).toBeInTheDocument();
    const fixText = I18n.t("exam_templates.assign_errors.fix_errors");
    const fixes = within(errors).getAllByRole("link", {name: fixText});
    expect(fixes).toHaveLength(2);
    for (const [index, pageId] of [201, 203].entries()) {
      expect(fixes[index]).toHaveAttribute("href", fixPath(scanLogs[2], pageId));
    }
    expect(within(errors).getByText("FIXED").closest('[role="row"]').querySelector("a")).toBeNull();
    expect(within(groups).getByText("1, 3")).toBeInTheDocument();
    expect(within(groups).getByText("paper_a")).toBeInTheDocument();
    expect(screen.getAllByRole("textbox")).toHaveLength(8);

    await user.click(within(scanRow("final-scan.pdf")).getByTestId("expander-button"));
    expect(screen.getAllByRole("grid")).toHaveLength(1);
    await expandLog(user, "midterm-b.pdf");
    expect(screen.getByRole("link", {name: fixText})).toHaveAttribute(
      "href",
      fixPath(scanLogs[1], 101)
    );
  });

  it("sorts each child table without changing the main table order", async () => {
    await renderLogs();
    const {errors, groups} = await expandLog(user, "final-scan.pdf");

    for (const [table, header, column, expected] of [
      [errors, "Raw page number", 0, ["1", "2", "10"]],
      [errors, I18n.t("activerecord.models.group.one"), 2, ["", "paper_a", "paper_b"]],
      [groups, I18n.t("split_pdf_logs.paper"), 0, ["paper_a", "paper_b"]],
    ]) {
      await user.click(within(table).getByText(header));
      expect(columnValues(table, column)).toEqual(expected);
    }
    expect(filenames()).toEqual(newestFirst);
  });

  it("shows an empty state in each child table when a log has no errors or incomplete papers", async () => {
    await renderLogs();
    const {errors, groups} = await expandLog(user, "midterm-a.pdf");

    expect(within(errors).getByText(I18n.t("table.no_data"))).toBeInTheDocument();
    expect(within(groups).getByText(I18n.t("table.no_data"))).toBeInTheDocument();
    expect(within(errors).queryByRole("link")).not.toBeInTheDocument();
  });
});
