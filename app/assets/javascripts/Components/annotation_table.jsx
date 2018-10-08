import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class AnnotationTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
    };
    this.fetchData = this.fetchData.bind(this);
  }

  static columns = [
    {
      Header: '#',
      accessor: 'number',
      id: 'number',
      maxWidth: 40,
      resizeable: false,
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
      Cell: data =>
        <div dangerouslySetInnerHTML={{__html: marked(data.value, {sanitize: true})}} />
    },
  ];

  static detailedColumns = [
    {
      Header: I18n.t('activerecord.attributes.annotation.creator'),
      accessor: 'creator',
      Cell: row => {
        if (row.original.is_remark) {
          return `${row.value} (${I18n.t('marker.annotation.remark_flag')})`;
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

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.get_annotations_assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id),
      dataType: 'json',
    }).then(res => {
      this.setState(
        {data: res},
        () => MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'annotation_table'])
      );
    });
  }

  addAnnotation(annotation) {
    this.setState({data: this.state.data.concat([annotation])});
    if (submissionFileViewer.state.submission_file_id === annotation.submission_file_id) {
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
      if (i) {
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

    if (i) {
      newAnnotations.splice(i, 1);
      this.setState({data: newAnnotations});
    }
  }

  /*
   * Called by text_viewer. Render all annotations for the given
   * submission file (through the global submissionFileViewer object).
   */
  display_annotations = (submission_file_id) => {
    for (let row of this.state.data) {
      if (row.submission_file_id === submission_file_id) {
        this.display_annotation(row);
      }
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
    let allColumns = AnnotationTable.columns;
    if (this.props.detailed) {
      allColumns = allColumns.concat(AnnotationTable.detailedColumns);
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
      />
    );
  }
}


export function makeAnnotationTable(elem, props) {
  return render(<AnnotationTable {...props}/>, elem);
}
