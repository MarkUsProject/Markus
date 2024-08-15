import React from "react";
import {render, screen, cleanup} from "@testing-library/react";
import {TextViewer} from "../Result/text_viewer";

describe("TextViewer", () => {
  let props;

  beforeEach(() => {
    props = {
      content: "def f(n: int) -> int:\n    return n + 1\n",
      annotations: [],
      focusLine: null,
      submission_file_id: 1,
    };

    render(<TextViewer {...props} />);
  });

  afterEach(cleanup);

  it("should render its text content", () => {
    expect(screen.getByText("def f(n: int) -> int:")).toBeInTheDocument();
  });
});
