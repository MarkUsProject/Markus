import React from "react";
import {render, screen, waitFor} from "@testing-library/react";
import {TextViewer} from "../Result/text_viewer";
import fetchMock from "jest-fetch-mock";
import userEvent from "@testing-library/user-event";
import {BinaryViewer} from "../Result/binary_viewer";

describe("TextViewer", () => {
  const successfulFetchResp = "File content";
  const loadingCallback = jest.fn();
  const errorCallback = jest.fn();
  const getItemMock = jest.spyOn(Storage.prototype, "getItem");
  const props = {
    annotations: [],
    focusLine: null,
    submission_file_id: 1,
    setLoadingCallback: loadingCallback,
    setErrorMessageCallback: errorCallback,
  };

  afterEach(() => {
    jest.clearAllMocks();
    fetchMock.resetMocks();
    getItemMock.mockReset();
  });

  it("should save font size to localStorage when font size change", async () => {
    jest.spyOn(Storage.prototype, "setItem");

    render(<TextViewer {...props} />);
    userEvent.click(screen.getByText("+A"));

    await waitFor(() => {
      expect(localStorage.setItem).toHaveBeenCalledWith("text_viewer_font_size", 1.25);
    });
  });

  it("should render using font size from localStorage", async () => {
    getItemMock.mockReturnValue("3");

    const {container} = render(<TextViewer {...props} />);
    const element = container.querySelector(".line-numbers");

    await waitFor(() => {
      expect(element).toHaveStyle("font-size: 3em");
    });
  });

  it("should render its text content when the content ends with a new line", () => {
    render(<TextViewer {...props} content={"def f(n: int) -> int:\n    return n + 1\n"} />);

    expect(screen.getByText("def f(n: int) -> int:")).toBeInTheDocument();
  });

  it("should render its text content when the content doesn't end with a new line", () => {
    render(<TextViewer {...props} content={"def f(n: int) -> int:"} />);

    expect(screen.getByText("def f(n: int) -> int:")).toBeInTheDocument();
  });

  it("should fetch content when a URL is passed", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    render(<TextViewer {...props} url={"/"} />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(screen.getByText(successfulFetchResp)).toBeInTheDocument();
    });
  });

  it("should call loading callbacks before and after loading", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    render(<TextViewer {...props} url={"/"} />);

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

    render(<TextViewer {...props} url={"/"} />);

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

    render(<TextViewer {...props} url={"/"} />);

    const mockedConsoleError = jest.spyOn(global.console, "error").mockImplementation(() => {});

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(mockedConsoleError).toHaveBeenCalledWith(fetchError);
    });
  });

  it("should not perform a fetch request if the URL hasn't changed", async () => {
    fetchMock.mockOnce(successfulFetchResp);
    const {rerender} = await render(<TextViewer {...props} url={"/"} />);
    await rerender(<TextViewer {...props} url={"/"} />);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("should render on the same component that doesn't remount on prop update", async () => {
    fetchMock.mockOnce(successfulFetchResp);

    const {rerender} = await render(<TextViewer {...props} url={"/"} />);
    await screen.findByText(successfulFetchResp);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(screen.getByText(successfulFetchResp)).toBeInTheDocument();

    // Prepare a different fetch response to test component rerender
    fetchMock.mockOnce(successfulFetchResp.repeat(2));

    await rerender(<TextViewer {...props} url={"/double"} />);
    await screen.findByText(successfulFetchResp.repeat(2));

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(screen.queryByText(successfulFetchResp)).not.toBeInTheDocument();
    expect(screen.getByText(successfulFetchResp.repeat(2))).toBeInTheDocument();
  });
});
