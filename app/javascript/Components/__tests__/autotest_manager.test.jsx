import React from "react";
import {render, screen, fireEvent, act} from "@testing-library/react";
import {AutotestManager} from "../autotest_manager";

jest.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => null,
}));

let mockFormOnChange;
jest.mock("@rjsf/core", () => {
  const React = require("react");
  const MockForm = React.forwardRef((props, ref) => {
    mockFormOnChange = props.onChange;
    React.useImperativeHandle(ref, () => ({validateForm: () => true}));
    return <form>{props.children}</form>;
  });
  MockForm.displayName = "MockForm";
  return {__esModule: true, default: MockForm};
});

jest.mock("@rjsf/utils", () => ({TranslatableString: {}}));
jest.mock("@rjsf/validator-ajv8", () => ({customizeValidator: () => ({})}));

jest.mock("react-flatpickr", () => {
  const React = require("react");
  const MockFlatpickr = ({id, value}) => <input id={id} type="text" readOnly value={value || ""} />;
  MockFlatpickr.displayName = "MockFlatpickr";
  return {__esModule: true, default: MockFlatpickr};
});

jest.mock("flatpickr/dist/plugins/labelPlugin/labelPlugin", () => () => ({}));

jest.mock("../markus_file_manager", () => ({__esModule: true, default: () => null}));
jest.mock("../Modals/file_upload_modal", () => ({__esModule: true, default: () => null}));
jest.mock("../Modals/autotest_specs_upload_modal", () => ({__esModule: true, default: () => null}));
jest.mock("../../common/flash", () => ({flashMessage: jest.fn()}));

const fetchPayload = {
  files: [],
  schema: {},
  formData: {},
  enable_test: true,
  enable_student_tests: true,
  token_start_date: "",
  token_end_date: "",
  tokens_per_period: 0,
  token_period: 0,
  non_regenerating_tokens: false,
  unlimited_tokens: false,
};

function renderManager() {
  return render(<AutotestManager course_id={1} assignment_id={1} validator={{}} />);
}

describe("AutotestManager navigation warning", () => {
  beforeEach(() => {
    fetch.mockReset();
    fetch.mockResolvedValue({ok: true, json: jest.fn().mockResolvedValue(fetchPayload)});
  });

  afterEach(() => {
    window.onbeforeunload = null;
  });

  it("does not warn when no changes have been made", () => {
    renderManager();
    expect(window.onbeforeunload()).toBeUndefined();
  });

  it("warns after a field is changed", () => {
    renderManager();
    fireEvent.click(screen.getAllByRole("checkbox")[0]);
    expect(window.onbeforeunload()).toBe(I18n.t("uncommitted_changes_warning"));
  });

  it("clears the warning after form is saved", async () => {
    renderManager();
    fireEvent.click(screen.getAllByRole("checkbox")[0]);
    expect(window.onbeforeunload()).toBe(I18n.t("uncommitted_changes_warning"));

    fetch.mockResolvedValueOnce({ok: true, json: jest.fn().mockResolvedValue({job_id: "1"})});
    await act(async () => {
      fireEvent.click(screen.getByRole("button", {name: I18n.t("save")}));
    });
    expect(window.onbeforeunload()).toBeUndefined();
  });

  it("does not mark dirty when rjsf fires onChange before fetch resolves", () => {
    renderManager();
    // formData is null until fetch resolves, so onChange is suppressed
    act(() => {
      mockFormOnChange({formData: {}});
    });
    expect(window.onbeforeunload()).toBeUndefined();
  });

  it("marks dirty when rjsf fires onChange after fetch resolves", async () => {
    renderManager();
    await act(async () => {}); // flush fetch promise, formData is now non-null

    act(() => {
      mockFormOnChange({formData: {testers: []}});
    });
    expect(window.onbeforeunload()).toBe(I18n.t("uncommitted_changes_warning"));
  });

  it("restores window.onbeforeunload to null on unmount", () => {
    const {unmount} = renderManager();
    expect(window.onbeforeunload).not.toBeNull();
    unmount();
    expect(window.onbeforeunload).toBeNull();
  });
});
