import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import EditTagModal from "../Modals/edit_tag_modal";
import Modal from "react-modal";
import fetchMock from "jest-fetch-mock";

describe("EditTagModal", () => {
  let props;
  let mockToken;
  let csrfToken;

  beforeAll(() => {
    mockToken = "mockToken";
    csrfToken = document.createElement("meta");
    csrfToken.name = "csrf-token";
    csrfToken.content = mockToken;
    document.head.appendChild(csrfToken);
  });

  beforeEach(() => {
    props = {
      course_id: 1,
      assignment_id: 1,
      tag_id: 1,
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
      currentTagName: "tag 1",
      currentTagDescription: "",
    };

    // Set the app element for React Modal
    Modal.setAppElement("body");
    render(<EditTagModal {...props} />);
  });

  afterEach(() => {
    fetchMock.resetMocks();
    jest.restoreAllMocks();
  });

  afterAll(() => {
    csrfToken.remove();
  });

  it("should be called with correct params on successful submit", async () => {
    const updatedName = "updated tag";
    const updatedDescription = "updated description";
    fireEvent.change(screen.getByTestId("tag_name_input"), {target: {value: updatedName}});
    fireEvent.change(screen.getByTestId("tag_description_input"), {
      target: {value: updatedDescription},
    });
    const data = {
      tag: {
        name: updatedName,
        description: updatedDescription,
      },
      course_id: props.course_id,
      id: props.tag_id,
      submit: "Save",
    };
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": mockToken,
      },
      body: JSON.stringify(data),
    };
    fetchMock.mockOnce(async req => {
      expect(req.url).toEqual(Routes.course_tag_path(props.course_id, props.tag_id));
      expect(req.method).toBe(options.method);
      expect(req.headers.get("Content-Type")).toEqual(options.headers["Content-Type"]);
      expect(req.headers.get("X-CSRF-Token")).toEqual(options.headers["X-CSRF-Token"]);
      expect(await req.json()).toEqual(data);

      return JSON.stringify({status: "success"});
    });

    fireEvent.click(screen.getByText(I18n.t("save")));
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });
  });

  it("should call onRequestClose on successful submit", async () => {
    fireEvent.click(screen.getByText(I18n.t("save")));
    await waitFor(() => {
      expect(props.onRequestClose).toHaveBeenCalledTimes(1);
    });
  });

  it("should initialize both inputs from the current tag", () => {
    expect(screen.getByTestId("tag_name_input")).toHaveValue(props.currentTagName);
    expect(screen.getByTestId("tag_description_input")).toHaveValue(props.currentTagDescription);
  });

  it("should console error on error", async () => {
    const customError = new Error();
    customError.message = "msg";
    fetchMock.mockRejectOnce(customError);
    const mockedConsoleError = jest.spyOn(global.console, "error").mockImplementation(() => {});
    fireEvent.click(screen.getByText(I18n.t("save")));
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(mockedConsoleError).toHaveBeenNthCalledWith(1, customError.message);
      expect(props.onRequestClose).not.toHaveBeenCalled();
    });
  });
});
