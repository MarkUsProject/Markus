import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import CreateModifyAnnotationPanel from './Modals/create_modify_annotation_panel_modal';

const INITIAL_ANNOTATION_MODAL_STATE = {
  show: false,
  onSubmit: null,
  title: '',
  content: '',
  categoryId: '',
  isNew: true,
  changeOneOption: false,
};
class OneTimeAnnotationsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      annotationModal: INITIAL_ANNOTATION_MODAL_STATE,
      loading: true
    };
  }

  componentDidMount()  {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.uncategorized_annotations_assignment_annotation_categories_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res,
        loading: false
      });
    });
  };

  refreshAnnotations = () => {
    $.ajax({
      url: Routes.uncategorized_annotations_assignment_annotation_categories_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res,
        loading: false
      })
    });
  };

  editAnnotation = (annot_id, content) => {
    let onSubmit = (formData) => {
      return ($.ajax({
        url: Routes.update_annotation_text_assignment_annotation_categories_path(this.props.assignment_id)+ '?id=' + annot_id,
        data:{ ...formData },
        method: "PUT",
        remote: true,
        dataType: "json",
      }).always(() =>
        {
          this.setState({
            annotationModal: INITIAL_ANNOTATION_MODAL_STATE
          })
          this.refreshAnnotations();
        }
      ));
    };


    let category_id = '';
    let deduction = '';

    this.setState({
      annotationModal: {
        ...this.state.annotationModal,
        show: true,
        content: content,
        category_id,
        isNew: false,
        changeOneOption: category_id && !deduction,
        onSubmit,
        title: I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        }),
      },
    });
  };

  removeAnnotation = (annot_id, result_id) => {
    $.ajax({
      url: Routes.destroy_annotation_text_assignment_annotation_categories_path(this.props.assignment_id)+ '?id=' + annot_id,
      method: 'delete',
      data: {
        result_id: result_id
      },
      remote: true,
      dataType: 'json'
    }).always(() =>
      {
      this.refreshAnnotations()
      });
  };

  columns = [
    {
      Header: I18n.t('activerecord.models.group.one'),
      accessor: 'group_name',
      id: 'group_name',
      Cell: row => {
        let remove_button = <a
        href="#"
        className="remove-icon"
        title={I18n.t('delete')}
        onClick={() => this.removeAnnotation(row.original.id, row.original.result_id)}
      />
        if (row.original.result_id) {
          const path = Routes.edit_assignment_submission_result_path(
            this.props.assignment_id,
            row.original.submission_id,
            row.original.result_id
          );
          return (
            <div>
            {remove_button}
            <a className ="alignright" href={path}>{row.original.group_name}</a>
          </div>
          );
        } else {
          return (
            <div>
            {remove_button}
            <span className="alignright">
              {row.original.group_name}
            </span>
          </div>
          );
        }
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          // Check group name
          if (row._original.group_name.includes(filter.value)) {
            return true;
          }
        } else {
          return true;
        }
      }
    },
    {
      Header:  I18n. t('activerecord.attributes.annotation_text.creator'),
      accessor: 'creator',
      id: 'creator',
      Cell: row => {
        return <span>{row.original.creator}</span>;
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          if (row._original.creator.includes(filter.value)) {
            return true;
          }
        } else {
          return true;
        }
      }
    },
    {
      Header: I18n. t('annotations.last_edited_by'),
      accessor: 'last_editor',
      id: 'last_editor',
      Cell: row => {
        return <span>{row.original.last_editor}</span>;
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          if (row._original.last_editor.includes(filter.value)) {
            return true;
          }
        } else {
          return true;
        }
      }
    },
    {
      Header: I18n. t('activerecord.models.annotation_text.one'),
      accessor: 'content',
      id: 'content',
      Cell: row => {
        let edit_button = <a
        href="#"
        className="edit-icon"
        title={I18n.t('edit')}
        onClick={() => this.editAnnotation(row.original.id, row.original.content)}
      />

        return (
          <div>
          <div dangerouslySetInnerHTML={{__html: marked(row.original.content, {sanitize: true})}}/>
          <div className={"alignright"}>{edit_button}</div>
        </div>
        );
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          if (row._original.content.includes(filter.value)) {
            return true;
          }
        } else {
          return true;
        }
      }
    }
  ];

  render() {
    return [
      <ReactTable
          key="one_time_annotations_table"
          data={this.state.data}
          columns={this.columns}
          filterable
          defaultSorted={[{id: 'group_name'}]}
          loading={this.state.loading}
        />,
      <CreateModifyAnnotationPanel
          key="modify_modal"
          categories={[]}
          onRequestClose={() =>
            this.setState({
              annotationModal: INITIAL_ANNOTATION_MODAL_STATE
            })
          }
          is_reviewer={false}
          assignment_id={this.props.assignment_id}
          {...this.state.annotationModal}
        />
    ];
    }
}

export function makeOneTimeAnnotationsTable(elem, props) {
    render(<OneTimeAnnotationsTable {...props} />, elem);
  }