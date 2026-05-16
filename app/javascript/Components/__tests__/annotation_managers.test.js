/**
 * Tests for getFallbackSelection() on the annotation manager classes,
 * for get_html_annotation_range() with the new warn parameter,
 * and for synthesize_html_fallback_selection() in result.jsx.
 *
 * annotation_manager.js, text_annotation_manager.js, and image_annotation_manager.js
 * are plain class declarations (no IIFE, no window exports). When require()'d by Jest
 * they are scoped to that module and don't become globals. We eval() them into the
 * global scope so that subclasses can find their base classes.
 *
 * pdf_annotation_manager.js IS an IIFE that does window.PdfAnnotationManager = ...,
 * so it is require()'d normally after the base class is in global scope.
 */

// result.jsx imports @rails/ujs which throws when jquery_ujs is already present in the
// Jest environment. Mock it out so we can import synthesize_html_fallback_selection.
jest.mock("@rails/ujs", () => {});

const fs = require("fs");
const path = require("path");

/**
 * Load a plain script and assign its top-level class declaration(s) to global.
 * `class` declarations are block-scoped even in eval/Function, so we use a
 * Function wrapper that receives `global` as a parameter, executes the script
 * source, then explicitly assigns the named class to global.
 */
function loadScript(relPath, exportNames) {
  const src = fs.readFileSync(path.resolve(__dirname, relPath), "utf8");
  const assignments = exportNames
    .map(name => `if(typeof ${name}!=='undefined') _g.${name}=${name};`)
    .join("\n");
  // eslint-disable-next-line no-new-func
  new Function("_g", src + "\n" + assignments)(global);
}

// Stub dependency classes before loading the manager scripts.
global.AnnotationTextDisplayer = class {
  hide() {}
  displayCollection() {}
  setDisplayNodeParent() {}
};

global.AnnotationTextManager = class {
  findOrCreateAnnotationText() {
    return {};
  }
};

global.SourceCodeLine = class {
  constructor(node) {
    this.line_node = node;
  }
  glow() {}
  unglow() {}
};

// Load the base class and subclasses into global scope.
// From __tests__/ go up 3 levels to reach app/, then into assets/javascripts/.
loadScript("../../../assets/javascripts/Annotations/annotation_manager.js", ["AnnotationManager"]);
loadScript("../../../assets/javascripts/Annotations/text_annotation_manager.js", [
  "TextAnnotationManager",
]);
loadScript("../../../assets/javascripts/Annotations/image_annotation_manager.js", [
  "ImageAnnotationManager",
]);

// PdfAnnotationManager is an IIFE that exports via window.PdfAnnotationManager.
// It depends on AnnotationManager already being in global scope, which it now is.
require("../../../assets/javascripts/Annotations/pdf_annotation_manager.js");

// html_annotations.js defines plain functions; load and export them to global.
loadScript("../../../assets/javascripts/Annotations/html_annotations.js", [
  "get_html_annotation_range",
  "check_annotation_overlap",
  "descendant_of_annotation",
  "ancestor_of_annotation",
]);

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Build a minimal TextAnnotationManager from an array of line content strings. */
function makeTextManager(lines) {
  const nodes = lines.map(text => {
    const node = document.createElement("span");
    node.textContent = text;
    return node;
  });
  return new global.TextAnnotationManager(nodes);
}

/** Build a minimal ImageAnnotationManager with a mock image element. */
function makeImageManager({
  naturalWidth = 200,
  naturalHeight = 100,
  displayWidth = 400,
  displayHeight = 200,
  rectLeft = 0,
  rectTop = 0,
} = {}) {
  const img = document.createElement("img");
  Object.defineProperty(img, "naturalWidth", {value: naturalWidth, configurable: true});
  Object.defineProperty(img, "naturalHeight", {value: naturalHeight, configurable: true});
  img.getBoundingClientRect = () => ({
    left: rectLeft,
    top: rectTop,
    width: displayWidth,
    height: displayHeight,
  });

  const selBox = document.createElement("div");

  const origGetById = document.getElementById.bind(document);
  jest.spyOn(document, "getElementById").mockImplementation(id => {
    if (id === "image_preview") return img;
    if (id === "sel_box") return selBox;
    return origGetById(id);
  });

  const mgr = new global.ImageAnnotationManager(false);
  document.getElementById.mockRestore();
  return {mgr, img};
}

