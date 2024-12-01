import React from "react";
import {render, screen, cleanup, waitFor} from "@testing-library/react";
import {TextViewer} from "../Result/text_viewer";
import fetchMock from "jest-fetch-mock";

describe("TextViewer", () => {
  let props;

  afterEach(() => {
    fetchMock.resetMocks();
    cleanup();
  });

  it("should render its text content when the content ends with a new line", () => {
    props = {
      content: "def f(n: int) -> int:\n    return n + 1\n",
      annotations: [],
      focusLine: null,
      submission_file_id: 1,
    };

    render(<TextViewer {...props} />);

    expect(screen.getByText("def f(n: int) -> int:")).toBeInTheDocument();
  });

  it("should render its text content when the content doesn't end with a new line", () => {
    props = {
      content: "def f(n: int) -> int:\n    return n + 1",
      annotations: [],
      focusLine: null,
      submission_file_id: 1,
    };

    render(<TextViewer {...props} />);

    expect(screen.getByText("def f(n: int) -> int:")).toBeInTheDocument();
  });

  it("should fetch content when a URL is passed", async () => {
    props = {
      url: "/",
      annotations: [],
      focusLine: null,
      submission_file_id: 1,
    };

    fetchMock.mockOnce("File content");

    render(<TextViewer {...props} />);
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(screen.getByText("File content")).toBeInTheDocument();
    });
  });
});
