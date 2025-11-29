import {CourseSummaryTable} from "../course_summaries_table";
import {render, screen, within, fireEvent, waitFor} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import {customLoadingProp} from "../Helpers/table_helpers";

describe("For each CourseSummaries' loading status", () => {
  beforeEach(() => {
    jest.spyOn(global, "fetch").mockImplementation(() => new Promise(() => {}));
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("shows loading spinner when data is being fetched", async () => {
    render(<CourseSummaryTable loading={true} LoadingComponent={customLoadingProp} />);

    const spinner = await screen.findByLabelText("grid-loading");
    expect(spinner).toBeInTheDocument();
  });
});

describe("CourseSummaryTable show/hide inactive students", () => {
  it("toggles the checkbox UI state when clicked", async () => {
    render(<CourseSummaryTable />);

    const checkbox = screen.getByLabelText(/display inactive students/i);

    expect(checkbox).not.toBeChecked(); // Initial state: not checked

    await userEvent.click(checkbox); // Toggle to showHidden = true
    expect(checkbox).toBeChecked();

    await userEvent.click(checkbox); // Toggle to showHidden = false
    expect(checkbox).not.toBeChecked();
  });

  it("updateShowHidden correctly updates state and columnFilters", () => {
    const table = new CourseSummaryTable({});

    // Spy on setState
    const setStateSpy = jest.spyOn(table, "setState");

    // Initial state
    expect(table.state.showHidden).toBe(false);
    expect(table.state.columnFilters).toEqual([{id: "hidden", value: false}]);

    // Check the checkbox (show hidden = true)
    const event1 = {target: {checked: true}};
    table.updateShowHidden(event1);

    // Check setState called with correct values
    expect(setStateSpy).toHaveBeenCalledWith({
      showHidden: true,
      columnFilters: [],
    });

    table.state.showHidden = true;
    table.state.columnFilters = [];

    // Uncheck the checkbox (show hidden = false)
    const event2 = {target: {checked: false}};
    table.updateShowHidden(event2);

    expect(setStateSpy).toHaveBeenCalledWith({
      showHidden: false,
      columnFilters: [{id: "hidden", value: false}], // Hidden filter added back
    });
  });

  it("updateShowHidden preserves other column filters", () => {
    const table = new CourseSummaryTable({});
    const setStateSpy = jest.spyOn(table, "setState");

    // Set up state with multiple filters
    table.state.columnFilters = [
      {id: "hidden", value: false},
      {id: "user_name", value: "test"},
    ];

    // Toggle show hidden to true
    const event = {target: {checked: true}};
    table.updateShowHidden(event);

    // Should preserve user_name filter & remove hidden filter
    expect(setStateSpy).toHaveBeenCalledWith({
      showHidden: true,
      columnFilters: [{id: "user_name", value: "test"}],
    });

    // Manually update state
    table.state.showHidden = true;
    table.state.columnFilters = [{id: "user_name", value: "test"}];

    // Toggle back to false
    const event2 = {target: {checked: false}};
    table.updateShowHidden(event2);

    // Should have both filters again
    expect(setStateSpy).toHaveBeenCalledWith({
      showHidden: false,
      columnFilters: [
        {id: "user_name", value: "test"},
        {id: "hidden", value: false},
      ],
    });
  });
});

describe("For CourseSummaryTable nameColumns,", () => {
  it("filterFn correctly hides rows when hidden=true", () => {
    const table = new CourseSummaryTable({});
    const [hiddenColumn] = table.nameColumns();

    const filterFn = hiddenColumn.filterFn;

    const visibleRow = {original: {hidden: false}};
    expect(filterFn(visibleRow, "hidden", false)).toBe(true);

    const hiddenRow = {original: {hidden: true}};
    expect(filterFn(hiddenRow, "hidden", false)).toBe(false);

    expect(filterFn(hiddenRow, "hidden", true)).toBe(true); // filterValue = true, show all rows
  });

  it("filterFn shows all rows when filterValue is true", () => {
    const table = new CourseSummaryTable({});
    const [hiddenColumn] = table.nameColumns();
    const filterFn = hiddenColumn.filterFn;

    const hiddenRow = {original: {hidden: true}};
    const visibleRow = {original: {hidden: false}};

    // When filterValue is true (show hidden checkbox is checked), show all rows
    expect(filterFn(hiddenRow, "hidden", true)).toBe(true);
    expect(filterFn(visibleRow, "hidden", true)).toBe(true);

    // When filterValue is false (show hidden checkbox is unchecked), filter out hidden rows
    expect(filterFn(hiddenRow, "hidden", false)).toBe(false);
    expect(filterFn(visibleRow, "hidden", false)).toBe(true);
  });

  it("does not render the hidden column in the table", async () => {
    render(<CourseSummaryTable />);

    expect(screen.queryByText("hidden")).not.toBeInTheDocument();
  });

  it("does not render the hidden column in the table", async () => {
    render(<CourseSummaryTable />);

    expect(screen.queryByText("hidden")).not.toBeInTheDocument();
  });
});

describe("CourseSummaryTable dataColumns", () => {
  it("creates columns for assessments and marking schemes", () => {
    const assessments = [{id: 1, name: "A1"}];
    const marking_schemes = [{id: 2, name: "Scheme1"}];

    const table = new CourseSummaryTable({assessments, marking_schemes});
    const columns = table.dataColumns();

    expect(columns.length).toBe(2);
  });
});

describe("CourseSummaryTable student view", () => {
  it("does not include name columns when student=true", () => {
    const assessments = [{id: 1, name: "A1"}];
    render(<CourseSummaryTable student={true} assessments={assessments} />);

    // Name columns should not appear
    expect(screen.queryByText(I18n.t("activerecord.attributes.user.user_name"))).toBeNull();

    // Data column should appear
    expect(screen.getByText("A1")).toBeInTheDocument();
  });
});

describe("CourseSummaryTable manual filtering", () => {
  it("filterFn correctly filters marks", () => {
    const assessments = [{id: 1, name: "A1"}];
    const marking_schemes = [];
    const table = new CourseSummaryTable({assessments, marking_schemes});
    const columns = table.dataColumns();

    const assessmentColumn = columns[0];
    const filterFn = assessmentColumn.filterFn;

    // Mock row with getValue returning a number
    const mockRow = {
      getValue: () => 15,
    };

    // Should match when filter value is contained in the mark
    expect(filterFn(mockRow, "assessment_marks.1.mark", "15")).toBe(true);
    expect(filterFn(mockRow, "assessment_marks.1.mark", "1")).toBe(true);
    expect(filterFn(mockRow, "assessment_marks.1.mark", "5")).toBe(true);

    // Should not match when filter value is not contained
    expect(filterFn(mockRow, "assessment_marks.1.mark", "7")).toBe(false);
    expect(filterFn(mockRow, "assessment_marks.1.mark", "20")).toBe(false);
  });

  it("filterFn works for marking schemes columns", () => {
    const assessments = [];
    const marking_schemes = [{id: 1, name: "Scheme1"}];
    const table = new CourseSummaryTable({assessments, marking_schemes});
    const columns = table.dataColumns();

    const schemeColumn = columns[0];
    const filterFn = schemeColumn.filterFn;

    const mockRow = {
      getValue: () => 85,
    };

    // Should match
    expect(filterFn(mockRow, "weighted_marks.1.mark", "85")).toBe(true);
    expect(filterFn(mockRow, "weighted_marks.1.mark", "8")).toBe(true);

    // Should not match
    expect(filterFn(mockRow, "weighted_marks.1.mark", "7")).toBe(false);

    // Null handling
    const mockRowWithNull = {
      getValue: () => null,
    };
    expect(filterFn(mockRowWithNull, "weighted_marks.1.mark", "5")).toBe(false);
  });
});
