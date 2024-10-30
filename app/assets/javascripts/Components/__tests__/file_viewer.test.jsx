import React from "react";
import {render, screen, cleanup, waitFor} from "@testing-library/react";
import {FileViewer} from "../Result/file_viewer";

describe("FileViewer", () => {
  afterEach(cleanup);

  it("should not render oversized files", async () => {
    // mocks `/get_file` request
    global.fetch = () =>
      Promise.resolve({
        json: () => Promise.resolve({content: "", type: "", size: 1e32}),
      });

    const props = {
      course_id: 0,
      submission_id: 0,
      result_id: 1,
      selectedFile: [],
    };

    render(<FileViewer {...props} />);

    // waits for the fetch promise to resolve
    await waitFor(() =>
      expect(screen.getByText(I18n.t("oversize_submission_file"))).toBeInTheDocument()
    );
  });
});
