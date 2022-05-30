import {mount} from "enzyme";
import {FileViewer} from "../Result/file_viewer";

describe("The FileViewer component", () => {
  let wrapper;

  beforeAll(() => {
    window.fetch = jest.fn(() =>
      Promise.resolve({
        json: () => Promise.resolve([]),
      })
    );
  });

  beforeEach(() => {
    // wrapper = mount(<FileViewer course_id={1} assignment_id={2} grouping_id={91} mime_type={"image/jpeg"}
    //                             submission_id={1} selectedFileType={"image"} selectedFileURL={"fake.url"}/>);
    wrapper = mount(<FileViewer course_id={1} assignment_id={2} submission_id={1} />);
  });

  // TODO: figure out how to test whether the correct URL is returned
  it("generates the correct URL based on the props", () => {
    // wrapper.update()
    // console.log(wrapper.instance().state)
    // expect(wrapper.instance().state.url).toEqual("/csc108/courses/1/results/1/download?select_file_id=1&show_in_browser=true&from_codeviewer=true")
    // TODO: placeholder
    expect(1).toEqual(1);
  });
});
