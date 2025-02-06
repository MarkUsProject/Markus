import {SubmissionFileManager} from "../submission_file_manager";

import {getAllByRole, waitFor, render, screen} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

describe("For the SubmissionFileManager", () => {
  const files_sample = {
    entries: [
      {
        id: 136680,
        url: "test.url",
        filename: '<img src="" /><a href=""> HelloWorld.java</a>',
        raw_name: "HelloWorld.java",
        last_revised_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
        last_modified_revision: "58ca2e15254aa63c4d41cb5db7dfc398b6bda3fb",
        revision_by: "c5anthei",
        submitted_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
        type: "java",
        key: "HelloWorld.java",
        modified: 1652577324,
        relativeKey: "HelloWorld.java",
      },
      {
        id: 136700,
        url: "test2.url",
        filename: '<img src="" /><a href=""> deferred-process.java</a>',
        raw_name: "deferred-process.java",
        last_revised_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
        last_modified_revision: "58ca2e15254aa63c4d41cb5db7dfc398b6bda3fb",
        revision_by: "c5anthei",
        submitted_date: "Saturday, May 14, 2022, 09:15:24 PM EDT",
        type: "java",
        key: "deferred-process.java",
        modified: 1652577324,
        relativeKey: "deferred-process.java",
      },
    ],
    only_required_files: false,
    required_files: [],
  };

  beforeEach(async () => {
    // Unlike FileManager, files are stored in SubmissionFileManager's states, which are set when the component mounts
    // and calls fetchData. As a result, we need to mock that fetch to return our data.
    // We need to mock "twice" (i.e. two promises) because of how fetch works.
    fetch.resetMocks();
    fetch.mockResponseOnce(JSON.stringify(files_sample));

    // Mock the document to have a section called content so that renderFileViewer can be called.
    // We can do this because we have Jest running in jsdom environment as configured by our jest.config.js.
    // https://jestjs.io/docs/tutorial-jquery the shown code example is JQuery but equally applicable here.
    document.body.innerHTML = `<div id="content"></div>`;

    // Render the component
    render(<SubmissionFileManager course_id={1} assignment_id={1} />);
    await screen.findByText("HelloWorld.java");
    await screen.findByText("deferred-process.java");
  });

  describe("For the submissions managed by its FileManager child component", () => {
    it("clicking on the row of each file opens up the preview for that file", async () => {
      const rows = getAllByRole(screen.getAllByRole("rowgroup")[1], "row"); // The second rowgroup corresponds to the tbody
      expect(rows.length).toEqual(files_sample.entries.length);

      expect(screen.queryByTestId("file-preview-root")).toBeNull(); // Initially no preview is shown

      for (let row of rows) {
        await userEvent.click(row);

        const filePreview = await screen.findByTestId("file-preview-root");
        expect(filePreview).toBeTruthy();
      }
    });

    it("the preview opened is with the correct contents", async () => {
      const rows = getAllByRole(screen.getAllByRole("rowgroup")[1], "row"); // The second rowgroup corresponds to the tbody
      expect(rows.length).toEqual(files_sample.entries.length);

      for (let i = 0; i < rows.length; i++) {
        fetch.mockResponseOnce(`Body ${i}`);
        await userEvent.click(rows[i]);

        const filePreview = await screen.findByTestId("file-preview-root");
        await waitFor(() => expect(filePreview.textContent).toContain(`Body ${i}`));
      }
    });
  });

  describe("For the upload modal's progress bar", () => {
    let file, mockXHR;
    beforeEach(() => {
      // a dummy file
      file = new File(["content"], "test.txt", {type: "text/plain"});

      // Mock the XMLHttpRequest object
      mockXHR = {
        upload: {
          addEventListener: jest.fn((event, callback) => {
            if (event === "progress") {
              mockXHR.upload.onprogress = callback;
            }
          }),
        },
      };

      // Override XMLHttpRequest constructor to return our mock request instead
      jest.spyOn(window, "XMLHttpRequest").mockImplementation(() => mockXHR);

      // mock ajax post call to prevent request from being sent
      $.post = jest.fn().mockImplementation(({xhr}) => {
        // call mock xhr send function to trigger onprogress handler
        xhr().send();

        // do nothing for any chain action after $.post() itself
        return {
          then: jest.fn().mockReturnThis(),
          fail: jest.fn().mockReturnThis(),
          always: jest.fn().mockReturnThis(),
        };
      });
    });

    it("when 10% of file uploaded, bar is visible and has value of 10.0", async () => {
      // override our mock XMLHttpRequest's send method to send an onprogress
      // event with 10% completion
      mockXHR.send = jest.fn().mockImplementation(() => {
        mockXHR.upload.onprogress({
          lengthComputable: true,
          loaded: 1,
          total: 10,
        });
      });

      const submitLink = screen.getByText(I18n.t("submit_the", {item: I18n.t("file")}));
      await userEvent.click(submitLink);
      await userEvent.upload(screen.getByTitle(I18n.t("modals.file_upload.file_input_label")), [
        file,
      ]);
      await userEvent.click(screen.getByRole("button", {name: I18n.t("save"), hidden: true}));

      const progressBar = await screen.findByRole("progressbar", {hidden: true});
      expect(progressBar.value).toEqual(10.0);
    });

    it("when 50% of file uploaded, bar is visible and has value of 50.0", async () => {
      // override our mock XMLHttpRequest's send method to send an onprogress
      // event with 50% completion
      mockXHR.send = jest.fn().mockImplementation(() => {
        mockXHR.upload.onprogress({
          lengthComputable: true,
          loaded: 5,
          total: 10,
        });
      });

      const submitLink = screen.getByText(I18n.t("submit_the", {item: I18n.t("file")}));
      await userEvent.click(submitLink);
      await userEvent.upload(screen.getByTitle(I18n.t("modals.file_upload.file_input_label")), [
        file,
      ]);
      await userEvent.click(screen.getByRole("button", {name: I18n.t("save"), hidden: true}));

      const progressBar = await screen.findByRole("progressbar", {hidden: true});
      expect(progressBar.value).toEqual(50.0);
    });

    it("when 100% of file uploaded, bar is visible and has value of 100.0", async () => {
      // override our mock XMLHttpRequest's send method to send an onprogress
      // event with 100% completion
      mockXHR.send = jest.fn().mockImplementation(() => {
        mockXHR.upload.onprogress({
          lengthComputable: true,
          loaded: 10,
          total: 10,
        });
      });

      const submitLink = screen.getByText(I18n.t("submit_the", {item: I18n.t("file")}));
      await userEvent.click(submitLink);
      await userEvent.upload(screen.getByTitle(I18n.t("modals.file_upload.file_input_label")), [
        file,
      ]);
      await userEvent.click(screen.getByRole("button", {name: I18n.t("save"), hidden: true}));

      const progressBar = await screen.findByRole("progressbar", {hidden: true});
      expect(progressBar.value).toEqual(100.0);
    });

    it("after a file is uploaded, bar is no longer visible and its value is reset to 0.0", async () => {
      // override existing mock implementation to allow always() to run
      $.post = jest.fn().mockReturnValue({
        then: jest.fn().mockReturnThis(),
        fail: jest.fn().mockReturnThis(),
        always: jest.fn().mockImplementation(func => {
          // allow func to run
          func();
          return this;
        }),
      });

      const submitLink = screen.getByText(I18n.t("submit_the", {item: I18n.t("file")}));
      await userEvent.click(submitLink);
      await userEvent.upload(screen.getByTitle(I18n.t("modals.file_upload.file_input_label")), [
        file,
      ]);
      await userEvent.click(screen.getByRole("button", {name: I18n.t("save"), hidden: true}));

      expect(screen.findByRole("progressbar", {hidden: true})).rejects.toThrow();
    });
  });
});
