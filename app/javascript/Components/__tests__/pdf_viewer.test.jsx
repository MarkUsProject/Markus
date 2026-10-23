import {render, screen, fireEvent, act} from "@testing-library/react";
import {PDFViewer} from "../Result/pdf_viewer";
import {ResultContext} from "../Result/result_context";

describe("PDFViewer", () => {
  let mockPdfViewer;
  let mockAnnotationManager;
  let eventBusInstances;

  class MockEventBus {
    constructor() {
      this.handlers = {};
      eventBusInstances.push(this);
    }

    on(event, handler) {
      (this.handlers[event] = this.handlers[event] || []).push(handler);
    }

    dispatch(event) {
      (this.handlers[event] || []).forEach(handler => handler());
    }
  }

  beforeEach(() => {
    eventBusInstances = [];

    mockPdfViewer = {
      setDocument: jest.fn(),
      update: jest.fn(),
      pagesRotation: 0,
      currentScaleValue: "page-width",
    };

    mockAnnotationManager = {
      rotateClockwise90: jest.fn(),
    };

    global.pdfjsViewer = {
      EventBus: MockEventBus,
      PDFViewer: jest.fn(() => mockPdfViewer),
    };

    global.pdfjs = {
      getDocument: jest.fn(() => ({promise: Promise.resolve({})})),
    };

    global.annotation_manager = mockAnnotationManager;
  });

  afterEach(() => {
    jest.restoreAllMocks();
    delete global.pdfjsViewer;
    delete global.pdfjs;
    delete global.annotation_manager;
  });

  describe("loading a document", () => {
    it("points pdf.js at the wasm image decoders so scanned (JBIG2) pages render", () => {
      render(
        <PDFViewer
          resultView={true}
          annotations={[]}
          url={"/some.pdf"}
          setLoadingCallback={jest.fn()}
        />
      );

      expect(global.pdfjs.getDocument).toHaveBeenCalledWith(
        expect.objectContaining({wasmUrl: `${RELATIVE_URL_ROOT}/wasm/`})
      );
    });

    // Each getDocument call returns a load the test settles by hand.
    let loads;
    let viewerProps;
    let rerenderViewer;

    beforeEach(() => {
      loads = [];
      global.pdfjs.getDocument = jest.fn(() => {
        const load = {};
        load.promise = new Promise((resolve, reject) => {
          load.resolve = resolve;
          load.reject = reject;
        });
        loads.push(load);
        return load;
      });
      viewerProps = {
        resultView: true,
        annotations: [],
        url: "/files/1.pdf",
        setLoadingCallback: jest.fn(),
        setErrorMessageCallback: jest.fn(),
      };
      const {rerender} = render(<PDFViewer {...viewerProps} />);
      rerenderViewer = url => rerender(<PDFViewer {...viewerProps} url={url} />);
    });

    it("shows the newer document when an older load settles last", async () => {
      rerenderViewer("/files/2.pdf");
      const [older, newer] = loads;

      await act(async () => newer.resolve("doc 2"));
      await act(async () => older.resolve("doc 1"));

      expect(mockPdfViewer.setDocument).toHaveBeenCalledTimes(1);
      expect(mockPdfViewer.setDocument).toHaveBeenCalledWith("doc 2");
    });

    it("ignores a load that settles after the URL is cleared", async () => {
      rerenderViewer(null);

      await act(async () => loads[0].resolve("doc 1"));

      expect(mockPdfViewer.setDocument).not.toHaveBeenCalled();
      expect(viewerProps.setLoadingCallback).not.toHaveBeenCalled();
    });

    it("shows an error when the document fails to load", async () => {
      await act(async () => loads[0].reject({status: 404}));

      expect(viewerProps.setErrorMessageCallback).toHaveBeenCalledWith(
        I18n.t("submissions.cannot_display")
      );
      expect(viewerProps.setLoadingCallback).toHaveBeenCalledWith(false);
    });

    it("shows the oversize message when the document is too large", async () => {
      await act(async () => loads[0].reject({status: 413}));

      expect(viewerProps.setErrorMessageCallback).toHaveBeenCalledWith(
        I18n.t("submissions.oversize_submission_file")
      );
    });

    it("ignores the failure of a load replaced by a newer one", async () => {
      rerenderViewer("/files/2.pdf");

      await act(async () => loads[0].reject({status: 404}));

      expect(viewerProps.setErrorMessageCallback).not.toHaveBeenCalled();
      expect(viewerProps.setLoadingCallback).not.toHaveBeenCalled();
    });
  });

  describe("redrawing when the pane is shown or resized", () => {
    let resize;

    beforeEach(() => {
      jest.spyOn(global, "ResizeObserver").mockImplementation(callback => {
        resize = width => callback([{borderBoxSize: [{inlineSize: width}]}]);
        return {observe: jest.fn(), disconnect: jest.fn()};
      });
      render(<PDFViewer resultView={true} annotations={[]} />);
      mockPdfViewer.update.mockClear();
    });

    it("draws the pages in view when the pane gets a width", () => {
      resize(800);

      expect(mockPdfViewer.update).toHaveBeenCalledTimes(1);
      expect(mockPdfViewer.currentScaleValue).toBe("page-width");
    });

    it("skips a resize that leaves the width unchanged", () => {
      resize(800);
      resize(800);

      expect(mockPdfViewer.update).toHaveBeenCalledTimes(1);
    });
  });

  describe("rotation", () => {
    let rotateButton;

    beforeEach(() => {
      render(<PDFViewer resultView={true} annotations={[]} />);
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
    beforeEach(() => {
      render(<PDFViewer resultView={true} annotations={[]} />);
    });

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

  describe("scroll position persistence for scanned exams", () => {
    const viewerProps = overrides => ({
      resultView: true,
      annotations: [],
      url: "/files/1.pdf",
      setLoadingCallback: jest.fn(),
      ...overrides,
    });

    beforeEach(() => {
      // The restore is deferred to an animation frame; run frames synchronously
      // so the test can assert on the result immediately after `pagesloaded`.
      jest.spyOn(window, "requestAnimationFrame").mockImplementation(cb => {
        cb();
        return 1;
      });
      jest.spyOn(window, "cancelAnimationFrame").mockImplementation(() => {});
    });

    // Renders a viewer inside a ResultContext and returns helpers to scroll,
    // load a different PDF (switching submissions or files), and fire pdf.js events.
    const renderWithContext = scanned_exam => {
      let submission_id = 1;
      let userFileSelectionCount = 0;
      const renderViewer = (utils, overrides) => {
        const tree = (
          <ResultContext.Provider value={{scanned_exam, submission_id}}>
            <PDFViewer {...viewerProps({userFileSelectionCount, ...overrides})} />
          </ResultContext.Provider>
        );
        return utils ? utils.rerender(tree) : render(tree);
      };
      const utils = renderViewer(null, {});
      const eventBus = eventBusInstances[eventBusInstances.length - 1];
      const scrollParent = utils.container.querySelector(".pdfContainerParent");
      // jsdom does no layout, so give the container dimensions that satisfy the
      // restore readiness check (visible and tall enough to scroll).
      Object.defineProperty(scrollParent, "scrollHeight", {configurable: true, value: 2000});
      Object.defineProperty(scrollParent, "clientHeight", {configurable: true, value: 500});
      const switchSubmission = (url, overrides = {}) => {
        submission_id += 1;
        renderViewer(utils, {url, ...overrides});
      };
      // A real submission switch changes the URL twice in separate renders: first
      // the submission id (the download URL embeds it), then the auto-selected
      // file for that submission. Neither is an explicit user file pick.
      const switchSubmissionInTwoSteps = (interimUrl, finalUrl, overrides = {}) => {
        submission_id += 1;
        renderViewer(utils, {url: interimUrl, ...overrides});
        renderViewer(utils, {url: finalUrl, ...overrides});
      };
      // The user deliberately opening a different file bumps the selection count.
      const switchFile = (url, overrides = {}) => {
        userFileSelectionCount += 1;
        renderViewer(utils, {url, ...overrides});
      };
      // Re-picking the already-open file bumps the count without changing the URL.
      const repickSameFile = (overrides = {}) => {
        userFileSelectionCount += 1;
        renderViewer(utils, {...overrides});
      };
      const hidePane = hidden => {
        utils.container.style.display = hidden ? "none" : "";
      };
      return {
        eventBus,
        scrollParent,
        hidePane,
        switchSubmission,
        switchSubmissionInTwoSteps,
        switchFile,
        repickSameFile,
      };
    };

    it("restores the scroll position after the new submission's PDF loads", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      scrollParent.scrollLeft = 30;
      switchSubmission("/files/2.pdf");

      // loading a new document resets the scroll position
      scrollParent.scrollTop = 0;
      scrollParent.scrollLeft = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(480);
      expect(scrollParent.scrollLeft).toBe(30);
    });

    it("keeps the scroll position across repeated submission switches", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      ["/files/2.pdf", "/files/3.pdf", "/files/4.pdf"].forEach(url => {
        switchSubmission(url);
        scrollParent.scrollTop = 0;
        eventBus.dispatch("pagesloaded");
      });

      expect(scrollParent.scrollTop).toBe(480);
    });

    it("waits until the container is tall enough before restoring", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(true);
      // Pages not laid out yet when pagesloaded fires — too short to hold offset.
      Object.defineProperty(scrollParent, "scrollHeight", {configurable: true, value: 500});
      const frames = [];
      window.requestAnimationFrame.mockImplementation(cb => frames.push(cb));

      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf");
      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      // Frame 1: not tall enough, so nothing is written yet.
      frames.shift()();
      expect(scrollParent.scrollTop).toBe(0);

      // Frame 2: pages laid out tall enough -> the saved position is applied.
      Object.defineProperty(scrollParent, "scrollHeight", {configurable: true, value: 2000});
      frames.shift()();
      expect(scrollParent.scrollTop).toBe(480);
    });

    it("re-applies the saved position if it is reset after loading", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(true);
      const frames = [];
      window.requestAnimationFrame.mockImplementation(cb => frames.push(cb));

      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf");
      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      // Frame 1: applies the saved position.
      frames.shift()();
      expect(scrollParent.scrollTop).toBe(480);

      // pdf.js resets the scroll to the top after our write...
      scrollParent.scrollTop = 0;
      // ...the next frame re-asserts it.
      frames.shift()();
      expect(scrollParent.scrollTop).toBe(480);
    });

    it("opens a different file of the same submission at the top", () => {
      const {eventBus, scrollParent, switchFile} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      switchFile("/files/2.pdf");

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(0);
    });

    it("keeps the scroll position when a switch updates the URL in two steps", () => {
      const {eventBus, scrollParent, switchSubmissionInTwoSteps} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      // First the submission id changes (interim URL), then the new submission's
      // file is auto-selected — the file refresh must not wipe the saved position.
      switchSubmissionInTwoSteps("/files/2-interim.pdf", "/files/2.pdf");

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(480);
    });

    it("keeps the scroll position when the URL is cleared while the new files load", () => {
      const {eventBus, scrollParent, switchSubmissionInTwoSteps} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      switchSubmissionInTwoSteps(null, "/files/2.pdf");

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(480);
    });

    it("keeps the saved position when another switch starts while the pane is hidden", () => {
      const {eventBus, scrollParent, switchSubmission, hidePane} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf");
      // The next switch starts before the PDF shows: the hidden pane reads as scrolled to 0.
      hidePane(true);
      scrollParent.scrollTop = 0;
      switchSubmission("/files/3.pdf");
      hidePane(false);
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(480);
    });

    it("opens a file picked after a submission switch at the top", () => {
      const {eventBus, scrollParent, switchSubmission, switchFile} = renderWithContext(true);

      // Switch submission (saves 480), then the user opens a different file.
      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf");
      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");
      expect(scrollParent.scrollTop).toBe(480);

      switchFile("/files/2-other.pdf");
      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(0);
    });

    it("keeps the scroll position when the same file is re-picked before a switch", () => {
      const {eventBus, scrollParent, repickSameFile, switchSubmission} = renderWithContext(true);

      scrollParent.scrollTop = 480;
      // Re-selecting the open file bumps the count but does not change the URL;
      // the next submission switch must still carry the scroll position over.
      repickSameFile();
      switchSubmission("/files/2.pdf");

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(480);
    });

    it("does not restore the scroll position for non-scanned assignments", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(false);

      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf");

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(0);
    });

    it("does not restore the scroll position when an annotation has focus", () => {
      const {eventBus, scrollParent, switchSubmission} = renderWithContext(true);

      const annotationHolder = document.createElement("div");
      annotationHolder.id = "annotation_holder_1";
      document.body.appendChild(annotationHolder);

      scrollParent.scrollTop = 480;
      switchSubmission("/files/2.pdf", {annotationFocus: 1});

      scrollParent.scrollTop = 0;
      eventBus.dispatch("pagesloaded");

      expect(scrollParent.scrollTop).toBe(0);
      annotationHolder.remove();
    });
  });
});
