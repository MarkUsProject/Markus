import {shallow} from "enzyme";
import SubmissionFileUploadModal from "../Modals/submission_file_upload_modal";

describe("For the SubmissionFileUploadModal", () => {
  it("checks if only selection menu renders", () => {
    let wrapper = shallow(
      <SubmissionFileUploadModal onlyRequiredFiles={true} requiredFiles={[{filename: "a1.py"}]} />
    );
    wrapper.setState({single_file_name: "main.py", newFiles: ["main.py"]});
    expect(wrapper.find(".select-filename").isEmptyRender()).toBeFalsy();
    expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeTruthy();
    expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeTruthy();
  });

  it("checks if only datalist menu renders", () => {
    let wrapper = shallow(
      <SubmissionFileUploadModal onlyRequiredFiles={false} requiredFiles={[{filename: "a1.py"}]} />
    );
    wrapper.setState({single_file_name: "main.py", newFiles: ["main.py"]});
    expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeFalsy();
    expect(wrapper.find(".select-filename").isEmptyRender()).toBeTruthy();
    expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeTruthy();
  });

  it("checks if only file rename textbox menu renders", () => {
    let wrapper = shallow(
      <SubmissionFileUploadModal onlyRequiredFiles={false} requiredFiles={[]} />
    );
    wrapper.setState({single_file_name: "main.py", newFiles: ["main.py"]});
    expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeFalsy();
    expect(wrapper.find(".select-filename").isEmptyRender()).toBeTruthy();
    expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeTruthy();
  });
});
