import {SubmissionFileManager} from "../submission_file_manager";

import {mount} from "enzyme";

describe("For the submissions managed by SubmissionFileManager's FileManager child component", () => {
  let wrapper;
  // TODO: check whether need to separate cases into img vs non img
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

  beforeAll(() => {
    // Unlike FileManager, files are stored in SubmissionFileManager's states, which are set when the component mounts
    // and calls fetchData. As a result, we need to mock that fetch to return our data.
    // We need to mock "twice" (i.e. two promises) because of how fetch works.
    window.fetch = jest.fn(() =>
      Promise.resolve({
        json: () => Promise.resolve(files_sample),
      })
    );
  });

  beforeEach(() => {
    wrapper = mount(<SubmissionFileManager course_id={1} assignment_id={1} />);

    // Mock the renderFileViewer as we don't care about its implementation.
    wrapper.instance().renderFileViewer = jest.fn();
  });

  // TODO: testing plan: here, we test that renderFileViewer is called;
  //  Then in another file, test that FileViewer generates the correct URL
  it("clicking on the row of each file opens up the preview for that file", () => {
    wrapper.update();

    const rows = wrapper.find(".file");
    // Make sure that all files are displayed .
    expect(rows.length).toEqual(2);

    rows.forEach(row => {
      row.simulate("click");
      wrapper.update();
      expect(wrapper.instance().renderFileViewer).toBeCalled();
    });
  });
});
