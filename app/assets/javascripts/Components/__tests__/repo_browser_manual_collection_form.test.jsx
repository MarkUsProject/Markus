import {render, screen, fireEvent} from "@testing-library/react";
import {ManualCollectionForm} from "../repo_browser";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => {
    return null;
  },
}));

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

    component = render(<ManualCollectionForm {...props} />);
  });

  it("shows the option to retain existing grading when there is a collected revision present", () => {
    const lblRecollectExistingSubmissions = screen.getByTestId("lbl_retain_existing_grading");
    const chkRecollectExistingSubmissions = screen.getByTestId("chk_retain_existing_grading");

    expect(lblRecollectExistingSubmissions).toBeVisible();
    expect(chkRecollectExistingSubmissions).toBeVisible();
  });

  it("does not show the option to retain existing grading when there is a not collected revision present", () => {
    props.collected_revision_id = "";
    component.rerender(<ManualCollectionForm {...props} />);

    const lblRecollectExistingSubmissions = screen.queryByTestId("lbl_retain_existing_grading");
    const chkRecollectExistingSubmissions = screen.queryByTestId("chk_retain_existing_grading");

    expect(lblRecollectExistingSubmissions).not.toBeVisible();
    expect(chkRecollectExistingSubmissions).not.toBeVisible();
  });

  it("should confirm with a full overwrite warning when retain existing grading option is checked", () => {
    const confirmSpy = jest.spyOn(window, "confirm").mockImplementation(() => false);
    const manualCollectionForm = component.getByTestId("form_manual_collection");

    fireEvent.submit(manualCollectionForm);

    expect(confirmSpy).toHaveBeenCalledWith(
      I18n.t("submissions.collect.confirm_recollect_retain_data")
    );
  });

  it("should confirm with a full overwrite warning when retain existing grading option is not checked", () => {
    const confirmSpy = jest.spyOn(window, "confirm").mockImplementation(() => false);
    const chkRecollectExistingSubmissions = screen.queryByTestId("chk_retain_existing_grading");
    const manualCollectionForm = component.getByTestId("form_manual_collection");

    fireEvent.click(chkRecollectExistingSubmissions);
    fireEvent.submit(manualCollectionForm);

    expect(confirmSpy).toHaveBeenCalledWith(I18n.t("submissions.collect.full_overwrite_warning"));
  });
});
