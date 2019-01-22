import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class TagTable extends React.Component {
  constructor() {
    super();
    this.state = {
      tags: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_tags_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.setState({
        tags: res,
        loading: false,
      });
    });
  };

  edit = (tag_id) => {
    $.get({
      url: Routes.edit_tag_dialog_assignment_tag_path(this.props.assignment_id, tag_id),
      dataType: 'script'
    })
  };

  delete = (tag_id) => {
    $.ajax(Routes.assignment_tag_path(this.props.assignment_id, tag_id), {
      method: 'DELETE'
    }).then(this.fetchData);
  };

  columns = () => [
    {
      Header: I18n.t('activerecord.attributes.tags.name'),
      accessor: 'name',
    },
    {
      Header: I18n.t('activerecord.attributes.tags.user'),
      accessor: 'creator',
    },
    {
      Header: I18n.t('activerecord.attributes.tags.description'),
      accessor: 'description',
    },
    {
      Header: I18n.t('tags.use'),
      accessor: 'use',
      Cell: ({value}) => {
        return I18n.t('tags.submissions_used', {count: value});
      },
    },
    {
      Header: I18n.t('actions'),
      accessor: 'id',
      Cell: ({value}) => {
        return (
          <span>
          <a href="#" onClick={() => this.edit(value)}>{I18n.t('edit')}</a>
          &nbsp;|&nbsp;
          <a href="#" onClick={() => this.delete(value)}>{I18n.t('delete')}</a>
          </span>
        );
      },
      sortable: false
    }
  ];

  render() {
    return (
      <ReactTable
        data={this.state.tags}
        columns={this.columns()}
        defaultSorted={[{id: 'name'}]}
        loading={this.state.loading}
      />
    );
  }
}


export function makeTagTable(elem, props) {
  render(<TagTable {...props} />, elem);
}
