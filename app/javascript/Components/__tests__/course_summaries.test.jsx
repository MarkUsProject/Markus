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
