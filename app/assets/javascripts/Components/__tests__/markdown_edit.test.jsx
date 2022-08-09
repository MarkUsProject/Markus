import {shallow} from "enzyme";
import MarkdownEdit from "../markdown_edit";

const basicProps = {
  content: "",
  handleChange: jest.fn(),
  show_autocomplete: false,
  updateAnnotationCompletion: jest.fn(),
};

describe("MarkdownEdit", () => {
  let props, wrapper;
  const getWrapper = () => {
    return shallow(<MarkdownEdit {...props} />);
  };
  beforeEach(() => {
    props = {...basicProps};
  });

  it("sets the content to the prop content by default", () => {
    props.content = "Hi Prof Liu";
    wrapper = getWrapper(props);

    expect(wrapper.state().content).toBe(props.content);
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

    expect(props.handleChange).toHaveBeenCalledWith(event);
    expect(wrapper.state().content).toBe(event.target.value);
  });

  it("should show and update autocomplete if desired", () => {
    props.show_autocomplete = true;
    props.annotation_text_id = "id";
    wrapper = getWrapper(props);

    const annotationList = wrapper.find("#annotation_text_list");

    expect(annotationList.exists()).toBeTruthy();

    expect(wrapper.find("#annotation_text_id").props().value).toBe(props.annotation_text_id);
  });

  it("should properly display and pass down props to the preview tab", () => {
    props.content = "arma virumque cano";
    wrapper = getWrapper(props);

    wrapper.find("#preview-tab").simulate("click");

    const preview = wrapper.find("#markdown-preview");

    expect(preview.exists()).toBeTruthy();

    expect(preview.props().content).toBe(props.content);
    expect(preview.props().updateAnnotationCompletion).toBe(props.updateAnnotationCompletion);
  });
});
