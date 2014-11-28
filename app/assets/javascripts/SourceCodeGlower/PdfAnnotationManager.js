// Class: PdfAnnotationManager
(function(window) {
  'use strict';

  var $ = jQuery;         // Rebind
  var MOUSE_OFFSET = 10;  // The offset from the moust cursor point

  // CONSTANTS
  var HIDE_BOX_THRESHOLD = 5;   // Threashold for not displaying selection box in pixels
  var COORDINATE_PRECISION = 5; // Keep 5 decimal places (used when converting back from ints)
  var COORDINATE_MULTIPLIER = Math.pow(10, COORDINATE_PRECISION);

  /**
   * Manager to load and display pdf annotations.
   *
   * @class
   *
   * @param {string} pageParentId The ID of the parent container of the pages.
   */
  function PdfAnnotationManager(pageParentId) {
    var self = this;

    // Members
    this.annotationTextManager = new AnnotationTextManager();
    this.pageParentId = pageParentId;

    /** @type {{page: int, $control: jQuery}} */
    this.selectionBox = {};

    /** @type {{x: number, y: number, width: number, height: number}} */
    this.currentSelection = {}; // The current selection area. The x, y are stored as percentages for device independent resolution

    // Css for the selection box
    this.selectionBoxCss = {
        "display": "inline-block",
        "position": "absolute",
        "border": "dashed 1px red"
    };

    this.bindPageEvents();
  }

  /**
   * Returns the selection point in percentage units for an event on
   * a element.
   *
   * @param  {Event} ev               The event that occurred.
   * @return {{x: number, y:number}}  The relative point in the element the event occurred in.
   */
  function getRelativePointForMouseEvent(ev) {
    var $elem = $(ev.delegateTarget);
    var offset = $elem.offset();

    var width = $elem.width();
    var height = $elem.height();

    var x = ev.pageX - offset.left - MOUSE_OFFSET;
    var y = ev.pageY - offset.top - MOUSE_OFFSET;

    return {
      x: 1 - Math.abs((x - width)/width),
      y: 1 - Math.abs((y - height)/height)
    };
  }

  /**
   * Get a selection for a specific page.
   * @return {{page: {int}, $control: {jQuery}}}
   */
  PdfAnnotationManager.prototype.getSelectionBox = function($page) {
    var pageNumber = parseInt($page.attr("id").replace("pageContainer", ""));

    if(this.selectionBox.page === pageNumber) {
      return this.selectionBox;
    } else if(this.selectionBox.$control != null) {
      this.selectionBox.$control.remove(); // Remove old control
    }

    var $control = $("<div />").css(this.selectionBoxCss);

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
    if(params) {
      $.extend(this.currentSelection, params);

      var $selectionBox = this.getSelectionBox($page).$control;

      $selectionBox.css({
        top:  (this.currentSelection.y * 100) + "%",
        left: (this.currentSelection.x * 100) + "%",
        width: (this.currentSelection.width * 100) + "%",
        height: (this.currentSelection.height * 100) + "%"
      });

      if(this.currentSelection.visible) {
        $selectionBox.show();
      } else {
        $selectionBox.hide();
      }
    }
  };

  /**
   * Return the current selection bounding rectangle if there is one, and
   * converts the floating point percentages to integers.
   *
   * @return {{x1, y1, x2, y2}} Bounding box (points are in percentages)
   */
  PdfAnnotationManager.prototype.selectionRectangleAsInts = function() {
    if(!this.currentSelection.visible) {
      return null;
    }

    return {
      x1: this.currentSelection.x * COORDINATE_MULTIPLIER,
      y1: this.currentSelection.y * COORDINATE_MULTIPLIER,
      x2: (this.currentSelection.x + this.currentSelection.width) * COORDINATE_MULTIPLIER,
      y2: (this.currentSelection.y + this.currentSelection.height) * COORDINATE_MULTIPLIER,
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
        self.setSelectionBox($(ev.delegateTarget), {
          visible: false
        });
      }

      selectionBoxActive = false;
    })
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

  // Exports
  window.PdfAnnotationManager = PdfAnnotationManager;

})(window);