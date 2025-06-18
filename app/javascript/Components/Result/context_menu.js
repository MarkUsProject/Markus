/*
  This file contains the Javascript code necessary for the functionality
  of the annotation context menu. For the annotation context menu to
  function properly, these dependencies are necessary:

  Context-Menu and library related:
    * ui-contextmenu
      * Depends on jQuery and jQuery-ui
    * context_menu.scss (..\app\assets\stylesheets\)
   */
export var annotation_context_menu = {
  setup: function () {
    var menu_items = {
      check_mark_annotation: {
        title: "✔️",
        cmd: "check_mark_annotation",
        action: () => resultComponent.current.addQuickAnnotation("✔️"),
        addClass: "emoji-annotation-context-menu-item",
      },
      thumbs_up_annotation: {
        title: "👍",
        cmd: "thumbs_up_annotation",
        action: () => resultComponent.current.addQuickAnnotation("👍"),
        addClass: "emoji-annotation-context-menu-item",
      },
      heart_annotation: {
        title: "❤️",
        cmd: "heart_annotation",
        action: () => resultComponent.current.addQuickAnnotation("❤️"),
        addClass: "emoji-annotation-context-menu-item",
      },
      smile_annotation: {
        title: "😄",
        cmd: "smile_annotation",
        action: () => resultComponent.current.addQuickAnnotation("😄️"),
        addClass: "emoji-annotation-context-menu-item",
      },
      new_annotation: {
        title: I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        }),
        cmd: "new_annotation",
        action: () => resultComponent.current.newAnnotation(),
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
          var clicked_element = ui.target[0];
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            resultComponent.current.editAnnotation(annot_id);
          }
        },
        disabled: true,
      },
      delete_annotation: {
        title: I18n.t("delete"),
        cmd: "delete_annotation",
        action: function (event, ui) {
          var clicked_element = $(ui.target)[0];
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            resultComponent.current.removeAnnotation(annot_id);
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
      if (annotation_type === ANNOTATION_TYPES.CODE) {
        let curr = clicked_element;
        while (curr !== null && curr.tagName === "SPAN") {
          for (let attr in curr.dataset) {
            if (attr.toLowerCase().startsWith("annotationid")) {
              return curr.dataset[attr];
            }
          }
          curr = curr.parentNode;
        }
        return "";
      } else {
        return clicked_element.id.replace("annotation_holder_", "");
      }
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
        menu_items.smile_annotation,
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
        $(document).contextmenu("enableEntry", "check_mark_annotation", selection_exists);
        $(document).contextmenu("enableEntry", "thumbs_up_annotation", selection_exists);
        $(document).contextmenu("enableEntry", "heart_annotation", selection_exists);
        $(document).contextmenu("enableEntry", "smile_annotation", selection_exists);
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
