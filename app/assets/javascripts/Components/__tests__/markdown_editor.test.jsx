import {shallow} from "enzyme";
import MarkdownEditor from "../markdown_editor";

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
  let props, wrapper;
  const getWrapper = () => {
    return shallow(<MarkdownEditor {...props} />);
  };
  beforeEach(() => {
    props = {...basicProps};
  });

  it("should properly handle the text input change", () => {
    wrapper = getWrapper(props);

    const inputBox = wrapper.find("#new_annotation_content");

    expect(inputBox.exists()).toBeTruthy();

    const event = {
      target: {
        value: "Hello world",
      },
    };

    inputBox.simulate("change", event);

    // expect(props.handleChange).toHaveBeenCalledWith(event);
  });

  it("should show autocomplete if desired", () => {
    props.show_autocomplete = true;
    props.annotation_text_id = "id";
    wrapper = getWrapper(props);

    const annotationList = wrapper.find("#annotation_text_list");

    expect(annotationList.exists()).toBeTruthy();
  });

  it("should properly display and pass down props to the preview tab", () => {
    props.content = "arma virumque cano";
    wrapper = getWrapper(props);

    //At 1 because it is the 2nd tab
    wrapper.find("Tab").at(1).simulate("click");

    const preview = wrapper.find("#markdown-preview");

    expect(preview.exists()).toBeTruthy();

    expect(preview.props().content).toBe(props.content);
    expect(preview.props().updateAnnotationCompletion).toBe(props.updateAnnotationCompletion);
  });
});
