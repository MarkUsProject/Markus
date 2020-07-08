import React from 'react';
import ReactTable from 'react-table';


export class AnnotationTable extends React.Component {

  deductionFilter = (filter, row) => {
    return String(row[filter.id]).toLocaleLowerCase().includes(filter.value.toLocaleLowerCase());
  }

  columns = [
    {
      Header: '#',
      accessor: 'number',
      id: 'number',
      maxWidth: 50,
      resizeable: false,
      Cell: row => {
        let remove_button = "";
        if (!this.props.released_to_students) {
          remove_button = <a
            href="#"
            className="remove-icon"
            title={I18n.t('delete')}
            onClick={() => this.props.removeAnnotation(row.original.id)}
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
      Header: I18n.t('attributes.filename'),
      accessor: 'filename',
      id: 'filename',
      Cell: row => {
        let full_path = row.original.path ? row.original.path + '/' + row.original.filename : row.original.filename;
        let name;
        if (row.original.line_start !== undefined) {
          name = `${full_path} (line ${row.original.line_start})`;
        } else {
          name = full_path;
        }
        return (
          <a onClick={() =>
              this.props.selectFile(
                full_path,
                row.original.submission_file_id,
                row.original.line_start,
                row.original.id)}>
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
        if (!this.props.released_to_students && !data.original.deduction) {
          edit_button = <a
            href="#"
            className="edit-icon"
            title={I18n.t('edit')}
            onClick={() => this.props.editAnnotation(data.original.id)}
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

  deductionColumn = {
    Header: I18n.t('activerecord.attributes.annotation_text.deduction'),
    accessor: row => {
      if (!row.deduction) {
        return '';
      } else {
        return '[' + row.criterion_name + '] -' + row.deduction;
      }
    },
    id: 'deduction',
    filterMethod: this.deductionFilter,
    Cell: data => {
      if (!data.original.deduction) {
        return '';
      } else {
        return (
          <div>
            {'[' + data.original.criterion_name + '] '}
            <span className={'red-text'}>
              {'-' + data.original.deduction}
            </span>
          </div>
        );
      }
    },
    sortMethod: (a, b) => {
      if (a === '') {
        return 1;
      } else if (b === '') {
        return -1;
      } else if (a > b) {
        return 1;
      } else if (a < b) {
        return -1;
      }
      return 0;
    },
    maxWidth: 120
  };

  componentDidMount() {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'annotation_table']);
  }

  componentDidUpdate() {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'annotation_table']);
  }

  render() {
    let allColumns = this.columns;
    if (this.props.detailed) {
      allColumns = allColumns.concat(this.detailedColumns);
    }
    if (this.props.annotations.some(a => !!a.deduction)) {
      allColumns.push(this.deductionColumn);
    }

    return (
      <div id={'annotation_table'}>
        <ReactTable
          className='auto-overflow'
          data={this.props.annotations}
          columns={allColumns}
          filterable
          resizable
          defaultSorted={[
            {id: 'deduction'},
            {id: 'filename'},
            {id: 'number'}
          ]}
        />
      </div>
    );
  }
}
