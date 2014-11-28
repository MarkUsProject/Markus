// Class: PdfAnnotationManager
(function(window) {
  'use strict';

  function assert(exp, msg) {
    if(!exp) {
      console.error(msg);
    }
  }


  var $ = jQuery;
  var MOUSE_OFFSET = 10;  // The offset from the moust cursor point

  /**
   * Manager to load and display pdf annotations.
   *
   * @class
   *
   * @param {string} newAnnotationBtnId       The ID of the button used for creating new annotations.
   * @param {string} newAnnotationDialogId    The ID of the dialog for new annotations.
   * @param {string} newAnnotationDialogBtnId The ID of the create button in the dialog.
   * @param {string} pageParentId             The ID of the parent container of the pages.
   */
  function PdfAnnotationManager(newAnnotationBtnId, newAnnotationDialogId,
                                newAnnotationDialogBtnId, newAnnotationTextAreaId,
                                pageParentId) {
    var self = this;

    // Members
    this.annotationDialog = new ModalMarkus("#" + newAnnotationDialogId);
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

    // Local
    var annotationUi = {
      newAnnotBtn: document.getElementById(newAnnotationBtnId),
      dialog: document.getElementById(newAnnotationDialogId),
      createBtn: document.getElementById(newAnnotationDialogBtnId),
      textarea: document.getElementById(newAnnotationTextAreaId)
    };

    // Setup Events
    annotationUi.newAnnotBtn.onclick = function() {
      self.annotationDialog.open();
    }

    annotationUi.createBtn.onclick = function() {
      self.annotationDialog.close();
    }

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

      assert(this.currentSelection.x >= 0, "x < 0");
      assert(this.currentSelection.y >= 0, "y < 0");
      assert(this.currentSelection.width >= 0, "width < 0");
      assert(this.currentSelection.height >= 0, "height < 0");

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
      self.setSelectionBox($(ev.delegateTarget), {
        visible: false
      });

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
   * Load annotations from the database for a specific file.
   *
   * @param  {number} fileId The ID of the file to load annotations for.
   * @return {type[]}         The loaded annotations.
   */
  PdfAnnotationManager.prototype.load = function(fileId) {
    // TODO: Call to server

    return [];
  };

  // Exports
  window.PdfAnnotationManager = PdfAnnotationManager;

})(window);