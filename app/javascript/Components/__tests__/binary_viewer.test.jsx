import React from "react";
import {render, screen, waitFor, fireEvent} from "@testing-library/react";
import {BinaryViewer} from "../Result/binary_viewer";
import fetchMock from "jest-fetch-mock";

describe("BinaryViewer", () => {
  const successfulFetchResp = "File content";
  const loadingCallback = jest.fn();
  const errorCallback = jest.fn();
  const props = {
    url: "/",
    annotations: [],
    focusLine: null,
    submission_file_id: 1,
    setLoadingCallback: loadingCallback,
    setErrorMessageCallback: errorCallback,
  };

  afterEach(() => {
    jest.clearAllMocks();
    fetchMock.resetMocks();
  });

  it("should fetch content when a URL is passed but not show it until requested by the user", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    render(<BinaryViewer {...props} />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });

    expect(screen.queryByText(successfulFetchResp)).not.toBeInTheDocument();
    expect(screen.getByText(I18n.t("submissions.get_anyway"))).toBeInTheDocument();
    fireEvent.click(screen.getByText(I18n.t("submissions.get_anyway")));
    await screen.findByText(successfulFetchResp);
    expect(screen.queryByText(I18n.t("submissions.get_anyway"))).not.toBeInTheDocument();
  });

  it("should call loading callbacks before and after loading", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    render(<BinaryViewer {...props} />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);

      expect(loadingCallback.mock.calls).toHaveLength(2);
      expect(loadingCallback.mock.calls[0][0]).toBe(true);
      expect(loadingCallback.mock.calls[1][0]).toBe(false);

      expect(errorCallback.mock.calls).toHaveLength(0);
    });
  });

  it("should call an error callback when the requested file content is too large", async () => {
    fetchMock.mockOnce({}, {status: 413});

    render(<BinaryViewer {...props} />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(errorCallback.mock.calls).toHaveLength(1);
      expect(errorCallback.mock.calls[0][0]).toEqual(
        I18n.t("submissions.oversize_submission_file")
      );

      expect(loadingCallback.mock.calls).toHaveLength(2);
      expect(loadingCallback.mock.calls[0][0]).toBe(true);
      expect(loadingCallback.mock.calls[1][0]).toBe(false);
    });
  });

  it("should console error on error", async () => {
    const fetchError = new Error("fetch error");
    fetchMock.mockRejectOnce(fetchError);

    render(<BinaryViewer {...props} />);

    const mockedConsoleError = jest.spyOn(global.console, "error").mockImplementation(() => {});

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(mockedConsoleError).toHaveBeenCalledWith(fetchError);
    });
  });

  it("should not perform a fetch request if the URL hasn't changed", async () => {
    fetchMock.mockOnce(successfulFetchResp);
    const {rerender} = await render(<BinaryViewer {...props} />);
    await rerender(<BinaryViewer {...props} submission_file_id={props.submission_file_id + 1} />);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("should render on the same component that doesn't remount on prop update", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    const {rerender} = await render(<BinaryViewer {...props} />);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(screen.queryByText(successfulFetchResp)).not.toBeInTheDocument();
    expect(screen.getByText(I18n.t("submissions.get_anyway"))).toBeInTheDocument();

    await fireEvent.click(screen.getByText(I18n.t("submissions.get_anyway")));
    await screen.findByText(successfulFetchResp);

    expect(screen.getByText(successfulFetchResp)).toBeInTheDocument();
    expect(screen.queryByText(I18n.t("submissions.get_anyway"))).not.toBeInTheDocument();

    // Prepare a different fetch response to test component rerender
    fetchMock.mockOnce(successfulFetchResp.repeat(2));

    await rerender(<BinaryViewer {...props} url={"/double"} />);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(screen.queryByText(successfulFetchResp)).not.toBeInTheDocument();
    expect(screen.queryByText(successfulFetchResp.repeat(2))).not.toBeInTheDocument();
    expect(screen.getByText(I18n.t("submissions.get_anyway"))).toBeInTheDocument();

    await fireEvent.click(screen.getByText(I18n.t("submissions.get_anyway")));
    await screen.findByText(successfulFetchResp);

    await screen.findByText(successfulFetchResp.repeat(2));
    expect(screen.queryByText(successfulFetchResp)).not.toBeInTheDocument();
    expect(screen.queryByText(I18n.t("submissions.get_anyway"))).not.toBeInTheDocument();
  });
});
