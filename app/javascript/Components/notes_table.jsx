import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class NotesTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      notes: [],
      columns: {},
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.course_notes_path(this.props.course_id, {format: "json"}), {
      headers: {Accept: "application/json"},
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.setState({
          notes: res,
          loading: false,
        });
      });
  };

  renderButtons(editable, id) {
    if (editable) {
      return (
        <div>
          <a
            href={Routes.edit_course_note_path(this.props.course_id, id)}
            className="inline-button button"
            aria-label={I18n.t("edit")}
            title={I18n.t("edit")}
          >
            <FontAwesomeIcon icon={faPencil} />
          </a>

          <a
            href={Routes.course_note_path(this.props.course_id, id)}
            className="inline-button button"
            data-method="delete"
            data-confirm={I18n.t("notes.delete.link_confirm")}
            aria-label={I18n.t("delete")}
            title={I18n.t("delete")}
          >
            <FontAwesomeIcon icon={faTrashCan} />
          </a>
        </div>
      );
    } else {
      return "";
    }
  }

  note_author(index) {
    return (
      <React.Fragment>
        <div>
          {I18n.t("notes.note_on_html", {
            user_name: this.state.notes[index]["user_name"],
            display_for: this.state.notes[index]["display_for"],
          })}
        </div>

        <div>{this.state.notes[index]["date"]}</div>
      </React.Fragment>
    );
  }

  data() {
    return this.state.notes.map((note, i) => {
      return {
        name: this.note_author(i),
        message: note["message"],
        action: this.renderButtons(note["modifiable"], note["id"]),
      };
    });
  }

  columns = [
    {
      Header: I18n.t("activerecord.models.note.other"),
      accessor: "name",
      width: 400,
      style: {whiteSpace: "unset"},
    },
    {
      Header: I18n.t("activerecord.attributes.notes.notes_message"),
      accessor: "message",
      style: {whiteSpace: "unset"},
    },
    {
      Header: I18n.t("actions"),
      accessor: "action",
      width: 200,
      mid_width: 100,
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.data()}
        columns={this.columns}
        sortable={false}
        loading={this.state.loading}
        getNoDataProps={() => ({
          loading: this.state.loading,
        })}
      />
    );
  }
}

export function makeNotesTable(elem, props) {
  const root = createRoot(elem);
  root.render(<NotesTable {...props} />);
}