// ─── TextAnnotationManager.getFallbackSelection ──────────────────────────────

describe("TextAnnotationManager.getFallbackSelection()", () => {
  it("returns line 1 selection when line 1 is non-empty", () => {
    const mgr = makeTextManager(["hello world", "second line"]);
    expect(mgr.getFallbackSelection()).toEqual({
      line_start: 1,
      line_end: 1,
      column_start: 0,
      column_end: 1,
    });
  });

  it("skips a blank line 1 and returns line 2 when that is first non-empty", () => {
    const mgr = makeTextManager(["", "second line"]);
    expect(mgr.getFallbackSelection()).toEqual({
      line_start: 2,
      line_end: 2,
      column_start: 0,
      column_end: 1,
    });
  });

  it("skips whitespace-only lines and returns first line with non-whitespace content", () => {
    // Line 1 = "" (empty), line 2 = "  " (spaces only, trimmed length = 0), line 3 = "third".
    // The fallback uses lineContent.trim().length > 0, so line 2 is skipped and line 3 is returned.
    const mgr = makeTextManager(["", "  ", "third"]);
    expect(mgr.getFallbackSelection()).toEqual({
      line_start: 3,
      line_end: 3,
      column_start: 0,
      column_end: 1,
    });
  });

  it("returns false for an empty file (no lines)", () => {
    const mgr = makeTextManager([]);
    expect(mgr.getFallbackSelection()).toBe(false);
  });

  it("returns false when all lines are empty strings", () => {
    const mgr = makeTextManager(["", "", ""]);
    expect(mgr.getFallbackSelection()).toBe(false);
  });

  it("returns false when all lines are whitespace-only", () => {
    const mgr = makeTextManager(["  ", "\t", "   "]);
    expect(mgr.getFallbackSelection()).toBe(false);
  });
});

// ─── ImageAnnotationManager.getFallbackSelection ─────────────────────────────

describe("ImageAnnotationManager.getFallbackSelection()", () => {
  it("returns a 40×40 box in image-pixel space centred at the click position", () => {
    const {mgr} = makeImageManager({
      naturalWidth: 200,
      naturalHeight: 100,
      displayWidth: 400,
      displayHeight: 200,
      rectLeft: 0,
      rectTop: 0,
    });

    // Click at display pixel (100, 50); rect origin is (0,0).
    // scaleX = 200/400 = 0.5 → imgX = round(100 * 0.5) = 50
    // scaleY = 100/200 = 0.5 → imgY = round(50 * 0.5) = 25
    // x1 = max(0, 50-20)=30, x2 = min(200, 50+20)=70
    // y1 = max(0, 25-20)=5,  y2 = min(100, 25+20)=45
    mgr.last_click_event = {clientX: 100, clientY: 50};
    expect(mgr.getFallbackSelection()).toEqual({x1: 30, y1: 5, x2: 70, y2: 45});
  });

  it("falls back to image centre when last_click_event is null", () => {
    const {mgr} = makeImageManager({
      naturalWidth: 200,
      naturalHeight: 100,
      displayWidth: 400,
      displayHeight: 200,
    });
    mgr.last_click_event = null;

    // clickX = displayWidth/2 = 200 → imgX = round(200 * 0.5) = 100
    // clickY = displayHeight/2 = 100 → imgY = round(100 * 0.5) = 50
    // x1=80, x2=120, y1=30, y2=70
    expect(mgr.getFallbackSelection()).toEqual({x1: 80, y1: 30, x2: 120, y2: 70});
  });

  it("clamps x1 to 0 when click is within 20 image-px of the left edge", () => {
    const {mgr} = makeImageManager({
      naturalWidth: 200,
      naturalHeight: 100,
      displayWidth: 400,
      displayHeight: 200,
    });
    // Display click at (10, 50) → imgX = round(10 * 0.5) = 5; x1 = max(0, 5-20) = 0
    mgr.last_click_event = {clientX: 10, clientY: 50};
    const result = mgr.getFallbackSelection();
    expect(result.x1).toBe(0);
    expect(result.x2).toBe(25);
  });

  it("clamps x2 to naturalWidth when click is within 20 image-px of the right edge", () => {
    const {mgr} = makeImageManager({
      naturalWidth: 200,
      naturalHeight: 100,
      displayWidth: 400,
      displayHeight: 200,
    });
    // Display click at (390, 50) → imgX = round(390 * 0.5) = 195; x2 = min(200, 215) = 200
    mgr.last_click_event = {clientX: 390, clientY: 50};
    const result = mgr.getFallbackSelection();
    expect(result.x1).toBe(175);
    expect(result.x2).toBe(200);
  });

  it("returns false when the displayed image has zero dimensions", () => {
    const img = document.createElement("img");
    Object.defineProperty(img, "naturalWidth", {value: 200, configurable: true});
    Object.defineProperty(img, "naturalHeight", {value: 100, configurable: true});
    img.getBoundingClientRect = () => ({left: 0, top: 0, width: 0, height: 0});

    const selBox = document.createElement("div");
    const origGetById = document.getElementById.bind(document);
    jest.spyOn(document, "getElementById").mockImplementation(id => {
      if (id === "image_preview") return img;
      if (id === "sel_box") return selBox;
      return origGetById(id);
    });
    const mgr = new global.ImageAnnotationManager(false);
    document.getElementById.mockRestore();

    expect(mgr.getFallbackSelection()).toBe(false);
  });
});

