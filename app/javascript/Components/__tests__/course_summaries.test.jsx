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

  it("toggles the checkbox UI state when clicked", async () => {
    render(<CourseSummaryTable />);

    const checkbox = screen.getByLabelText(/display inactive students/i);

    expect(checkbox).not.toBeChecked(); // Initial state: not checked

    await userEvent.click(checkbox); // Toggle to showHidden = true
    expect(checkbox).toBeChecked();

    await userEvent.click(checkbox); // Toggle to showHidden = false
    expect(checkbox).not.toBeChecked();
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
