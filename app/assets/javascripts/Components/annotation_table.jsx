import React from 'react';
import ReactTable from 'react-table';


export class AnnotationTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
      // TODO: remove these two when this component and the FileViewer are
      // put under the same parent component.
      initialized: false,
      queued_id: null
    };
    this.fetchData = this.fetchData.bind(this);
  }

  columns = [
    {
      Header: '#',
      id: 'number',
      maxWidth: 50,
      resizeable: false,
      Cell: row => {
        let remove_button = "";
        if (!this.props.released_to_students) {
          remove_button = <a
            href="#"
            className="remove-icon"
            title={I18n.t('remove')}
            onClick={() => this.removeAnnotation(row.original.id)}
          />;
        }
        return (
          <div>
            {remove_button}
            <span className="alignright">
              {row.original.number}
            </span>
          </div>
        );
      }
    },
    {
      Header: I18n.t('filename'),
      id: 'filename',
      // TODO: refactor load_submitted_file_and_focus vs. load_submitted_file
      Cell: row => {
        let name;
        if (row.original.line_start !== undefined) {
          name = `${row.original.file} (line ${row.original.line_start})`;
        } else {
          name = row.original.file;
        }
        return (
          <a
            href="javascript:void(0)"
            onClick={() =>
              load_submitted_file_and_focus(
                row.original.submission_file_id,
                row.original.line_start)}>
              {name}
          </a>
        );
      },
      maxWidth: 150,
    },
    {
      Header: I18n.t('annotations.text'),
      accessor: 'content',
      Cell: data => {
        let edit_button = "";
        if (!this.props.released_to_students) {
          edit_button = <a
            href="#"
            className="edit-icon"
            title={I18n.t('edit')}
            onClick={() => this.editAnnotation(data.original.id)}
          />
        }
        return (
          <div>
            <div dangerouslySetInnerHTML={{__html: marked(data.value, {sanitize: true})}}/>
            <div className={"alignright"}>{edit_button}</div>
          </div>
        )
      }
    },
  ];

  detailedColumns = [
    {
      Header: I18n.t('activerecord.attributes.annotation.creator'),
      accessor: 'creator',
      Cell: row => {
        if (row.original.is_remark) {
          return `${row.value} (${I18n.t('results.annotation.remark_flag')})`;
        } else {
          return row.value;
        }
      },
      maxWidth: 120
    },
    {
      Header: I18n.t('activerecord.models.annotation_category', {count: 1}),
      accessor: 'annotation_category',
      maxWidth: 150,
    },
  ];

  editAnnotation = (annot_id) => {
    $.ajax({
      url: Routes.edit_annotation_path(annot_id, {locale: I18n.locale}),
      method: 'GET',
      data: {
        id: annot_id,
        result_id: this.props.result_id,
        assignment_id: this.props.assignment_id },
      dataType: 'script'
    })
  };

  removeAnnotation = (annot_id) => {
    $.ajax({
      url: Routes.annotations_path(),
      method: 'DELETE',
      data: { id: annot_id,
        result_id: this.props.result_id,
        assignment_id: this.props.assignment_id },
      dataType: 'script'
    }).then(this.fetchData())
  };

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    this.setState({loading: true}, () => {
      $.ajax({
        url: Routes.get_annotations_assignment_submission_result_path(
          this.props.assignment_id,
          this.props.submission_id,
          this.props.result_id),
        dataType: 'json',
      }).then(res => {
        this.setState(
          {data: res, initialized: true, loading: false},
          () => {
            MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'annotation_table']);
            if (this.state.queued_id !== null) {
              this.display_annotations(this.state.queued_id);
            }
          }
        );
      })
    });
  }

  addAnnotation(annotation) {
    this.setState({data: this.state.data.concat([annotation])});
    if (submissionFilePanel.state.selectedFile !== null &&
        submissionFilePanel.state.selectedFile[1] === annotation.submission_file_id) {
      this.display_annotation(annotation);
    }

    if (annotation.annotation_category) {
      annotationManager.fetchData();
    }
  }

  updateAnnotation(annotation) {
    // If the modified text was for a shared annotation, reload all annotations.
    // (This is pretty naive.)
    if (annotation.annotation_category !== '') {
      this.fetchData();
    } else {
      let newAnnotations = [...this.state.data];
      let i = newAnnotations.findIndex(a => a.id === annotation.id);
      if (i >= 0) {
        // Manually copy the annotation.
        newAnnotations[i] = {...newAnnotations[i]};
        newAnnotations[i].content = annotation.content;
        this.setState({data: newAnnotations});
      }
    }
  }

  destroyAnnotation(annotation_id) {
    let newAnnotations = [...this.state.data];
    let i = newAnnotations.findIndex(a => a.id === annotation_id);

    if (i >= 0) {
      newAnnotations.splice(i, 1);
      this.setState({data: newAnnotations});
    }
  }

  /*
   * Called by text_viewer. Render all annotations for the given
   * submission file (through the global SubmissionFilePanel object).
   */
  display_annotations = (submission_file_id) => {
    if (this.state.initialized) {
      for (let row of this.state.data) {
        if (row.submission_file_id === submission_file_id) {
          this.display_annotation(row);
        }
      }
    } else {
      this.setState({queued_id: submission_file_id});
    }
  };

  display_annotation = (annotation) => {
    add_annotation_text(annotation.annotation_text_id,
                        marked(annotation.content, {sanitize: true}));
    if (annotation.type === 'ImageAnnotation') {
      annotation_manager.add_to_grid({
        x_range: annotation.x_range,
        y_range: annotation.y_range,
        annot_id: annotation.id,
        // TODO: rename the following
        id: annotation.annotation_text_id
      });
    } else if (annotation.type === 'PdfAnnotation') {
      annotation_manager.addAnnotation(
        annotation.annotation_text_id,
        marked(annotation.content, {sanitize: true}),
        {
          x1: annotation.x_range.start,
          x2: annotation.x_range.end,
          y1: annotation.y_range.start,
          y2: annotation.y_range.end,
          page: annotation.page,
          annot_id: annotation.id
        });
    } else if (annotation.type === 'TextAnnotation') {
    add_annotation(annotation.id, {
        start: annotation.line_start,
        end: annotation.line_end,
        column_start: annotation.column_start,
        column_end: annotation.column_end
      },
      annotation.annotation_text_id);
    }
  };


  render() {
    const {data} = this.state;
    let allColumns = this.columns;
    if (this.props.detailed) {
      allColumns = allColumns.concat(this.detailedColumns);
    }

    return (
      <ReactTable
        data={data}
        columns={allColumns}
        filterable
        defaultSorted={[
          {id: 'filename'},
          {id: 'number'}
        ]}
        loading={this.state.loading}
      />
    );
  }
}