// ─── PdfAnnotationManager.getFallbackSelection ───────────────────────────────

describe("PdfAnnotationManager.getFallbackSelection()", () => {
  const MULT = 100000;
  let pageEl;

  beforeEach(() => {
    pageEl = document.createElement("div");
    pageEl.dataset.pageNumber = "1";
    document.body.appendChild(pageEl);
    // 500 wide × 1000 tall page, top-left at (0,0).
    pageEl.getBoundingClientRect = () => ({
      left: 0,
      top: 0,
      width: 500,
      height: 1000,
    });
    document.elementFromPoint = jest.fn(() => pageEl);

    // Stub jQuery to return the page element for .page[data-page-number] queries.
    const origJQ = global.$;
    global.$ = jest.fn(selector => {
      if (typeof selector === "string" && selector.includes(".page")) {
        return {
          length: 1,
          first: () => ({length: 1, 0: pageEl, data: () => 1}),
        };
      }
      return origJQ(selector);
    });
  });

  afterEach(() => {
    if (pageEl.parentNode) pageEl.parentNode.removeChild(pageEl);
    global.$ = window.jQuery;
    delete document.elementFromPoint;
  });

  it("returns a box centred at the click position at 0° rotation", () => {
    const mgr = new window.PdfAnnotationManager(false);
    mgr.last_click_event = {clientX: 250, clientY: 500};

    const result = mgr.getFallbackSelection();
    // cx = round(250/500 * 100000) = 50000
    // cy = round(500/1000 * 100000) = 50000
    // halfX = round(20/500 * 100000) = 4000
    // halfY = round(20/1000 * 100000) = 2000
    // At 0° no rotation applied.
    expect(result).toEqual({
      page: 1,
      x1: 46000,
      x2: 54000,
      y1: 48000,
      y2: 52000,
    });
  });

  it("applies 270° rotation correction when angle is 90°", () => {
    const mgr = new window.PdfAnnotationManager(false);
    mgr.angle = 90;
    mgr.last_click_event = {clientX: 250, clientY: 500};

    const result = mgr.getFallbackSelection();
    // Pre-rotation box: x1=46000, y1=48000, x2=54000, y2=52000
    // Inverse rotation = 360-90 = 270.
    // getRotatedCoords(box, 270):
    //   newX1 = y1 = 48000
    //   newX2 = y2 = 52000
    //   newY1 = MULT - x2 = 100000 - 54000 = 46000
    //   newY2 = MULT - x1 = 100000 - 46000 = 54000
    expect(result).toEqual({
      page: 1,
      x1: 48000,
      x2: 52000,
      y1: 46000,
      y2: 54000,
    });
  });

  it("returns false when no page element is found anywhere", () => {
    document.elementFromPoint = jest.fn(() => null);
    global.$ = jest.fn(() => ({length: 0, first: () => ({length: 0})}));

    const mgr = new window.PdfAnnotationManager(false);
    mgr.last_click_event = {clientX: 250, clientY: 500};

    expect(mgr.getFallbackSelection()).toBe(false);
  });
});

