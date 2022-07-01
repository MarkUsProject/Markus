/*
  This file contains the Javascript code necessary for the functionality
  of the annotation context menu. For the annotation context menu to
  function properly, these dependencies are necessary:

  Context-Menu and library related:
    * jquery.ui-contextmenu.min.js (..\app\assets\javascripts\)
      * Depends on jQuery and jQuery-ui
    * context_menu.scss (..\app\assets\stylesheets\)
   */
var annotation_context_menu = {
  setup: function () {
    var menu_items = {
      check_mark_annotation: {
        title: "✅",
        cmd: "check_mark_annotation",
        action: () => resultComponent.addQuickAnnotation("✅"),
      },
      thumbs_up_annotation: {
        title: "👍",
        cmd: "thumbs_up_annotation",
        action: () => resultComponent.addQuickAnnotation("👍"),
      },
      heart_annotation: {
        title: "❤",
        cmd: "heart_annotation",
        action: () => resultComponent.addQuickAnnotation("❤"),
      },
      new_annotation: {
        title: I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        }),
        cmd: "new_annotation",
        action: () => resultComponent.newAnnotation(),
        disabled: true,
      },
      common_annotations: {
        title: `${I18n.t("results.annotation.common")} <kbd>></kbd>`,
        cmd: "common_annotations",
        disabled: false,
      },
      edit_annotation: {
        title: I18n.t("edit"),
        cmd: "edit_annotation",
        action: function (event, ui) {
          var clicked_element = $(ui.target);
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            resultComponent.editAnnotation(annot_id);
          }
        },
        disabled: true,
      },
      delete_annotation: {
        title: I18n.t("delete"),
        cmd: "delete_annotation",
        action: function (event, ui) {
          var clicked_element = $(ui.target);
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            resultComponent.removeAnnotation(annot_id);
          }
        },
        disabled: true,
      },
      separator: {
        title: "----",
      },
      copy: {
        title: I18n.t("copy"),
        cmd: "copy",
        action: function () {
          document.execCommand("copy");
        },
        disabled: true,
      },
      download: {
        title: I18n.t("download"),
        cmd: "download",
        action: function () {
          submissionFilePanel.downloadFile();
        },
        disabled: false,
      },
    };

    function get_annotation_id(clicked_element) {
      var annot_id = "";
      if (annotation_type === ANNOTATION_TYPES.CODE) {
        $.each(clicked_element[0].attributes, function (index, attr) {
          if (attr.nodeName.toLowerCase().indexOf("data-annotationid") != -1) {
            annot_id = attr.value;
            // Continue iteration in case of multiple annotations
          }
        });
      } else {
        annot_id = clicked_element.attr("id").replace("annotation_holder_", "");
      }
      return annot_id;
    }

    $(document).contextmenu({
      delegate: "#codeviewer, #sel_box",
      autoFocus: false,
      preventContextMenuForPopup: true,
      preventSelect: false,
      taphold: true,
      ignoreParentSelect: false,
      show: {
        effect: "slidedown",
        duration: "fast",
      },
      menu: [
        menu_items.check_mark_annotation,
        menu_items.thumbs_up_annotation,
        menu_items.heart_annotation,
        menu_items.separator,
        menu_items.new_annotation,
        menu_items.common_annotations,
        menu_items.edit_annotation,
        menu_items.delete_annotation,
        menu_items.separator,
        menu_items.copy,
        menu_items.download,
      ],
      beforeOpen: function (event, ui) {
        // Enable annotation menu items only if a selection has been made
        var selection_exists = !!window.annotation_manager.getSelection(false);
        $(document).contextmenu("enableEntry", "new_annotation", selection_exists);
        $(document).contextmenu("enableEntry", "common_annotations", selection_exists);
        $(document).contextmenu("enableEntry", "copy", selection_exists);

        var has_common_annot =
          $(document).contextmenu("getMenu").find(".has_common_annotations").length > 0;
        $(document).contextmenu("showEntry", "common_annotations", has_common_annot);

        // Enable "delete" menu item if an annotation was clicked.
        var annotation_selected = (function () {
          var clicked_element = $(ui.target);
          if (annotation_type === ANNOTATION_TYPES.CODE) {
            return clicked_element.closest(".source-code-glowing-1").length > 0;
          } else {
            return clicked_element.closest(".annotation_holder").length > 0;
          }
        })();
        $(document).contextmenu("enableEntry", "edit_annotation", annotation_selected);
        $(document).contextmenu("enableEntry", "delete_annotation", annotation_selected);
      },
    });
  },
  set_common_annotations: function (common_annotations_menu_children) {
    if (common_annotations_menu_children.length > 0) {
      $(document).contextmenu("setEntry", "common_annotations", {
        title: `${I18n.t("results.annotation.common")} <kbd>></kbd>`,
        cmd: "common_annotations",
        addClass: "has_common_annotations",
        action: () => false,
        children: common_annotations_menu_children,
        disabled: false,
      });
    }
  },
};
