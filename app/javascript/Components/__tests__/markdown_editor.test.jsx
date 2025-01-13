import {render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import MarkdownEditor from "../markdown_editor";
import {ResultContext} from "../Result/result_context";

const basicProps = {
  content: "",
  text_area_id: "new_annotation_content",
  auto_completion_text_id: "annotation_completion_text",
  auto_completion_list_id: "annotation_text_list",
  handleChange: jest.fn(),
  show_autocomplete: false,
  updateAnnotationCompletion: jest.fn(),
};

const contextValue = {
  result_id: 1,
  submission_id: 1,
  assignment_id: 1,
  grouping_id: 1,
  course_id: 1,
  role: "user",
  is_reviewer: false,
};

describe("MarkdownEditor", () => {
  let props;
  beforeEach(() => {
    props = {...basicProps};
  });

  it("should properly handle the text input change", async () => {
    render(
      <ResultContext.Provider value={contextValue}>
        <MarkdownEditor {...props} />
      </ResultContext.Provider>
    );

    const inputBox = screen.getByRole("textbox");
    await userEvent.type(inputBox, "Hello world");

    expect(props.handleChange).toHaveBeenCalled();
  });

  it("should show autocomplete if desired", async () => {
    props.show_autocomplete = true;
    props.annotation_text_id = "id";
    render(
      <ResultContext.Provider value={contextValue}>
        <MarkdownEditor {...props} />
      </ResultContext.Provider>
    );

    const autocompleteList = screen.queryByTestId("markdown-editor-autocomplete-root");
    expect(autocompleteList).toBeTruthy();
  });

  it("should properly display and pass down props to the preview tab", async () => {
    props.content = "arma virumque cano";
    render(
      <ResultContext.Provider value={contextValue}>
        <MarkdownEditor {...props} />
      </ResultContext.Provider>
    );

    await userEvent.click(screen.getByRole("tab", {name: "Preview"}));

    const preview = document.querySelector("#annotation-preview");
    expect(preview).toBeTruthy();
    expect(preview.textContent.trim()).toEqual(props.content);
  });
});
