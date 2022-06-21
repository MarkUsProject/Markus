import {SubmissionFileManager} from "../submission_file_manager";

import {mount} from "enzyme";

describe("For the submissions managed by SubmissionFileManager's FileManager child component", () => {
  let wrapper, rows;
  const files_sample = [
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
  ];

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
    expect(rows.length).toEqual(files_sample.length);

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
    expect(rows.length).toEqual(files_sample.length);

    rows.forEach(row => {
      row.simulate("click");
      wrapper.update();

      // Locate the preview block
      const file_viewer_comp = wrapper.find("FileViewer");
      const file_displayed = files_sample.find(
        file => file.url === file_viewer_comp.props().selectedFileURL
      );

      expect(file_viewer_comp.props().selectedFile).toEqual(file_displayed.relativeKey);
      expect(file_viewer_comp.props().selectedFileType).toEqual(file_displayed.type);
    });
  });
});
