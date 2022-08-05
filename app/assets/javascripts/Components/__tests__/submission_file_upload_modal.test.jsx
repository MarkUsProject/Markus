import {shallow} from "enzyme";
import SubmissionFileUploadModal from "../Modals/submission_file_upload_modal";

describe("For the SubmissionFileUploadModal", () => {
  let wrapper;
  describe("The select element", () => {
    beforeEach(() => {
      wrapper = shallow(
        <SubmissionFileUploadModal
          onlyRequiredFiles={true}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
        />
      );
    });

    it("renders the element if onlyRequiredFiles is true", () => {
      expect(wrapper.find(".select-filename").isEmptyRender()).toBeFalsy();
    });
    it("does not render the datalist and textbox elements if onlyRequiredFiles is true", () => {
      expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeTruthy();
      expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      expect(wrapper.find(".select-filename").props().disabled).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", () => {
      wrapper.setState({newFiles: ["q1.py", "q2.py"]});
      expect(wrapper.find(".select-filename").props().disabled).toBeTruthy();
    });
    describe("length of newFiles in the state is 1", () => {
      beforeEach(() => {
        wrapper.setState({newFiles: ["main.py"]});
      });
      it("enables the element", () => {
        expect(wrapper.find(".select-filename").props().disabled).toBeFalsy();
      });
      it("only shows the files required in the root directory if uploadTarget is null", () => {
        const filenames = wrapper
          .find(".select-filename")
          .props()
          .children[1].map(obj => obj.key);
        expect(filenames).toEqual(["q1.py", "q2.py", "q3.py"]);
      });
      it("only shows the files in the activated directory if uploadTarget is not null", () => {
        wrapper.setProps({uploadTarget: "part1/"});
        const filenames = wrapper
          .find(".select-filename")
          .props()
          .children[1].map(obj => obj.key);
        expect(filenames).toEqual(["p1.py"]);
      });
    });
  });
  describe("The datalist input element", () => {
    beforeEach(() => {
      wrapper = shallow(
        <SubmissionFileUploadModal
          onlyRequiredFiles={false}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
        />
      );
    });
    it("renders the element if onlyRequiredFiles is false and requiredFiles is non empty", () => {
      expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeFalsy();
    });
    it("does not render the select and textbox elements if onlyRequiredFiles is false and requiredFiles is non empty", () => {
      expect(wrapper.find(".select-filename").isEmptyRender()).toBeTruthy();
      expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      expect(wrapper.find(".datalist-textbox").props().disabled).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", () => {
      wrapper.setState({newFiles: ["q1.py", "q2.py"]});
      expect(wrapper.find(".datalist-textbox").props().disabled).toBeTruthy();
    });
    describe("length of newFiles in the state is 1", () => {
      beforeEach(() => {
        wrapper.setState({newFiles: ["main.py"]});
      });
      it("enables the element", () => {
        expect(wrapper.find(".datalist-textbox").props().disabled).toBeFalsy();
      });
      it("only shows the files required in the root directory if uploadTarget is null", () => {
        const filenames = wrapper
          .find("#fileInput_datalist")
          .props()
          .children.map(obj => obj.key);
        expect(filenames).toEqual(["q1.py", "q2.py", "q3.py"]);
      });
      it("only shows the files in the activated directory if uploadTarget is not null", () => {
        wrapper.setProps({uploadTarget: "part1/"});
        const filenames = wrapper
          .find("#fileInput_datalist")
          .props()
          .children.map(obj => obj.key);
        expect(filenames).toEqual(["p1.py"]);
      });
    });
  });
  describe("The textbox element", () => {
    beforeEach(() => {
      wrapper = shallow(
        <SubmissionFileUploadModal
          onlyRequiredFiles={false}
          requiredFiles={[]}
          uploadTarget={null}
        />
      );
    });
    it("renders the element if onlyRequiredFiles is false and requiredFiles is empty", () => {
      expect(wrapper.find(".file-rename-textbox").isEmptyRender()).toBeFalsy();
    });
    it("does not render the select and datalist input elements if onlyRequiredFiles is false and requiredFiles is empty", () => {
      expect(wrapper.find(".select-filename").isEmptyRender()).toBeTruthy();
      expect(wrapper.find(".datalist-textbox").isEmptyRender()).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      expect(wrapper.find(".file-rename-textbox").props().disabled).toBeTruthy();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", () => {
      wrapper.setState({newFiles: ["q1.py", "q2.py"]});
      expect(wrapper.find(".file-rename-textbox").props().disabled).toBeTruthy();
    });
    it("enables the element if the length of newFiles in the state is 1", () => {
      wrapper.setState({newFiles: ["q1.py"]});
      expect(wrapper.find(".file-rename-textbox").props().disabled).toBeFalsy();
    });
  });
});
