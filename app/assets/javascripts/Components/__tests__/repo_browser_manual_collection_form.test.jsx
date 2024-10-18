import * as React from "react";
import {render, screen} from "@testing-library/react";
import {ManualCollectionForm} from "../repo_browser";

describe("RepoBrowser's ManualCollectionForm", () => {
  let props, component;

  beforeEach(() => {
    props = {
      course_id: 1,
      assignment_id: 2,
      late_penalty: false,
      grouping_id: 1,
      revision_identifier: "test",
      collected_revision_id: "test",
    };

    // Set the app element for React Modal
    component = render(<ManualCollectionForm {...props} />);
  });

  it("shows the option to retain existing grading when there is a collected revision present", () => {
    const lblRecollectExistingSubmissions = screen.getByTestId("lbl_retain_existing_grading");
    const chkRecollectExistingSubmissions = screen.getByTestId("chk_retain_existing_grading");

    expect(lblRecollectExistingSubmissions).toBeInTheDocument();
    expect(chkRecollectExistingSubmissions).toBeInTheDocument();
  });

  it("does not show the option to retain existing grading when there is a not collected revision present", () => {
    props.collected_revision_id = "";
    component.rerender(<ManualCollectionForm {...props} />);

    const lblRecollectExistingSubmissions = screen.queryByTestId("lbl_retain_existing_grading");
    const chkRecollectExistingSubmissions = screen.queryByTestId("chk_retain_existing_grading");

    expect(lblRecollectExistingSubmissions).not.toBeInTheDocument();
    expect(chkRecollectExistingSubmissions).not.toBeInTheDocument();
  });
});