// ─── get_html_annotation_range() ─────────────────────────────────────────────

describe("get_html_annotation_range()", () => {
  let iframeDoc;

  beforeEach(() => {
    iframeDoc = {getSelection: () => ({rangeCount: 0})};
    const iframe = document.createElement("iframe");
    Object.defineProperty(iframe, "contentDocument", {
      value: iframeDoc,
      configurable: true,
    });
    const origGetById = document.getElementById.bind(document);
    jest
      .spyOn(document, "getElementById")
      .mockImplementation(id => (id === "html-content" ? iframe : origGetById(id)));
  });

  afterEach(() => {
    document.getElementById.mockRestore();
  });

  it("returns null without alerting when warn=false and no selection exists", () => {
    const alertSpy = jest.spyOn(window, "alert").mockImplementation(() => {});
    expect(global.get_html_annotation_range(false)).toBeNull();
    expect(alertSpy).not.toHaveBeenCalled();
    alertSpy.mockRestore();
  });

  it("alerts and returns null when warn=true (default) and no selection exists", () => {
    const alertSpy = jest.spyOn(window, "alert").mockImplementation(() => {});
    expect(global.get_html_annotation_range()).toBeNull();
    expect(alertSpy).toHaveBeenCalledTimes(1);
    alertSpy.mockRestore();
  });

  it("returns the range when a valid non-collapsed selection exists", () => {
    // Attach the text node to document.body so that descendant_of_annotation's
    // parentNode walk terminates at document (Node.DOCUMENT_NODE) rather than null.
    const container = document.createElement("span");
    document.body.appendChild(container);
    const textNode = document.createTextNode("hello");
    container.appendChild(textNode);

    const mockRange = {
      startContainer: textNode,
      endContainer: textNode,
      startOffset: 0,
      endOffset: 3,
      cloneContents: () => ({children: []}),
    };
    iframeDoc.getSelection = () => ({rangeCount: 1, getRangeAt: () => mockRange});

    expect(global.get_html_annotation_range(false)).toBe(mockRange);

    document.body.removeChild(container);
  });
});

// ─── context_menu beforeOpen ──────────────────────────────────────────────────

