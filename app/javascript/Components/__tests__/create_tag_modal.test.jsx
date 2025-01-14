import React from "react";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import CreateTagModal from "../Modals/create_tag_modal";
import Modal from "react-modal";
import fetchMock from "jest-fetch-mock";
import {ResultContext} from "../Result/result_context";
import {DEFAULT_RESULT_CONTEXT_VALUE, renderInResultContext} from "./result_context_renderer";

describe("CreateTagModal", () => {
  let props;
  let component;
  let mockToken;
  let tagName;

  beforeAll(() => {
    mockToken = "mockToken";
    document.querySelector = jest.fn(() => ({
      content: mockToken, // Return a mock value for the content property
    }));
  });

  beforeEach(() => {
    props = {
      isOpen: true,
      onRequestClose: jest.fn().mockImplementation(() => (props.isOpen = false)),
    };

    // Set the app element for React Modal
    Modal.setAppElement("body");

    component = renderInResultContext(<CreateTagModal {...props} />, {role: "Student"});

    // Enable submit
    tagName = "Name";
    fireEvent.change(screen.getByTestId("tag_name_input"), {target: {value: tagName}});
  });

  afterEach(() => {
    fetchMock.resetMocks();
  });

  it("should be called with correct params on successful submit", async () => {
    fireEvent.change(screen.getByTestId("tag_name_input"), {target: {value: tagName}});
    const data = {
      tag: {
        name: tagName,
        description: "",
      },
      grouping_id: DEFAULT_RESULT_CONTEXT_VALUE.grouping_id,
    };
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": mockToken,
      },
      body: JSON.stringify(data),
    };
    fetchMock.mockOnce(async req => {
      expect(req.url).toEqual(
        Routes.course_tags_path(DEFAULT_RESULT_CONTEXT_VALUE.course_id, {
          assignment_id: DEFAULT_RESULT_CONTEXT_VALUE.assignment_id,
        })
      );
      expect(req.method).toBe(options.method);
      expect(req.headers.get("Content-Type")).toEqual(options.headers["Content-Type"]);
      expect(req.headers.get("X-CSRF-Token")).toEqual(options.headers["X-CSRF-Token"]);

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

  it("should console error on error", async () => {
    const customError = new Error();
    customError.message = "msg";
    fetchMock.mockRejectOnce(customError);
    const mockedConsoleError = jest.spyOn(global.console, "error").mockImplementation(() => {});
    fireEvent.click(screen.getByText(I18n.t("save")));
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(mockedConsoleError).toHaveBeenNthCalledWith(
        1,
        `Error submitting form: ${customError.message}`
      );
    });
  });
});
