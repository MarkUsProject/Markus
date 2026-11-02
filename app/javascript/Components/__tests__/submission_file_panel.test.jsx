import {act, render} from "@testing-library/react";
import {SubmissionFilePanel} from "../Result/submission_file_panel";

// Record the URL every render hands to the viewer.
const viewerUrls = [];
jest.mock("../Result/file_viewer", () => ({
  FileViewer: props => {
    viewerUrls.push(props.selectedFileURL);
    return null;
  },
}));
jest.mock("../Result/file_selector", () => ({FileSelector: () => null}));

const fileData = id => ({
  files: [
    ["COVER.pdf", id, "pdf"],
    ["Q1.pdf", id + 1, "pdf"],
  ],
  directories: {},
  name: "",
  path: [],
});

const panelProps = overrides => ({
  course_id: 1,
  assignment_id: 1,
  result_id: 10,
  submission_id: 100,
  fileData: fileData(1000),
  annotations: [],
  loading: false,
  canDownload: false,
  ...overrides,
});

// The URL pairs a submission with a file id; only the submission's own files exist there.
const urlFor = (submission_id, file_id) =>
  expect.stringMatching(
    new RegExp(`/submissions/${submission_id}/download_file\\?select_file_id=${file_id}&`)
  );

describe("SubmissionFilePanel", () => {
  let ref;
  let rerenderPanel;

  beforeEach(() => {
    viewerUrls.length = 0;
    localStorage.clear();
    global.ModalMarkus = jest.fn();
    ref = React.createRef();
    const {rerender} = render(<SubmissionFilePanel ref={ref} {...panelProps()} />);
    rerenderPanel = overrides =>
      rerender(<SubmissionFilePanel ref={ref} {...panelProps(overrides)} />);
  });

  afterEach(() => {
    delete global.ModalMarkus;
  });

  // Mirrors Result#nextSubmission: the new ids arrive while loading, before the new files.
  const switchSubmission = () => {
    rerenderPanel({loading: true});
    rerenderPanel({loading: true, result_id: 11, submission_id: 200});
    rerenderPanel({loading: false, result_id: 11, submission_id: 200, fileData: fileData(2000)});
  };

  it("requests the first file of the submission", () => {
    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(100, 1000));
  });

  it("requests the new submission's file after a switch", () => {
    switchSubmission();

    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(200, 2000));
  });

  it("never pairs the new submission with the previous submission's file", () => {
    switchSubmission();

    viewerUrls.forEach(url => expect(url).not.toEqual(urlFor(200, 1000)));
  });

  it("keeps the previous submission's file while the new submission's files load", () => {
    rerenderPanel({loading: true, result_id: 11, submission_id: 200});

    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(100, 1000));
  });

  it("requests a file picked mid-switch from the submission it belongs to", () => {
    rerenderPanel({loading: true, result_id: 11, submission_id: 200});
    act(() => ref.current.selectFile("Q1.pdf", 1001, "pdf"));

    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(100, 1001));
  });

  it("requests a file picked by the user", () => {
    act(() => ref.current.selectFile("Q1.pdf", 1001, "pdf"));

    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(100, 1001));
  });

  it("keeps the picked file name across a switch", () => {
    act(() => ref.current.selectFile("Q1.pdf", 1001, "pdf"));
    switchSubmission();

    expect(viewerUrls[viewerUrls.length - 1]).toEqual(urlFor(200, 2001));
  });
});
