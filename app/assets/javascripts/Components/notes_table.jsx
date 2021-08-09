import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {admins_path, all_notes_notes_path, edit_note_path} from "../../../javascript/routes";

class NotesTable extends React.Component {
  constructor() {
    super();
    this.state = {
      notes: [],
      columns: {},
      loading: true
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.all_notes_notes_path()
    }).then(res => {
      this.setState({
        notes: res['notes_data'],
        loading: false,
        columns: res['column_headers']
      });
    });
  };

  buttons(modifiable, id) {
    if(modifiable) {
      return(
        <div>
          <div>
            <a href={Routes.edit_note_path(id)}>
              <button> {I18n.t('edit')} </button>
            </a>
          </div>

          <div>
            <a href={"notes/" + id} data-method="delete" data-confirm={I18n.t('notes.delete.link_confirm')}>
              <button> {I18n.t('delete')} </button>
            </a>
          </div>
        </div>
      );
    } else {
      return(<></>);
    }
  }

  note_author(index)
  {
    return(
      <>
        <div>
          {I18n.t('notes.note_on_html',
            {user_name: this.state.notes[index]['user_name'],
              display_for: this.state.notes[index]['display_for']})}
        </div>

        <div>
          {this.state.notes[index]['date']}
        </div>
      </>
    )
  }


  data() {
    let note_data = []
    for(let i = 0; i < this.state.notes.length; i++)
    {
      let row = {
        'name' : this.note_author(i),
        'message': this.state.notes[i]['message'],
        'action' : this.buttons(this.state.notes[i]['modifiable'], this.state.notes[i]['id'])
      }
      note_data.push(row)
    }
    return note_data
  }

  columns = () => [
    {
      Header: this.state.columns['human_name'],
      accessor: 'name',
      width: 400,
      style: { 'whiteSpace': 'unset' }
    },
    {
      Header: this.state.columns['messages'],
      accessor: 'message',
      style: { 'whiteSpace': 'unset' }

    },
    {
      Header: this.state.columns['actions'],
      accessor: 'action',
      width: 200,
      mid_width: 100
    }
  ];

  render() {
    return (
      <ReactTable
        data={this.data()}
        columns={this.columns()}
        // defaultSorted={[{id: 'name'}]}
        sortable={false}
        loading={this.state.loading}
        noDataText={I18n.t('peer_reviews.no_assigned_reviews')}
      />
    );
  }
}

export function makeNotesTable(elem, props) {
  render(<NotesTable {...props} />, elem);
}
