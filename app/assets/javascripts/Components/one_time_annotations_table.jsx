import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';

class AnnotationTextCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editMode: false,
      content: props.content
    }
  }
  componentDidUpdate(prevProps) {
    if (prevProps.content !== this.props.content) {
      this.setState({content: this.props.content});
    }
  }
  render() {
    //Show input field and save and cancel buttons
    if (this.state.editMode)
    {
      let save_button = <a
        href="#"
        className='button inline-button'
        onClick={() => {
          if (this.props.content != this.state.content) {
            this.props.editAnnotation(this.props.id, this.state.content);       
          }
          this.setState({editMode: false});         
          }
        }>Save</a>;
      let cancel_button = <a
        href="#"
        className='button inline-button'
        onClick={() => this.setState({
          editMode: false, 
          content: this.props.content
          })
        }>Cancel</a>;
      return (
        <div>
          <input type="text" 
            defaultValue={this.state.content} 
            onChange={e => this.setState({content: e.target.value})}/>   
          <div className={"alignright"} >{save_button}</div>
          <div className={"alignright"}>{cancel_button}</div>
        </div>
        );
    }
    else
    {
      let edit_button = <a
        href="#"
        className="edit-icon"
        title={I18n.t('edit')}
        onClick={() => this.setState({editMode: true})}/>;
      return(
        <div>         
          <div dangerouslySetInnerHTML={{__html: marked(this.state.content, {sanitize: true})}}/>
          <div className={"alignright"}>{edit_button}</div>
        </div>
      );     
    }
   
  }
}
class OneTimeAnnotationsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
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

  editAnnotation = (annot_id, content) => {
    $.ajax({
      url: Routes.update_annotation_text_assignment_annotation_categories_path(this.props.assignment_id),
      data:{ content: content, id: annot_id },
      method: "PUT",
      remote: true,
      dataType: "json",
      }).always(() => this.fetchData());
  };

  removeAnnotation = (annot_id) => {
    $.ajax({
      url: Routes.destroy_annotation_text_assignment_annotation_categories_path(this.props.assignment_id),
      data: { id: annot_id },
      method: 'delete',
      remote: true,
      dataType: 'script'
    }).then(() => this.fetchData());
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
          onClick={() => this.removeAnnotation(row.original.id, row.original.result_id)}/>;
        if (row.original.result_id) {
          const path = Routes.edit_assignment_submission_result_path(
            this.props.assignment_id,
            row.original.submission_id,
            row.original.result_id
          );
          return (
            <div>
              {remove_button}
              <a className="alignright" href={path}>{row.original.group_name}</a>
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
          return row._original.group_name.includes(filter.value);
        } else {
          return true;
        }
      }
    },
    {
      Header:  I18n.t('activerecord.attributes.annotation_text.creator'),
      accessor: 'creator',
      id: 'creator',
      Cell: row => {
        return <span>{row.original.creator}</span>;
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          return row._original.creator.includes(filter.value);
        } else {
          return true;
        }
      }
    },
    {
      Header: I18n.t('annotations.last_edited_by'),
      accessor: 'last_editor',
      id: 'last_editor',
      Cell: row => {
        return <span>{row.original.last_editor}</span>;
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          return row._original.last_editor.includes(filter.value);
        } else {
          return true;
        }
      }
    },
    {
      Header: I18n.t('activerecord.models.annotation_text.one'),
      accessor: 'content',
      id: 'content',
      Cell: row => {
        return <AnnotationTextCell
                  content={row.original.content} 
                  id={row.original.id}
                  editAnnotation={this.editAnnotation}/>;
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          return row._original.content.includes(filter.value);
        } else {
          return true;
        }
      }
    }
  ];

  render() {
    return <ReactTable
        key="one_time_annotations_table"
        data={this.state.data}
        columns={this.columns}
        filterable
        defaultSorted={[{id: 'group_name'}]}
        loading={this.state.loading}
        noDataText={I18n. t('annotations.empty_uncategorized')}/>;
  }
}

export function makeOneTimeAnnotationsTable(elem, props) {
    render(<OneTimeAnnotationsTable {...props} />, elem);
  }
