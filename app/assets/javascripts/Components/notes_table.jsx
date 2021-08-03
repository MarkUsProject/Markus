import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {admins_path, all_notes_notes_path} from "../../../javascript/routes";


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

  data() {
    let note_data = []
    for(let i = 0; i < this.state.notes.length; i++)
    {
      let name = I18n.t('notes.note_on_html',
            {user_name: this.state.notes[i]['user_name'],
            display_for: this.state.notes[i]['display_for']})


      let row = {
        'name' : name,
        'message': this.state.notes[i]['message'],
      }

      if(this.state.notes[i]['modifiable'])
      {
          row['action'] = <div> buttons </div>
      } else {
        row['action'] = <div> </div>
      }
      note_data.push(row)
    }
    return note_data
  }



  columns = () => [
    {
      Header: this.state.columns['human_name'],
      
      accessor: 'name',

    },
    {
      Header: this.state.columns['messages'],
      accessor: 'message',
    },
    {
      Header: this.state.columns['actions'],
      accessor: 'action',
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
