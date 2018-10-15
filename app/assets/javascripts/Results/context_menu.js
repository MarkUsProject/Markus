/*
  This file contains the Javascript code necessary for the functionality
  of the annotation context menu. For the annotation context menu to
  function properly, these dependencies are necessary:

  Context-Menu and library related:
    * jquery.ui-contextmenu.min.js (..\app\assets\javascripts\)
      * Depends on jQuery and jQuery-ui
    * context_menu.css (..\app\assets\stylesheets\)

  Context-Menu button functionality:
    * _annotations.js.erb (..\app\views\results\common\)

   */
var annotation_context_menu = {
  setup: function(annot_path, result_id, assignment_id, file_dl_path) {
    var menu_items = {
      new_annotation: {
        title: I18n.t('marker.annotation.context_menu.new'),
        cmd: 'new_annotation',
        action: make_new_annotation,
        disabled: true
      },
      common_annotations: {
        title: `${I18n.t('marker.annotation.context_menu.common')} <kbd>></kbd>`,
        cmd: 'common_annotations',
        disabled: true
      },
      edit_annotation: {
        title: I18n.t('marker.annotation.context_menu.edit'),
        cmd: 'edit_annotation',
        action: function(event, ui) {
          var clicked_element = $(ui.target);
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            $.ajax({
              url:  Routes.edit_annotation_path(annot_id, {locale: I18n.locale}),
              method: 'GET',
              data: {
                id: annot_id,
                result_id: result_id,
                assignment_id: assignment_id
              },
              dataType: 'script'
            });
          }
        },
        disabled: true
      },
      delete_annotation: {
        title: I18n.t('marker.annotation.context_menu.delete'),
        cmd: "delete_annotation",
        action: function(event, ui) {
          var clicked_element = $(ui.target);
          var annot_id = get_annotation_id(clicked_element);
          if (annot_id !== null && annot_id.length !== 0) {
            $.ajax({
              url: annot_path,
              method: 'DELETE',
              data: { id: annot_id,
                      result_id: result_id,
                      assignment_id: assignment_id },
              dataType: 'script'
            });
          }
          return;
        },
        disabled: true
      },
      separator: {
        title: '----'
      },
      copy: {
        title: I18n.t('marker.annotation.context_menu.copy'),
        cmd: 'copy',
        action: function(){ document.execCommand('copy'); },
        disabled: true
      },
      download: {
        title: I18n.t('marker.annotation.context_menu.download'),
        cmd: 'download',
        action: function() { download_func('false'); },
        disabled: false
      },
      download_annotated: {
        title: I18n.t('marker.annotation.context_menu.download_annotated'),
        cmd: 'download_annotated',
        action: function() { download_func('true'); },
        disabled: false
      }
    };

    function get_annotation_id(clicked_element) {
      var annot_id = '';
      if (annotation_type === ANNOTATION_TYPES.CODE) {
        $.each(clicked_element[0].attributes, function(index, attr) {
          if (attr.nodeName.toLowerCase()
            .indexOf('data-annotationid') != -1) {
            annot_id = attr.value;
            // Continue iteration in case of multiple annotations
          }
        });
      } else {
        annot_id = clicked_element.attr('id')
          .replace('annotation_holder_', '');
      }
      return annot_id;
    }

    function download_func(include_annot) {
      var sub_file_id = $('#select_file_id').val();
      if (sub_file_id !== null && sub_file_id.length !== 0) {
        window.open(file_dl_path + '?utf8=✓&include_annotations=' +
                    include_annot + '&select_file_id=' + sub_file_id);
      }
    }

    $(document).contextmenu({
      delegate: '#codeviewer, #sel_box',
      autoFocus: false,
      preventContextMenuForPopup: true,
      preventSelect: false,
      taphold: true,
      ignoreParentSelect: false,
      show: {
        effect: 'slidedown',
        duration: 'fast'
      },
      menu: [
        menu_items.new_annotation,
        menu_items.common_annotations,
        menu_items.edit_annotation,
        menu_items.delete_annotation,
        menu_items.separator,
        menu_items.copy,
        menu_items.download,
        menu_items.download_annotated
      ],
      beforeOpen: function (event, ui) {
        // Enable annotation menu items only if a selection has been made
        var selection_exists = (function() {
          if (annotation_type === ANNOTATION_TYPES.CODE) {
            return window.getSelection().toString() !== '';
          } else if (annotation_type === ANNOTATION_TYPES.PDF) {
            return !!get_pdf_box_attrs();
          } else {
            return !!get_selection_box_coordinates();
          }
        })();
        $(document).contextmenu('enableEntry', 'new_annotation',
                                selection_exists);
        $(document).contextmenu('enableEntry', 'common_annotations',
                                selection_exists);
        $(document).contextmenu('enableEntry', 'copy',
                                selection_exists);

        var has_common_annot = $(document).contextmenu('getMenu')
                                          .find('.has_common_annotations')
                                          .length > 0;
        $(document).contextmenu('showEntry', 'common_annotations',
                                has_common_annot);

        // Enable "delete" menu item if an annotation was clicked.
        var annotation_selected = (function() {
          var clicked_element = $(ui.target);
          if (annotation_type === ANNOTATION_TYPES.CODE) {
            return clicked_element.hasClass('source-code-glowing-1');
          } else {
            return clicked_element.hasClass('annotation_holder');
          }
        })();
        $(document).contextmenu('enableEntry', 'edit_annotation',
                                annotation_selected);
        $(document).contextmenu('enableEntry', 'delete_annotation',
                                annotation_selected);
      }
    });
  },
  set_common_annotations: function(common_annotations_menu_children) {
    if (common_annotations_menu_children.length > 0) {
      $(document).contextmenu("setEntry", "common_annotations", {
        title: `${I18n.t('marker.annotation.context_menu.common')} <kbd>></kbd>`,
        cmd: 'common_annotations',
        addClass: 'has_common_annotations',
        action: function(event, ui){ return false; },
        children: common_annotations_menu_children,
        disabled: true
      });
    }
  }
};
