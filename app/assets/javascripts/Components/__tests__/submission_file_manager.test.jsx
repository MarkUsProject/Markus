import {SubmissionFileManager} from "../submission_file_manager";

import {mount} from "enzyme";

describe("For the submissions managed by SubmissionFileManager's FileManager child component", () => {
  let wrapper, rows;
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

  beforeEach(() => {
    // Unlike FileManager, files are stored in SubmissionFileManager's states, which are set when the component mounts
    // and calls fetchData. As a result, we need to mock that fetch to return our data.
    // We need to mock "twice" (i.e. two promises) because of how fetch works.
    fetch.resetMocks();
    fetch.mockResponseOnce(JSON.stringify(files_sample));
    wrapper = mount(<SubmissionFileManager course_id={1} assignment_id={1} />);

    // Mock the document to have a section called content so that renderFileViewer can be called.
    // We can do this because we have Jest running in jsdom environment as configured by our jest.config.js.
    // https://jestjs.io/docs/tutorial-jquery the shown code example is JQuery but equally applicable here.
    document.body.innerHTML = `<div id="content"></div>`;
  });

  it("clicking on the row of each file opens up the preview for that file", () => {
    wrapper.update();
    rows = wrapper.find(".file");
    expect(rows.length).toEqual(files_sample.entries.length);

    rows.forEach(row => {
      row.simulate("click");
      wrapper.update();

      // Locate the preview block
      const file_viewer_comp = wrapper.find("FileViewer");
      expect(file_viewer_comp).toBeTruthy();
    });
  });

  it("the preview opened is called with the correct props", () => {
    wrapper.update();
    rows = wrapper.find(".file");
    expect(rows.length).toEqual(files_sample.entries.length);

    rows.forEach(row => {
      row.simulate("click");
      wrapper.update();

      // Locate the preview block
      const file_viewer_comp = wrapper.find("FileViewer");
      const file_displayed = files_sample.entries.find(
        file => file.url === file_viewer_comp.props().selectedFileURL
      );

      expect(file_viewer_comp.props().selectedFile).toEqual(file_displayed.relativeKey);
      expect(file_viewer_comp.props().selectedFileType).toEqual(file_displayed.type);
    });
  });

  describe("For the uploadModalProgressPercentage state element", () => {
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

      // mock ajax call to prevent request from being sent
      $.ajax = jest.fn().mockImplementation(({xhr}) => {
        // call mock xhr send function to trigger onprogress handler
        xhr().send();

        // do nothing for any chain action after ajax() itself
        return {
          then: jest.fn().mockReturnThis(),
          fail: jest.fn().mockReturnThis(),
          always: jest.fn().mockReturnThis(),
        };
      });
    });

    it("when 50% of a file is uploaded, uploadModalProgressPercentage is 0.50", () => {
      // override our mock XMLHttpRequest's send method to send an onprogress
      // event with 50% completion
      mockXHR.send = jest.fn().mockImplementation(() => {
        mockXHR.upload.onprogress({
          lengthComputable: true,
          loaded: 5,
          total: 10,
        });
      });

      // call handleCreateFiles with dummy file
      wrapper.instance().handleCreateFiles([file], "", false);

      // verify percentage is correct
      expect(wrapper.state().uploadModalProgressPercentage).toEqual(50);
    });
  });
});
