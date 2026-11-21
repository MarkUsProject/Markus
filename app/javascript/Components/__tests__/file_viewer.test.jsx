import {render, screen} from "@testing-library/react";
import {FileViewer} from "../Result/file_viewer";
import fetchMock from "jest-fetch-mock";

describe("FileViewer", () => {
  afterEach(() => {
    fetchMock.resetMocks();
  });

  it("should not render oversized files", async () => {
    fetchMock.mockOnce({}, {status: 413});

    const props = {
      course_id: 0,
      submission_id: 0,
      result_id: 1,
      selectedFile: [],
      selectedFileType: "text",
      selectedFileURL: "/",
    };

    // The viewer logs the oversize error after showing its message
    const consoleError = jest.spyOn(global.console, "error").mockImplementation(() => {});

    render(<FileViewer {...props} />);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(
      await screen.findByText(I18n.t("submissions.oversize_submission_file"))
    ).toBeInTheDocument();
    expect(consoleError).toHaveBeenCalledWith(
      new Error(I18n.t("submissions.oversize_submission_file"))
    );
    consoleError.mockRestore();
  });
});