describe("context_menu beforeOpen handler", () => {
  let capturedOptions;
  let enabledEntries;
  let origAnnotationManager;

  beforeEach(() => {
    origAnnotationManager = window.annotation_manager;

    // Spy on $.fn.contextmenu to capture the options object passed during setup().
    jest.spyOn($.fn, "contextmenu").mockImplementation(function (optsOrCmd) {
      if (typeof optsOrCmd === "object") {
        capturedOptions = optsOrCmd;
      } else if (optsOrCmd === "enableEntry") {
        // Track which entries are enabled/disabled: args are (cmd, entry, enabled).
        const [, entry, enabled] = arguments;
        enabledEntries[entry] = enabled;
      } else if (optsOrCmd === "showEntry") {
        // ignore
      } else if (optsOrCmd === "getMenu") {
        return {find: () => ({length: 0})};
      }
      return this;
    });

    capturedOptions = null;
    enabledEntries = {};

    // Set up globals that context_menu.js reads.
    global.ANNOTATION_TYPES = {CODE: 0, IMAGE: 1, PDF: 2, HTML: 3};
    global.annotation_type = global.ANNOTATION_TYPES.CODE;
    global.resultComponent = {current: {addQuickAnnotation: jest.fn(), newAnnotation: jest.fn()}};
  });

  afterEach(() => {
    window.annotation_manager = origAnnotationManager;
    $.fn.contextmenu.mockRestore();
    delete global.ANNOTATION_TYPES;
    delete global.annotation_type;
    delete global.resultComponent;
  });

  it("stores last_click_event on annotation_manager and enables all annotation creation items", async () => {
    const {annotation_context_menu} = await import("../Result/context_menu.js");
    annotation_context_menu.setup();

    expect(capturedOptions).not.toBeNull();

    // Set up a mock annotation_manager.
    const mockManager = {last_click_event: null};
    window.annotation_manager = mockManager;

    const fakeEvent = {clientX: 100, clientY: 200, type: "contextmenu"};
    const fakeUi = {target: document.createElement("div")};

    capturedOptions.beforeOpen(fakeEvent, fakeUi);

    // The event should have been stored on the annotation_manager.
    expect(mockManager.last_click_event).toBe(fakeEvent);

    // All annotation creation items should be enabled unconditionally.
    expect(enabledEntries["check_mark_annotation"]).toBe(true);
    expect(enabledEntries["thumbs_up_annotation"]).toBe(true);
    expect(enabledEntries["heart_annotation"]).toBe(true);
    expect(enabledEntries["smile_annotation"]).toBe(true);
    expect(enabledEntries["new_annotation"]).toBe(true);
    expect(enabledEntries["common_annotations"]).toBe(true);
  });

  it("does not throw when annotation_manager is null", async () => {
    const {annotation_context_menu} = await import("../Result/context_menu.js");
    annotation_context_menu.setup();

    window.annotation_manager = null;

    const fakeEvent = {clientX: 0, clientY: 0};
    const fakeUi = {target: document.createElement("div")};

    // Should not throw even when annotation_manager is null.
    expect(() => capturedOptions.beforeOpen(fakeEvent, fakeUi)).not.toThrow();
  });
});

// ─── synthesize_html_fallback_selection() ────────────────────────────────────

describe("synthesize_html_fallback_selection()", () => {
  let synthesize_html_fallback_selection;

  beforeEach(() => {
    ({synthesize_html_fallback_selection} = require("../Result/result.jsx"));
  });

  afterEach(() => {
    jest.resetModules();
    document.getElementById.mockRestore && document.getElementById.mockRestore();
  });

  it("returns null when no iframe element exists", () => {
    jest.spyOn(document, "getElementById").mockReturnValue(null);
    expect(synthesize_html_fallback_selection()).toBeNull();
  });

  it("returns null when iframe has no contentDocument", () => {
    jest
      .spyOn(document, "getElementById")
      .mockImplementation(id => (id === "html-content" ? {contentDocument: null} : null));
    expect(synthesize_html_fallback_selection()).toBeNull();
  });

  it("returns null when iframe body has no text content", () => {
    const emptyBody = document.createElement("div");
    const fakeDoc = {body: emptyBody, createRange: () => document.createRange()};
    jest
      .spyOn(document, "getElementById")
      .mockImplementation(id => (id === "html-content" ? {contentDocument: fakeDoc} : null));
    expect(synthesize_html_fallback_selection()).toBeNull();
  });

  it("returns start_node/end_node/offsets for body with text content", () => {
    const textNode = document.createTextNode("Hello world");
    const bodyEl = document.createElement("div");
    bodyEl.appendChild(textNode);

    const fakeRange = {
      setStart: jest.fn(),
      setEnd: jest.fn(),
      startContainer: textNode,
      endContainer: textNode,
      startOffset: 0,
      endOffset: 1,
      cloneContents: () => ({children: []}),
    };
    const fakeDoc = {body: bodyEl, createRange: () => fakeRange};
    jest
      .spyOn(document, "getElementById")
      .mockImplementation(id => (id === "html-content" ? {contentDocument: fakeDoc} : null));
    global.check_annotation_overlap = jest.fn(() => false);

    const result = synthesize_html_fallback_selection();
    expect(result).not.toBeNull();
    expect(result.start_offset).toBe(0);
    expect(result.end_offset).toBe(1);
    expect(result.start_node).toBeDefined();
    expect(result.end_node).toBeDefined();
  });
});
