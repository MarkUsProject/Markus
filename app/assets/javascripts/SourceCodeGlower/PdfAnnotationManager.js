// Class: PdfAnnotationManager
(function(window) {
  'use strict';

  var $ = jQuery;         // Rebind
  var MOUSE_OFFSET = 10;  // The offset from the mouse cursor point

  // CONSTANTS
  var HIDE_BOX_THRESHOLD = 5;   // Threshold for not displaying selection box in pixels
  var COORDINATE_PRECISION = 5; // Keep 5 decimal places (used when converting back from ints)
  var COORDINATE_MULTIPLIER = Math.pow(10, COORDINATE_PRECISION);

  /**
   * Manager to load and display pdf annotations.
   *
   * @class
   *
   * @param {PDFView} pdfView      PDF Viewer
   * @param {String}  pageParentId The ID of the parent container of the pages.
   */
  function PdfAnnotationManager(pdfView, pageParentId) {
    var self = this;

    // Members
    this.pdfView = pdfView;
    this.annotationTextManager = new AnnotationTextManager();
    this.pageParentId = pageParentId;

    /** @type {<page> : {[id]: {annotation: AnnotationText, coords: Object}} */
    this.annotations = {};        // Lookup of annotations by page number
    this.annotationsById = {};    // Lookup of annotations by annotation id
    this.annotationControls = {}; // DOM elements added for annotations

    /** @type {{page: int, $control: jQuery}} */
    this.selectionBox = {};

    // The current selection area. The x, y are stored as percentages
    // for device independent resolution
    /** @type {{x: number, y: number, width: number, height: number}} */
    this.currentSelection = {};

    // Event Handlers
    this.pdfView.onPageRendered = this.onPageRendered.bind(this);
    this.bindPageEvents();
  }

  /**
   * Returns the selection point in percentage units for an event on
   * a element.
   *
   * @param {Event}                 ev          The event that occurred.
   * @param {String|DOMNode|jQuery} relativeTo  The element to calculate the offset for.
   * @param {number}                mouseOffset Custom mouse offset value.
   * @return {{x: number, y:number}}  The relative point in the element the event occurred in.
   */
  function getRelativePointForMouseEvent(ev, relativeTo, mouseOffset) {
    var $elem = (relativeTo ? $(relativeTo) : $(ev.delegateTarget));
    var offset = $elem.offset();

    var width = $elem.width();
    var height = $elem.height();

    var x = ev.pageX - offset.left - (mouseOffset || MOUSE_OFFSET);
    var y = ev.pageY - offset.top - (mouseOffset || MOUSE_OFFSET);

    return {
      x: 1 - ((width - x)/width),
      y: 1 - ((height - y)/height)
    };
  }

  /**
   * Get all the annotations for a specific page.
   * @param  {number} pageNumber The page number to get the annotations for
   * @return {{annotation: AnnotationText, coords: Object}[]} Annotation data.
   */
  PdfAnnotationManager.prototype.getPageAnnotations = function(pageNumber) {
    var pageData = this.annotations[pageNumber];

    if (!pageData) {
      return []; // No annotations on page
    } else {
      return $.map(pageData, function(value, key) {
        return value;
      });
    }
  };

  /**
   * Redraw the annotations on the page.
   * Called whenever a page is rendered on the PDF view.
   *
   * @param  {PDFView Page} page       The page being rendered.
   * @param  {number}       pageNumber The page number being rendered.
   */
  PdfAnnotationManager.prototype.onPageRendered = function(page, pageNumber) {
    var annotations = this.getPageAnnotations(pageNumber);

    for (var i = 0; i < annotations.length; i++) {
      var item = annotations[i];
      this.renderAnnotation(item.annotation, item.coords);
    }
  };

  /**
   * Get a selection for a specific page.
   * @return {{page: {int}, $control: {jQuery}}}
   */
  PdfAnnotationManager.prototype.getSelectionBox = function($page) {
    var pageNumber = parseInt($page.attr("id").replace("pageContainer", ""), 10);

    if (this.selectionBox.page === pageNumber) {
      return this.selectionBox;
    } else if (this.selectionBox.$control != null) {
      this.selectionBox.$control.remove(); // Remove old control
    }

    var $control = $("<div />").attr("id", "sel_box");

    $page.append($control);

    this.selectionBox = {
      page: pageNumber,
      $control: $control
    };

    return this.selectionBox;
  }

  /**
   * Update and redraw the selection box.
   *
   * @param {jQuery}                $page   The page the control is for.
   * @param {{x, y, width, height, visible}} params  Values to update
   */
  PdfAnnotationManager.prototype.setSelectionBox = function($page, params) {
    if (params) {
      $.extend(this.currentSelection, params);

      var $selectionBox = this.getSelectionBox($page).$control;

      $selectionBox.css({
        top: (this.currentSelection.y * 100) + "%",
        left: (this.currentSelection.x * 100) + "%",
        width: (this.currentSelection.width * 100) + "%",
        height: (this.currentSelection.height * 100) + "%"
      });

      $selectionBox.toggle(this.currentSelection.visible);
    }
  };

  /**
   * Return the current selection bounding rectangle if there is one, and
   * converts the floating point percentages to integers.
   *
   * @return {{x1, y1, x2, y2}} Bounding box (points are in percentages)
   */
  PdfAnnotationManager.prototype.selectionRectangleAsInts = function() {
    if (!this.currentSelection.visible) {
      return null;
    }

    return {
      x1: parseInt(this.currentSelection.x * COORDINATE_MULTIPLIER, 10),
      y1: parseInt(this.currentSelection.y * COORDINATE_MULTIPLIER, 10),
      x2: parseInt((this.currentSelection.x + this.currentSelection.width) * COORDINATE_MULTIPLIER, 10),
      y2: parseInt((this.currentSelection.y + this.currentSelection.height) * COORDINATE_MULTIPLIER, 10),
      page: this.selectionBox.page
    }
  };

  /**
   * Get the selection box size in pixels. If there is no selection box
   * return {width: 0, height: 0}.
   *
   * @return {{width: {int}, height: {int}}} The selection box size in pixels
   */
  PdfAnnotationManager.prototype.selectionBoxSize = function() {
    var $box = this.selectionBox.$control;

    return ($box ? {width: $box.width(), height: $box.height()} : {width: 0, height: 0});
  }

  PdfAnnotationManager.prototype.bindPageEvents = function() {
    var self = this;
    var $pages = this.getPages();

    var selectionBoxActive = false; // Is the selection box in use

    // Location of the mouse relative to the threshold point
    var location = {
      onRight: true,
      onBottom: true,
      threshold: {
        x: 0,
        y: 0
      }
    }

    // Press down, activate the selection box
    $pages.mousedown(function(ev) {
      var point = getRelativePointForMouseEvent(ev);

      self.setSelectionBox($(ev.delegateTarget), {
        x: point.x,
        y: point.y,
        width: 0,
        height: 0,
        visible: true
      });

      location.threshold = point;

      selectionBoxActive = true;
    });

    // Change the selection area
    $pages.mousemove(function(ev) {
      if(!selectionBoxActive) { return; }

      var point = getRelativePointForMouseEvent(ev);  // Mouse position

      // Cross X Threshold
      if(location.onRight && point.x < location.threshold.x) {
        location.onRight = false;
        location.threshold.x = self.currentSelection.x;
      } else if(!location.onRight && point.x > location.threshold.x) {
        location.onRight = true;
        location.threshold.x = point.x;
      }

      // Cross Y Threshold
      if(location.onBottom && point.y < location.threshold.y) {
        location.onBottom = false;
        location.threshold.y = self.currentSelection.y;
      } else if(!location.onBottom && point.y > location.threshold.y) {
        location.onBottom = true;
        location.threshold.y = point.y
      }

      var box = {
        x1: (location.onRight ? location.threshold.x : point.x),
        y1: (location.onBottom ? location.threshold.y : point.y),
        x2: (location.onRight ? point.x : location.threshold.x),
        y2: (location.onBottom ? point.y : location.threshold.y)
      }

      self.setSelectionBox($(ev.delegateTarget), {
        x: box.x1,
        y: box.y1,
        width: (box.x2 - box.x1),
        height: (box.y2 - box.y1)
      });
    });

    // Hide the selection box
    $pages.mouseup(function(ev) {
      var size = self.selectionBoxSize();

      // If the box is REALLY small then hide it
      if(size.width < HIDE_BOX_THRESHOLD && size.height < HIDE_BOX_THRESHOLD) {
        self.hideSelectionBox();
      }

      selectionBoxActive = false;
    })
  }

  PdfAnnotationManager.prototype.hideSelectionBox = function() {
    if(this.selectionBox.$control) {
      this.selectionBox.$control.hide();
    }
  }

  /**
   * Get all the div elements for the pages.
   *
   * @return {jQuery} The jQuery object of pages.
   */
  PdfAnnotationManager.prototype.getPages = function() {
    return $("#" + this.pageParentId + " .page");
  }

  /**
   * Returns the annotation text manager.
   *
   * @return {AnnotationTextManager} Return the annotation text manager.
   */
  PdfAnnotationManager.prototype.getAnnotationTextManager = function() {
    return this.annotationTextManager;
  }

  PdfAnnotationManager.prototype.getPageContainer = function(pageNum) {
    return $("#" + this.pageParentId + " #pageContainer" + pageNum);
  }

  /**
   * Draw the annotation on the screen.
   *
   * @param {AnnotationText} annotation
   * @param {{x1: int, y1: int, x2: int, y2: int, page: int}}} coords
   */
  PdfAnnotationManager.prototype.renderAnnotation = function(annotation, coords) {
    if (this.annotationControls[annotation.getId()]) {
      this.annotationControls[annotation.getId()].remove(); // Remove old controls
    }

    var $control = $("<div />").addClass("annotation_holder").css({
      top: ((coords.y1 / COORDINATE_MULTIPLIER) * 100) + "%",
      left: ((coords.x1 / COORDINATE_MULTIPLIER) * 100) + "%",
      width: (((coords.x2 - coords.x1) / COORDINATE_MULTIPLIER) * 100) + "%",
      height: (((coords.y2 - coords.y1) / COORDINATE_MULTIPLIER) * 100) + "%"
    });

    var $page = this.getPageContainer(coords.page);

    // Show annotation on mouse over
    var $textSpan = null;

    function createTextNode() {
      var text = annotation.getContent();

      return $('<div />').addClass('annotation_text_display')
                         .append($('<p />', {html: text}));
    }

    $control.mousemove(function(ev) {
      if($textSpan == null) {
        $textSpan = createTextNode();
        $page.append($textSpan);
      }

      var point = getRelativePointForMouseEvent(ev, $page, -1);

      $textSpan.css({
        position: "absolute",
        left: (point.x * 100) + "%",
        top: (point.y * 100) + "%"
      });
    });

    $control.mouseleave(function(ev) {
      if($textSpan != null) {
        $textSpan.remove();
        $textSpan = null;
      }
    });

    this.annotationControls[annotation.getId()] = $control;

    $page.append($control);
  }

  /**
   * Add an annotation to the PDF.
   *
   * @param {string} annotation_text_id [description]
   * @param {string} content            [description]
   * @param {{x1: int, y1: int, x2: int, y2: int, page: int}}} coords
   */
  PdfAnnotationManager.prototype.addAnnotation = function(annotation_text_id, content, coords) {
    var annotation_text = new AnnotationText(annotation_text_id, 0, content);

    if (this.getAnnotationTextManager().annotationTextExists(annotation_text.getId())) {
      return;
    }

    this.getAnnotationTextManager().addAnnotationText(annotation_text);

    this.renderAnnotation(annotation_text, coords);

    // Save annotation location information
    var annotationData = {
      annotation: annotation_text,
      coords: coords
    };

    // Stored using multiple lookups so that there is fast rendering
    // and fast deletion.
    this.annotations[coords.page] = this.annotations[coords.page] || {};
    this.annotations[coords.page][annotation_text.getId()] = annotationData;
    this.annotationsById[annotation_text.getId()] = annotationData;

    this.hideSelectionBox();
  }

  /**
   * Remove an annotation
   * @param  {string} annotation_id      Ignored
   * @param  {Object} range              Ignored
   * @param  {string} annotation_text_id Annotation text id.
   */
  PdfAnnotationManager.prototype.remove_annotation = function(annotation_id, range, annotation_text_id) {
    var annotationData = this.annotationsById[annotation_text_id];

    // Remove from rendering lookups
    delete this.annotations[annotationData.coords.page][annotation_text_id];
    delete this.annotationsById[annotation_text_id];

    this.annotationControls[annotation_text_id].remove(); // Delete DOM node

    if (this.getAnnotationTextManager().annotationTextExists(annotation_text_id)) {
      this.getAnnotationTextManager().removeAnnotationText(annotation_text_id);
    }
  }

  // Exports
  window.PdfAnnotationManager = PdfAnnotationManager;

})(window);
