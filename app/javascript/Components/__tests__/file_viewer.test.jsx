import React from "react";
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

    await render(<FileViewer {...props} />);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(
      await screen.findByText(I18n.t("submissions.oversize_submission_file"))
    ).toBeInTheDocument();
  });
});
