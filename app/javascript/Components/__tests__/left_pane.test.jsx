import React from "react";
import {render} from "@testing-library/react";
import {LeftPane} from "../Result/left_pane";
import {renderInResultContext} from "./result_context_renderer";

jest.mock("../Result/annotation_panel", () => ({AnnotationPanel: () => <div />}));
jest.mock("../Result/feedback_file_panel", () => ({FeedbackFilePanel: () => <div />}));
jest.mock("../Result/remark_panel", () => ({RemarkPanel: () => <div />}));
jest.mock("../test_run_table", () => ({TestRunTable: () => <div />}));
jest.mock("../Result/submission_file_panel", () => {
  const React = require("react");
  const MockSubmissionFilePanel = React.forwardRef((props, ref) => {
    React.useImperativeHandle(ref, () => ({selectFile: jest.fn()}));
    return null;
  });
  MockSubmissionFilePanel.displayName = "MockSubmissionFilePanel";
  return {SubmissionFilePanel: MockSubmissionFilePanel};
});

const flatFileData = {
  files: [
    ["report.pdf", 1, "pdf"],
    ["notes.txt", 2, "text"],
  ],
  directories: {},
  name: "",
  path: [],
};

const nestedFileData = {
  files: [["root.pdf", 1, "pdf"]],
  directories: {
    subdir: {
      files: [["image.png", 2, "image"]],
      directories: {
        nested: {
          files: [["data.csv", 3, "text"]],
          directories: {},
          name: "nested",
          path: ["subdir", "nested"],
        },
      },
      name: "subdir",
      path: ["subdir"],
    },
  },
  name: "",
  path: [],
};

const basicProps = {
  loading: false,
  allow_remarks: false,
  annotation_categories: [],
  annotations: [],
  assignment_remark_message: "",
  update_overall_comment: jest.fn(),
  can_run_tests: false,
  detailed_annotations: false,
  enable_test: false,
  feedback_files: [],
  instructor_run: false,
  overall_comment: "",
  past_remark_due_date: false,
  released_to_students: false,
  remark_due_date: null,
  remark_overall_comment: "",
  remark_request_text: "",
  remark_request_timestamp: null,
  remark_submitted: false,
  revision_identifier: "1",
  submission_files: flatFileData,
  student_view: false,
  newAnnotation: jest.fn(),
  addExistingAnnotation: jest.fn(),
  editAnnotation: jest.fn(),
  removeAnnotation: jest.fn(),
  rmd_convert_enabled: false,
};

describe("LeftPane", () => {
  describe("getFileTypeById", () => {
    let leftPaneRef;

    beforeEach(() => {
      leftPaneRef = React.createRef();
      renderInResultContext(<LeftPane ref={leftPaneRef} {...basicProps} />);
    });

    it("returns the file type for a file at the root level", () => {
      expect(leftPaneRef.current.getFileTypeById(flatFileData, 1)).toBe("pdf");
      expect(leftPaneRef.current.getFileTypeById(flatFileData, 2)).toBe("text");
    });

    it("returns the file type for a file in a nested subdirectory", () => {
      expect(leftPaneRef.current.getFileTypeById(nestedFileData, 2)).toBe("image");
      expect(leftPaneRef.current.getFileTypeById(nestedFileData, 3)).toBe("text");
    });

    it("returns null when no file with the given id exists", () => {
      expect(leftPaneRef.current.getFileTypeById(flatFileData, 3)).toBeNull();
    });
  });

  describe("selectFile", () => {
    it("passes the file type for a file at the root level", () => {
      const leftPaneRef = React.createRef();
      renderInResultContext(
        <LeftPane ref={leftPaneRef} {...basicProps} submission_files={flatFileData} />
      );

      leftPaneRef.current.selectFile("report.pdf", 1, undefined, 42);

      expect(leftPaneRef.current.submissionFilePanel.current.selectFile).toHaveBeenCalledWith(
        "report.pdf",
        1,
        "pdf",
        undefined,
        42
      );
    });

    it("passes the correct file type for a file in a nested subdirectory", () => {
      const leftPaneRef = React.createRef();
      renderInResultContext(
        <LeftPane ref={leftPaneRef} {...basicProps} submission_files={nestedFileData} />
      );

      leftPaneRef.current.selectFile("subdir/image.png", 2, undefined, 42);

      expect(leftPaneRef.current.submissionFilePanel.current.selectFile).toHaveBeenCalledWith(
        "subdir/image.png",
        2,
        "image",
        undefined,
        42
      );
    });
  });
});
