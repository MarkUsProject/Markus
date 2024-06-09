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
  describe("The onSubmit method", () => {
    // Mock onSubmit function
    const mockOnSubmit = jest.fn();

    beforeEach(() => {
      wrapper = shallow(
        <SubmissionFileUploadModal
          onlyRequiredFiles={true}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
          onSubmit={mockOnSubmit} // Pass the mocked onSubmit function
        />
      );
    });

    it("should call onSubmit prop with correct arguments when extensions match", () => {
      // Mock setState method
      wrapper.setState({
        newFiles: [{name: "file.py"}],
        renameTo: "file.py",
      });

      // Simulate form submission
      wrapper.instance().onSubmit({preventDefault: jest.fn()});

      // Ensure onSubmit is called with expected arguments
      expect(mockOnSubmit).toHaveBeenCalledWith([{name: "file.py"}], undefined, false, "file.py");
    });

    it("should not call onSubmit prop when extensions don't match and user cancels", () => {
      // Mock window.confirm to return false
      window.confirm = jest.fn(() => false);

      // Mock setState method
      wrapper.setState({
        newFiles: [{name: "file1.py"}],
        renameTo: "file2.txt",
      });

      // Simulate form submission
      wrapper.instance().onSubmit({preventDefault: jest.fn()});

      // Ensure onSubmit is not called
      expect(mockOnSubmit).not.toHaveBeenCalled();
    });

    it("should call onSubmit prop with correct arguments when extensions don't match and user confirms", () => {
      // Mock window.confirm to return true
      window.confirm = jest.fn(() => true);

      // Mock setState method
      wrapper.setState({
        newFiles: [{name: "file1.py"}],
        renameTo: "file2.txt",
      });

      // Simulate form submission
      wrapper.instance().onSubmit({preventDefault: jest.fn()});

      // Ensure onSubmit is called with expected arguments
      expect(mockOnSubmit).toHaveBeenCalledWith(
        [{name: "file1.py"}],
        undefined,
        false,
        "file2.txt"
      );
    });
  });

  describe("The progress bar", () => {
    describe("when the progressVisible prop is initially true and progressPercentage prop is 0.0", () => {
      beforeEach(() => {
        // for testing the behaviour of progress bar after submit
        mockOnSubmit = jest.fn(() => {
          wrapper.setProps({progressVisible: false});
        });

        wrapper = shallow(
          <SubmissionFileUploadModal
            progressVisible={true}
            progressPercentage={0.0}
            requiredFiles={[]}
            onSubmit={mockOnSubmit}
          />
        );

        // to ensure submit button is enabled
        wrapper.setState({newFiles: ["q1.py", "q2.py"]});
      });

      it("the progress bar is initially visible", () => {
        expect(wrapper.find(".modal-progress-bar").exists()).toBeTruthy();
      });

      it("the progress bar's value is initially 0.0", () => {
        expect(wrapper.find(".modal-progress-bar").props()["value"]).toEqual(0.0);
      });

      it("the progress bar's value changes when the prop progressPercentage changes", () => {
        wrapper.setProps({progressPercentage: 50.0});
        wrapper.update();
        expect(wrapper.find(".modal-progress-bar").props()["value"]).toEqual(50.0);
      });

      it("the progress bar disappears after the submit button is clicked", () => {
        // simulate form submission
        wrapper.instance().onSubmit({preventDefault: jest.fn()});
        expect(mockOnSubmit).toHaveBeenCalled();
        wrapper.update();
        expect(wrapper.find(".modal-progress-bar").exists()).toBeFalsy();
      });
    });

    describe("when the progressVisible prop is initially false", () => {
      beforeEach(() => {
        wrapper = shallow(
          <SubmissionFileUploadModal
            progressVisible={false}
            progressPercentage={0.0}
            requiredFiles={[]}
            onSubmit={() => {}}
          />
        );
      });

      it("the progress bar is initially not visible", () => {
        expect(wrapper.find(".modal-progress-bar").exists()).toBeFalsy();
      });
    });
  });
});
