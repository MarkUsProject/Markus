import React from "react";
import {render, screen, cleanup, waitFor, fireEvent} from "@testing-library/react";
import {BinaryViewer} from "../Result/binary_viewer";
import fetchMock from "jest-fetch-mock";

describe("BinaryViewer", () => {
  let props;

  afterEach(() => {
    fetchMock.resetMocks();
    cleanup();
  });

  it("should fetch content when a URL is passed but not show it until requested by the user", async () => {
    props = {
      url: "/",
      annotations: [],
      focusLine: null,
      submission_file_id: 1,
      setLoadingCallback: _ => {},
    };

    fetchMock.mockOnce("File content");

    render(<BinaryViewer {...props} />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });

    expect(screen.queryByText("File content")).not.toBeInTheDocument();
    expect(screen.getByText(I18n.t("submissions.get_anyway"))).toBeInTheDocument();
    fireEvent.click(screen.getByText(I18n.t("submissions.get_anyway")));
    expect(screen.getByText("File content")).toBeInTheDocument();
    expect(screen.queryByText(I18n.t("submissions.get_anyway"))).not.toBeInTheDocument();
  });
});
