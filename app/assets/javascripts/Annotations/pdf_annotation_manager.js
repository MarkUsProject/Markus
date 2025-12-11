(function (window) {
  "use strict";

  // CONSTANTS
  const MOUSE_OFFSET = 10; // The offset from the mouse cursor point
  const HIDE_BOX_THRESHOLD = 10; // Threshold for not displaying selection box in pixels
  const COORDINATE_PRECISION = 5; // Keep 5 decimal places (used when converting back from ints)
  const COORDINATE_MULTIPLIER = Math.pow(10, COORDINATE_PRECISION);

  /**
   * AnnotationManager subclass for PDF files.
   *
   * @param {boolean} enable_annotations Whether annotations can be modified
   */
  class PdfAnnotationManager extends AnnotationManager {
    constructor(enable_annotations) {
      // Members
      super();
      this.angle = 0; // current orientation of the PDF

      this.annotationControls = {}; // DOM elements added for annotations

      /** @type {{page: int, $control: HTMLElement}} */
      this.selectionBox = {};

      // The current selection area. The x, y are stored as percentages
      // for device independent resolution
      /** @type {{x: number, y: number, width: number, height: number}} */
      this.currentSelection = {};

      // Event Handlers
      if (enable_annotations) {
        this.bindPageEvents();
      }
    }

    /**
     * Get a selection for a specific page.
     * @return {{page: {int}, $control: {HTMLElement}}}
     */
    getSelectionBox($page) {
      let pageNumber = $page.data("page-number");

      if (
        this.selectionBox.page === pageNumber &&
        this.selectionBox.$control !== null &&
        $.contains(document, this.selectionBox.$control)
      ) {
        return this.selectionBox;
      } else if (this.selectionBox.$control != null) {
        this.selectionBox.$control.remove(); // Remove old control
      }

      let $control = document.createElement("div");
      $control.id = "sel_box";
      $control.addClass("annotation-holder-active");
      $control.style.display = "none";

      // append $control before the first annotation_holder but after the annotationLayer
      // or else you will be prevented from deleting/editing old annotations
      let $first_anno = $page.find(".annotation_holder:first")[0];

      if (!!$first_anno) {
        $first_anno.parentNode.insertBefore($control, $first_anno);
      } else {
        $page.append($control);
      }

      this.selectionBox = {
        page: pageNumber,
        $control: $control,
      };

      return this.selectionBox;
    }

    /**
     * Update and redraw the selection box.
     *
     * @param {jQuery}                $page   The page the control is for.
     * @param {{x, y, width, height, visible}} params  Values to update
     */
    setSelectionBox($page, params) {
      if (params) {
        Object.assign(this.currentSelection, params);

        let sel_box = this.getSelectionBox($page).$control;
        sel_box.style.top = this.currentSelection.y * 100 + "%";
        sel_box.style.left = this.currentSelection.x * 100 + "%";
        sel_box.style.width = this.currentSelection.width * 100 + "%";
        sel_box.style.height = this.currentSelection.height * 100 + "%";

        sel_box.style.display = this.currentSelection.visible ? "block" : "none";
      }
    }

    hide_selection_box() {
      this.currentSelection.visible = false;
      if (this.selectionBox.$control) {
        this.selectionBox.$control.style.display = "none";
      }
    }

    /**
     * Returns the selection box coordinates (used when creating an annotation).
     * @returns {{x1, y1, x2, y2, page}}
     */
    getSelection(warn_no_selection = true) {
      let box = this.get_pdf_box_attrs();
      if (!box) {
        if (warn_no_selection) {
          alert(I18n.t("results.annotation.select_an_area_pdf"));
        }
        return false;
      }
      let page = box.page;
      box = getRotatedCoords(box, 360 - annotation_manager.angle);

      return {...box, page: page};
    }

    get_pdf_box_attrs() {
      let box = this.selectionRectangleAsInts();
      let boxSize = this.selectionBoxSize();

      if (!box || boxSize.width < HIDE_BOX_THRESHOLD || boxSize.height < HIDE_BOX_THRESHOLD) {
        return false;
      } else {
        return box;
      }
    }

    /**
     * Return the current selection bounding rectangle if there is one, and
     * converts the floating point percentages to integers.
     *
     * @return {{x1, y1, x2, y2, page}} Bounding box (points are in percentages)
     */
    selectionRectangleAsInts() {
      if (!this.currentSelection.visible) {
        return null;
      }

      return {
        x1: parseInt(this.currentSelection.x * COORDINATE_MULTIPLIER, 10),
        y1: parseInt(this.currentSelection.y * COORDINATE_MULTIPLIER, 10),
        x2: parseInt(
          (this.currentSelection.x + this.currentSelection.width) * COORDINATE_MULTIPLIER,
          10
        ),
        y2: parseInt(
          (this.currentSelection.y + this.currentSelection.height) * COORDINATE_MULTIPLIER,
          10
        ),
        page: this.selectionBox.page,
      };
    }

    /**
     * Get the selection box size in pixels. If there is no selection box
     * return {width: 0, height: 0}.
     *
     * @return {{width: int, height: int}} The selection box size in pixels
     */
    selectionBoxSize() {
      let $box = this.selectionBox.$control;

      return $box ? {width: $box.offsetWidth, height: $box.offsetHeight} : {width: 0, height: 0};
    }

    /**
     * Add an annotation to the PDF.
     *
     * @param {string} annotation_text_id [description]
     * @param {string} content            [description]
     * @param {{x1: int, y1: int, x2: int, y2: int, page: int}} range
     * @param {string} annotation_id the id of the annotation
     * @param {boolean} is_remark
     */
    addAnnotation(annotation_text_id, content, range, annotation_id, is_remark) {
      let annotation = super.addAnnotation(
        annotation_text_id,
        content,
        range,
        annotation_id,
        is_remark
      );

      // Update display
      this.renderAnnotation(annotation);
      this.hide_selection_box();
    }

    /**
     * Remove an annotation
     * @param  {string} annotation_id      Annotation ID
     */
    removeAnnotation(annotation_id) {
      let annotation = super.removeAnnotation(annotation_id);
      if (annotation === undefined) {
        return;
      }
      this.annotationControls[annotation_id].remove(); // Delete DOM node
    }

    /**
     * Draw the annotation on the screen.
     *
     * @param {{annotation_id: string, annotation_text: Object, range: Object}} annotation
     */
    renderAnnotation = function (annotation) {
      let {annotation_id, annotation_text, range} = annotation;
      if (this.annotationControls[annotation_id]) {
        this.annotationControls[annotation_id].remove(); // Remove old controls
      }

      // The coords are in the unrotated form, but the PDF may be in a different orientation.
      let newCoords = getRotatedCoords(range, this.angle);

      let $control = document.createElement("div");
      $control.id = "annotation_holder_" + annotation_id;
      $control.addClass("annotation_holder");
      if (this.annotations[annotation_id].is_remark) {
        $control.addClass("remark");
      }
      $control.style.top = (newCoords.y1 / COORDINATE_MULTIPLIER) * 100 + "%";
      $control.style.left = (newCoords.x1 / COORDINATE_MULTIPLIER) * 100 + "%";
      $control.style.width = ((newCoords.x2 - newCoords.x1) / COORDINATE_MULTIPLIER) * 100 + "%";
      $control.style.height = ((newCoords.y2 - newCoords.y1) / COORDINATE_MULTIPLIER) * 100 + "%";

      let annotation_text_displayer = this.annotation_text_displayer;
      $control.onmousemove = function (ev) {
        let point = getRelativePointForEvent(ev, $page, -1);

        annotation_text_displayer.setDisplayNodeParent($page[0]);
        annotation_text_displayer.displayCollection(
          [annotation_text],
          point.x * 100,
          point.y * 100,
          "%"
        );
      };

      $control.onmouseleave = function () {
        annotation_text_displayer.hide();
      };

      this.annotationControls[annotation_id] = $control;

      let $page = $(`.page[data-page-number=${range.page}]`);
      $page.append($control);
    };

    /**
     * The following two functions are used to keep track of the orientation of
     * the PDF so we know how to render the annotations.
     */
    rotateClockwise90() {
      this.hide_selection_box();
      this.angle += 90;
      if (this.angle === 360) this.angle = 0;
    }

    resetAngle() {
      this.angle = 0;
    }

    /**
     * Set event handlers for PDF annotations.
     */
    bindPageEvents() {
      let $pages = $(".page");
      let selectionBoxActive = false; // Is the selection box in use

      // Start of click
      let start = {
        x: 0,
        y: 0,
      };

      // Helper: Start selection box
      const startSelection = (point, $target) => {
        this.setSelectionBox($target, {
          x: point.x,
          y: point.y,
          width: 0,
          height: 0,
          visible: true,
        });

        start = point;
        selectionBoxActive = true;
      };

      // Helper: Update selection box dimensions
      const updateSelection = (point, $target) => {
        if (!selectionBoxActive) {
          return;
        }

        this.setSelectionBox($target, {
          x: Math.min(start.x, point.x),
          y: Math.min(start.y, point.y),
          width: Math.abs(start.x - point.x),
          height: Math.abs(start.y - point.y),
        });
      };

      // Helper: End selection box
      const endSelection = () => {
        let size = this.selectionBoxSize();

        // If the box is REALLY small then hide it
        if (size.width < HIDE_BOX_THRESHOLD && size.height < HIDE_BOX_THRESHOLD) {
          this.hide_selection_box();
        }

        selectionBoxActive = false;
      };

      // Mouse event handlers
      $pages.mousedown(ev => {
        if (ev.which !== 1 && ev.target.id === "sel_box") {
          return;
        }

        let point = getRelativePointForEvent(ev);
        startSelection(point, $(ev.delegateTarget));
      });

      $pages.mousemove(ev => {
        let point = getRelativePointForEvent(ev);
        updateSelection(point, $(ev.delegateTarget));
      });

      $pages.mouseup(() => {
        endSelection();
      });

      // Touch event handlers
      $pages.on("touchstart", ev => {
        // Prevent default to avoid scrolling while annotating
        ev.preventDefault();

        let touch = ev.originalEvent.touches[0];
        let point = getRelativePointForEvent(touch, ev.delegateTarget, undefined);
        startSelection(point, $(ev.delegateTarget));
      });

      $pages.on("touchmove", ev => {
        // Prevent default to avoid scrolling while annotating
        ev.preventDefault();

        let touch = ev.originalEvent.touches[0];
        let point = getRelativePointForEvent(touch, ev.delegateTarget, undefined);
        updateSelection(point, $(ev.delegateTarget));
      });

      $pages.on("touchend", () => {
        endSelection();
      });
    }
  }

  /**
   * Returns the selection point in percentage units for a mouse or touch event.
   *
   * @param {Event|Touch}           eventOrTouch The event or touch object.
   * @param {String|DOMNode|jQuery} relativeTo   The element to calculate the offset for.
   * @param {number}                mouseOffset  Custom mouse offset value.
   * @return {{x: number, y:number}}  The relative point in the element the event occurred in.
   */
  function getRelativePointForEvent(eventOrTouch, relativeTo, mouseOffset) {
    let $elem = relativeTo ? $(relativeTo) : $(eventOrTouch.delegateTarget);
    let offset = $elem.offset();

    let width = $elem.width();
    let height = $elem.height();

    let x = eventOrTouch.pageX - offset.left - (mouseOffset || MOUSE_OFFSET);
    let y = eventOrTouch.pageY - offset.top - (mouseOffset || MOUSE_OFFSET);

    return {
      x: 1 - (width - x) / width,
      y: 1 - (height - y) / height,
    };
  }

  /**
   * Returns the rotated coordinates of the annotation after applying
   * the rotation specified by angle.
   *
   * @param {{x1: int, y1: int, x2: int, y2: int, page: int}} coords
   * @param {number} angle
   */
  function getRotatedCoords(coords, angle) {
    let newCoords = {
      x1: coords.x1,
      x2: coords.x2,
      y1: coords.y1,
      y2: coords.y2,
    };

    switch (angle) {
      case 90:
        newCoords.x1 = COORDINATE_MULTIPLIER - coords.y2;
        newCoords.x2 = COORDINATE_MULTIPLIER - coords.y1;
        newCoords.y1 = coords.x1;
        newCoords.y2 = coords.x2;
        break;
      case 180:
        newCoords.x1 = COORDINATE_MULTIPLIER - coords.x2;
        newCoords.x2 = COORDINATE_MULTIPLIER - coords.x1;
        newCoords.y1 = COORDINATE_MULTIPLIER - coords.y2;
        newCoords.y2 = COORDINATE_MULTIPLIER - coords.y1;
        break;
      case 270:
        newCoords.x1 = coords.y1;
        newCoords.x2 = coords.y2;
        newCoords.y1 = COORDINATE_MULTIPLIER - coords.x2;
        newCoords.y2 = COORDINATE_MULTIPLIER - coords.x1;
        break;
    }
    return newCoords;
  }

  // Exports
  window.PdfAnnotationManager = PdfAnnotationManager;
})(window);
