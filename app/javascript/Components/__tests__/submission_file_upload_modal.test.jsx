import {fireEvent, render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import SubmissionFileUploadModal from "../Modals/submission_file_upload_modal";

describe("For the SubmissionFileUploadModal", () => {
  describe("The select element", () => {
    let rerender;
    beforeEach(() => {
      const rendered = render(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={true}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
        />
      );
      rerender = rendered.rerender;
    });

    it("renders the element if onlyRequiredFiles is true", () => {
      expect(
        screen.getByRole("combobox", {
          name: I18n.t("submissions.student.rename_file_to"),
          hidden: true,
        })
      ).toBeTruthy();
    });
    it("does not render the datalist and textbox elements if onlyRequiredFiles is true", () => {
      expect(
        screen.queryByRole("combobox", {name: I18n.t("submissions.student.rename_file_to")})
      ).toBeNull();
      expect(
        screen.queryByRole("textbox", {name: I18n.t("submissions.student.rename_file_to")})
      ).toBeNull();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      const element = screen.queryByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(element).toBeDisabled();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", async () => {
      const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
      fireEvent.change(fileInput, {
        target: {files: ["q1.py", "q2.py"]},
      });
      const filenameInput = await screen.findByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(filenameInput).toBeDisabled();
    });

    describe("length of newFiles in the state is 1", () => {
      beforeEach(() => {
        const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
        fireEvent.change(fileInput, {
          target: {files: ["main.py"]},
        });
      });
      it("enables the element", async () => {
        const filenameInput = await screen.findByRole("combobox", {
          name: I18n.t("submissions.student.rename_file_to"),
          hidden: true,
        });
        expect(filenameInput).toBeEnabled();
      });
      it("only shows the files required in the root directory if uploadTarget is null", async () => {
        const filenameInput = await screen.findByRole("combobox", {
          name: I18n.t("submissions.student.rename_file_to"),
          hidden: true,
        });
        const filenames = Array.from(filenameInput.options).map(obj => obj.textContent);

        expect(filenames).toEqual([I18n.t("select_filename"), "q1.py", "q2.py", "q3.py"]);
      });
      it("only shows the files in the activated directory if uploadTarget is not null", async () => {
        rerender(
          <SubmissionFileUploadModal
            isOpen={true}
            onlyRequiredFiles={true}
            requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
            uploadTarget={"part1/"}
          />
        );
        const filenameInput = await screen.findByRole("combobox", {
          name: I18n.t("submissions.student.rename_file_to"),
          hidden: true,
        });
        const filenames = Array.from(filenameInput.options).map(obj => obj.textContent);

        expect(filenames).toEqual([I18n.t("select_filename"), "p1.py"]);
      });
    });
  });

  describe("The datalist input element", () => {
    let rerender;
    beforeEach(() => {
      const rendered = render(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={false}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
        />
      );
      rerender = rendered.rerender;
    });
    it("renders the element if onlyRequiredFiles is false and requiredFiles is non empty", () => {
      const datalist = screen.queryByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
      });
      expect(datalist).toBeNull();
    });
    it("does not render the select and textbox elements if onlyRequiredFiles is false and requiredFiles is non empty", () => {
      expect(
        screen.queryByRole("combobox", {name: I18n.t("submissions.student.rename_file_to")})
      ).toBeNull();
      expect(
        screen.queryByRole("textbox", {name: I18n.t("submissions.student.rename_file_to")})
      ).toBeNull();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      const datalist = screen.queryByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(datalist).toBeDisabled();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", async () => {
      const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
      fireEvent.change(fileInput, {
        target: {files: ["q1.py", "q2.py"]},
      });

      const datalist = await screen.findByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(datalist).toBeDisabled();
    });
    describe("length of newFiles in the state is 1", () => {
      beforeEach(() => {
        const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
        fireEvent.change(fileInput, {
          target: {files: ["main.py"]},
        });
      });
      it("enables the element", async () => {
        const datalist = await screen.findByRole("combobox", {
          name: I18n.t("submissions.student.rename_file_to"),
          hidden: true,
        });
        expect(datalist).toBeEnabled();
      });
      it("only shows the files required in the root directory if uploadTarget is null", async () => {
        const optionsList = await screen.findByRole("listbox", {hidden: true});
        const filenames = Array.from(optionsList.children).map(obj => obj.value);
        expect(filenames).toEqual(["q1.py", "q2.py", "q3.py"]);
      });
      it("only shows the files in the activated directory if uploadTarget is not null", async () => {
        rerender(
          <SubmissionFileUploadModal
            isOpen={true}
            onlyRequiredFiles={false}
            requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
            uploadTarget={"part1/"}
          />
        );
        const optionsList = await screen.findByRole("listbox", {hidden: true});
        const filenames = Array.from(optionsList.children).map(obj => obj.value);
        expect(filenames).toEqual(["p1.py"]);
      });
    });
  });

  describe("The textbox element", () => {
    beforeEach(() => {
      render(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={false}
          requiredFiles={[]}
          uploadTarget={null}
        />
      );
    });
    it("renders the element if onlyRequiredFiles is false and requiredFiles is empty", () => {
      const datalist = screen.queryByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
      });
      expect(datalist).toBeNull();
    });
    it("does not render the select and datalist input elements if onlyRequiredFiles is false and requiredFiles is empty", () => {
      expect(
        screen.queryByRole("combobox", {name: I18n.t("submissions.student.rename_file_to")})
      ).toBeNull();
    });
    it("disables the element if the length of newFiles in the state is 0", () => {
      const datalist = screen.queryByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(datalist).toBeDisabled();
    });
    it("disables the element if the length of newFiles in the state is greater than 1", async () => {
      const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
      fireEvent.change(fileInput, {
        target: {files: ["q1.py", "q2.py"]},
      });

      const datalist = await screen.findByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(datalist).toBeDisabled();
    });
    it("enables the element if the length of newFiles in the state is 1", async () => {
      const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
      fireEvent.change(fileInput, {
        target: {files: ["q1.py"]},
      });
      const datalist = await screen.findByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      expect(datalist).toBeEnabled();
    });
  });

  describe("The onSubmit method", () => {
    // Mock onSubmit function
    const mockOnSubmit = jest.fn();
    let fileInput, renameToInput, submit;
    let rerender;

    beforeEach(() => {
      let renderer = render(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={true}
          requiredFiles={["q1.py", "q2.py", "q3.py", "part1/p1.py"]}
          uploadTarget={null}
          onSubmit={mockOnSubmit} // Pass the mocked onSubmit function
        />
      );
      rerender = renderer.rerender;

      fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
      renameToInput = screen.getByRole("combobox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });
      submit = screen.getByRole("button", {name: I18n.t("save"), hidden: true});
    });

    it("should call onSubmit prop with correct arguments when extensions match", async () => {
      await fireEvent.change(fileInput, {
        target: {files: [{name: "file.py"}]},
      });
      await userEvent.selectOptions(renameToInput, "q1.py");
      await userEvent.click(submit);

      // Ensure onSubmit is called with expected arguments
      expect(mockOnSubmit).toHaveBeenCalledWith([{name: "file.py"}], undefined, false, "q1.py");
    });

    it.only("should not call onSubmit prop when extensions don't match and user cancels", async () => {
      // Mock window.confirm to return false
      window.confirm = jest.fn(() => false);

      await fireEvent.change(fileInput, {
        target: {files: [{name: "file1.txt"}]},
      });
      await userEvent.selectOptions(renameToInput, "q1.py");
      await userEvent.click(submit);

      // Ensure onSubmit is not called
      expect(mockOnSubmit).not.toHaveBeenCalled();
    });

    it("should call onSubmit prop with correct arguments when extensions don't match and user confirms", async () => {
      // Mock window.confirm to return true
      window.confirm = jest.fn(() => true);

      // Mock setState method
      fireEvent.change(fileInput, {
        target: {files: [{name: "file2.txt"}]},
      });
      await userEvent.selectOptions(renameToInput, "q1.py");
      await userEvent.click(submit);

      // Ensure onSubmit is called with expected arguments
      expect(mockOnSubmit).toHaveBeenCalledWith([{name: "file2.txt"}], undefined, false, "q1.py");
    });

    it("should call onSubmit prop with correct arguments when rename input is left blank", async () => {
      rerender(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={false}
          requiredFiles={[]}
          uploadTarget={null}
          onSubmit={mockOnSubmit} // Pass the mocked onSubmit function
        />
      );
      // This input has changed to a text input
      renameToInput = await screen.findByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });

      await fireEvent.change(fileInput, {
        target: {files: [{name: "q1.py"}]},
      });
      await userEvent.clear(renameToInput);
      await userEvent.click(submit);

      expect(mockOnSubmit).toHaveBeenCalledWith([{name: "q1.py"}], undefined, false, "");
    });

    it("should call onSubmit prop with correct arguments when rename input consists only of whitespace", async () => {
      rerender(
        <SubmissionFileUploadModal
          isOpen={true}
          onlyRequiredFiles={false}
          requiredFiles={[]}
          uploadTarget={null}
          onSubmit={mockOnSubmit} // Pass the mocked onSubmit function
        />
      );
      // This input has changed to a text input
      renameToInput = await screen.findByRole("textbox", {
        name: I18n.t("submissions.student.rename_file_to"),
        hidden: true,
      });

      await fireEvent.change(fileInput, {
        target: {files: [{name: "file.py"}]},
      });
      await userEvent.type(renameToInput, "    ");
      await userEvent.click(submit);

      expect(mockOnSubmit).toHaveBeenCalledWith([{name: "file.py"}], undefined, false, "");
    });
  });

  describe("The progress bar", () => {
    describe("when the progressVisible prop is initially true and progressPercentage prop is 0.0", () => {
      let rerender;
      // for testing the behaviour of progress bar after submit
      let mockOnSubmit = jest.fn(() => {
        rerender(
          <SubmissionFileUploadModal
            isOpen={true}
            progressVisible={false}
            progressPercentage={0.0}
            requiredFiles={[]}
          />
        );
      });

      beforeEach(() => {
        const renderer = render(
          <SubmissionFileUploadModal
            isOpen={true}
            progressVisible={true}
            progressPercentage={0.0}
            requiredFiles={[]}
            onSubmit={mockOnSubmit}
          />
        );
        rerender = renderer.rerender;

        // to ensure submit button is enabled
        const fileInput = screen.getByTitle(I18n.t("modals.file_upload.file_input_label"));
        fireEvent.change(fileInput, {
          target: {files: ["q1.py", "q2.py"]},
        });
      });

      it("the progress bar is initially visible", async () => {
        await screen.findByRole("progressbar", {hidden: true});
      });

      it("the progress bar's value is initially 0.0", async () => {
        const progressBar = await screen.findByRole("progressbar", {hidden: true});
        expect(progressBar.value).toEqual(0.0);
      });

      it("the progress bar's value changes when the prop progressPercentage changes", async () => {
        rerender(
          <SubmissionFileUploadModal
            isOpen={true}
            progressVisible={true}
            progressPercentage={50.0}
            requiredFiles={[]}
            onSubmit={mockOnSubmit}
          />
        );
        const progressBar = await screen.findByRole("progressbar", {hidden: true});
        expect(progressBar.value).toEqual(50.0);
      });

      it("the progress bar disappears after the submit button is clicked", async () => {
        const submit = await screen.findByRole("button", {name: I18n.t("save"), hidden: true});
        fireEvent.click(submit);
        expect(mockOnSubmit).toHaveBeenCalled();
        await expect(screen.findByRole("progressbar", {hidden: true})).rejects.toThrow();
      });
    });

    describe("when the progressVisible prop is initially false", () => {
      beforeEach(() => {
        render(
          <SubmissionFileUploadModal
            isOpen={true}
            progressVisible={false}
            progressPercentage={0.0}
            requiredFiles={[]}
            onSubmit={() => {}}
          />
        );
      });

      it("the progress bar is initially not visible", async () => {
        await expect(screen.findByRole("progressbar", {hidden: true})).rejects.toThrow();
      });
    });
  });
});
