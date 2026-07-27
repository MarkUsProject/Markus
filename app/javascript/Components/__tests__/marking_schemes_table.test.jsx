/***
 * Tests for MarkingSchemesTable Component
 */

import {MarkingSchemeTable} from "../marking_schemes_table";
import {render, screen, fireEvent} from "@testing-library/react";
import {expect} from "@jest/globals";
import {defaultSearchPlaceholderText} from "../table/search_filter";

const markingSchemesMockData = [
  {
    name: "scheme1",
    id: 1,
    assessment_weights: {
      1: 0.5,
      2: 0.5,
    },
    edit_link: "mock_edit_link",
    delete_link: "mock_delete_link",
  },
  {
    name: "scheme2",
    id: 2,
    assessment_weights: {
      1: 0.7,
      2: 0.3,
    },
    edit_link: "mock_edit_link",
    delete_link: "mock_delete_link",
  },
];

const markingSchemesMockColumns = [
  {
    accessor: "assessment_weights.1",
    Header: "A0",
    minWidth: 50,
    className: "number",
  },
  {
    accessor: "assessment_weights.2",
    Header: "A1",
    minWidth: 50,
    className: "number",
  },
];

describe("For the MarkingSchemesTable's display", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: markingSchemesMockData,
        columns: markingSchemesMockColumns,
      }),
    });

    render(<MarkingSchemeTable course_id={1} />);
    await screen.findByText("scheme1", {exact: false});
  });

  it("contains all Marking Schemes for this course", () => {
    expect(screen.queryByText(/scheme1/)).toBeInTheDocument();
    expect(screen.queryByText(/scheme2/)).toBeInTheDocument();
  });
});

describe("For the MarkingSchemesTable's Actions column", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: markingSchemesMockData,
        columns: markingSchemesMockColumns,
      }),
    });

    render(<MarkingSchemeTable course_id={1} />);
    await screen.findByText("scheme1", {exact: false});
  });

  it("renders the edit links with the correct attributes", () => {
    // Find all links with aria-label={I18n.t("edit")}
    const editActions = screen.getAllByRole("link", {name: I18n.t("edit")});
    expect(editActions).toHaveLength(2);

    // Verify each row's href attributes
    expect(editActions[0]).toHaveAttribute("href", "mock_edit_link");
    expect(editActions[1]).toHaveAttribute("href", "mock_edit_link");

    // Verify each row's data-method
    expect(editActions[0]).toHaveAttribute("data-remote", "true");
    expect(editActions[1]).toHaveAttribute("data-remote", "true");
  });

  it("renders the delete links with the correct attributes", () => {
    // Find all links with aria-label={I18n.t("delete")}
    const deleteActions = screen.getAllByRole("link", {name: I18n.t("delete")});
    expect(deleteActions).toHaveLength(2);

    // Verify each row's href attributes
    expect(deleteActions[0]).toHaveAttribute("href", "mock_delete_link");
    expect(deleteActions[1]).toHaveAttribute("href", "mock_delete_link");

    // Verify each row's data-method
    expect(deleteActions[0]).toHaveAttribute("data-method", "delete");
    expect(deleteActions[1]).toHaveAttribute("data-method", "delete");
  });
});

describe("For the MarkingSchemesTable's search filter", () => {
  beforeEach(async () => {
    fetch.mockReset();
    fetch.mockResolvedValueOnce({
      ok: true,
      json: jest.fn().mockResolvedValueOnce({
        data: markingSchemesMockData,
        columns: markingSchemesMockColumns,
      }),
    });

    render(<MarkingSchemeTable course_id={1} />);
    await screen.findByText("scheme1", {exact: false});
  });

  it("filters rows as the user types in the Name search box", () => {
    fireEvent.change(screen.getByPlaceholderText(defaultSearchPlaceholderText()), {
      target: {value: "scheme1"},
    });

    expect(screen.queryByText(/scheme1/)).toBeInTheDocument();
    expect(screen.queryByText(/scheme2/)).not.toBeInTheDocument();
  });

  it("restores all rows when the Name search query is cleared", () => {
    const searchInput = screen.getByPlaceholderText(defaultSearchPlaceholderText());
    fireEvent.change(searchInput, {target: {value: "scheme2"}});
    fireEvent.change(searchInput, {target: {value: ""}});

    expect(screen.queryByText(/scheme1/)).toBeInTheDocument();
    expect(screen.queryByText(/scheme2/)).toBeInTheDocument();
  });

  it("shows no rows when the Name search query matches nothing", () => {
    fireEvent.change(screen.getByPlaceholderText(defaultSearchPlaceholderText()), {
      target: {value: "scheme0"},
    });

    expect(screen.queryByText(/scheme1/)).not.toBeInTheDocument();
    expect(screen.queryByText(/scheme2/)).not.toBeInTheDocument();
  });
});
