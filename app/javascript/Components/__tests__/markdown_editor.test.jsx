import {render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import MarkdownEditor from "../markdown_editor";
import {ResultContext} from "../Result/result_context";
import {renderInResultContext} from "./result_context_renderer";

const basicProps = {
  content: "",
  text_area_id: "new_annotation_content",
  auto_completion_text_id: "annotation_completion_text",
  auto_completion_list_id: "annotation_text_list",
  handleChange: jest.fn(),
  show_autocomplete: false,
  updateAnnotationCompletion: jest.fn(),
};

describe("MarkdownEditor", () => {
  let props;
  beforeEach(() => {
    props = {...basicProps};
  });

  it("should properly handle the text input change", async () => {
    renderInResultContext(<MarkdownEditor {...props} />);

    const inputBox = screen.getByRole("textbox");
    await userEvent.type(inputBox, "Hello world");

    expect(props.handleChange).toHaveBeenCalled();
  });

  it("should show autocomplete if desired", async () => {
    props.show_autocomplete = true;
    props.annotation_text_id = "id";
    renderInResultContext(<MarkdownEditor {...props} />);

    const autocompleteList = screen.queryByTestId("markdown-editor-autocomplete-root");
    expect(autocompleteList).toBeTruthy();
  });

  it("should properly display and pass down props to the preview tab", async () => {
    props.content = "arma virumque cano";
    renderInResultContext(<MarkdownEditor {...props} />);

    await userEvent.click(screen.getByRole("tab", {name: "Preview"}));

    const preview = document.querySelector("#annotation-preview");
    expect(preview).toBeTruthy();
    expect(preview.textContent.trim()).toEqual(props.content);
  });
});
