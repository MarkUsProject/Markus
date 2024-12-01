import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import {PDFViewer} from "../Result/pdf_viewer";

describe("PDFViewer", () => {
  let mockPdfViewer;
  let mockAnnotationManager;

  beforeEach(() => {
    mockPdfViewer = {
      setDocument: jest.fn(),
      pagesRotation: 0,
      currentScaleValue: "page-width",
    };

    mockAnnotationManager = {
      rotateClockwise90: jest.fn(),
    };

    global.pdfjsViewer = {
      EventBus: class {
        on = jest.fn();
      },
      PDFViewer: jest.fn(() => mockPdfViewer),
    };

    global.annotation_manager = mockAnnotationManager;

    render(<PDFViewer resultView={true} annotations={[]} />);
  });

  afterEach(() => {
    jest.restoreAllMocks();
    delete global.pdfjsViewer;
    delete global.annotation_manager;
  });

  describe("rotation", () => {
    let rotateButton;

    beforeEach(() => {
      rotateButton = screen.getByText(I18n.t("results.rotate_image"));
    });

    it("initially has a rotation of 0", async () => {
      expect(mockPdfViewer.pagesRotation).toBe(0);
    });

    it("rotates to 90 degrees when rotate button is clicked once", () => {
      fireEvent.click(rotateButton);

      expect(mockAnnotationManager.rotateClockwise90).toHaveBeenCalledTimes(1);
      expect(mockPdfViewer.pagesRotation).toBe(90);
    });

    it("rotates back to 0 degrees when rotate button is clicked four times", () => {
      for (let i = 0; i < 4; i++) {
        fireEvent.click(rotateButton);
      }

      expect(mockAnnotationManager.rotateClockwise90).toHaveBeenCalledTimes(4);
      expect(mockPdfViewer.pagesRotation).toBe(0);
    });
  });

  describe("zoom", () => {
    it("has default zoom 'page-width' on initial render", () => {
      expect(mockPdfViewer.currentScaleValue).toBe("page-width");
    });

    it("updates zoom to 100% (1.0) when the option is selected from dropdown", () => {
      const dropdown = screen.getByTestId("dropdown");
      fireEvent.click(dropdown);

      const option100 = screen.getByText("100 %");
      fireEvent.click(option100);

      expect(mockPdfViewer.currentScaleValue).toBe("1.00");
    });

    it("updates zoom to 75% (0.75) when the option is selected from dropdown", () => {
      const dropdown = screen.getByTestId("dropdown");
      fireEvent.click(dropdown);

      const option110 = screen.getByText("75 %");
      fireEvent.click(option110);

      expect(mockPdfViewer.currentScaleValue).toBe("0.75");
    });

    it("updates zoom to 125% (1.25) when the option is selected from dropdown", () => {
      const dropdown = screen.getByTestId("dropdown");
      fireEvent.click(dropdown);

      const option120 = screen.getByText("125 %");
      fireEvent.click(option120);

      expect(mockPdfViewer.currentScaleValue).toBe("1.25");
    });

    it("resets zoom to 'page-width' when the option is selected after selecting another zoom", () => {
      // set some arbitrary zoom first
      const dropdown = screen.getByTestId("dropdown");
      fireEvent.click(dropdown);
      const option120 = screen.getByText("125 %");
      fireEvent.click(option120);

      // now put it back to page width
      fireEvent.click(dropdown);
      const fitToPageWidthOption = screen.getByText(I18n.t("results.fit_to_page_width"));
      fireEvent.click(fitToPageWidthOption);

      expect(mockPdfViewer.currentScaleValue).toBe("page-width");
    });
  });
});
