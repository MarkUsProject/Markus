import {render, screen, waitFor} from "@testing-library/react";
import {ImageViewer} from "../Result/image_viewer";

jest.mock("heic-convert/browser", () => ({
  __esModule: true,
  default: jest.fn(() => Promise.resolve(new Uint8Array([1, 2, 3]))),
}));

describe("ImageViewer", () => {
  let mockFetch;
  let mockCreateObjectURL;
  let props;

  beforeEach(() => {
    mockFetch = jest.fn(() =>
      Promise.resolve({
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(3)),
      })
    );

    mockCreateObjectURL = jest.fn(() => "blob:mock-url");

    global.fetch = mockFetch;
    global.URL.createObjectURL = mockCreateObjectURL;

    props = {
      url: "/image",
    };
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("sets image URLs", () => {
    it("creates a blob URL for HEIC images", async () => {
      render(<ImageViewer {...props} mime_type="image/heic" />);

      await waitFor(() => expect(screen.getByRole("img")).toHaveAttribute("src", "blob:mock-url"));

      expect(mockFetch).toHaveBeenCalledWith("/image");
      expect(mockCreateObjectURL).toHaveBeenCalled();
    });

    it("creates a blob URL for HEIF images", async () => {
      render(<ImageViewer {...props} mime_type="image/heif" />);

      await waitFor(() => expect(screen.getByRole("img")).toHaveAttribute("src", "blob:mock-url"));

      expect(mockFetch).toHaveBeenCalledWith("/image");
      expect(mockCreateObjectURL).toHaveBeenCalled();
    });

    it("uses the original URL for JPEG images", async () => {
      render(<ImageViewer {...props} mime_type="image/jpeg" />);

      await waitFor(() => expect(screen.getByRole("img")).toHaveAttribute("src", "/image"));

      expect(mockFetch).not.toHaveBeenCalled();
      expect(mockCreateObjectURL).not.toHaveBeenCalled();
    });
  });
});
