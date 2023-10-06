import React from "react";
import {render} from "react-dom";

import ReactTable from "react-table";

import CreateTagModal from "./Modals/create_tag_modal";

class TagTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tags: [],
      loading: true,
      isCreateTagModalOpen: false,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    const url = Routes.course_tags_path(this.props.course_id, {
      assignment_id: this.props.assignment_id,
    });

    fetch(url, {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.setState({
          tags: res,
          loading: false,
        });
      });
  };

  edit = tag_id => {
    $.get({
      url: Routes.edit_tag_dialog_course_tag_path(this.props.course_id, tag_id),
      dataType: "script",
    });
  };

  delete = tag_id => {
    $.ajax(Routes.course_tag_path(this.props.course_id, tag_id), {
      method: "DELETE",
    }).then(this.fetchData);
  };

  columns = () => [
    {
      Header: I18n.t("activerecord.attributes.tags.name"),
      accessor: "name",
    },
    {
      Header: I18n.t("activerecord.attributes.tags.user"),
      accessor: "creator",
    },
    {
      Header: I18n.t("activerecord.attributes.tags.description"),
      accessor: "description",
    },
    {
      Header: I18n.t("tags.use"),
      accessor: "use",
      Cell: ({value}) => {
        return I18n.t("tags.submissions_used", {count: value});
      },
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      Cell: ({value}) => {
        return (
          <span>
            <a href="#" onClick={() => this.edit(value)}>
              {I18n.t("edit")}
            </a>
            &nbsp;|&nbsp;
            <a href="#" onClick={() => this.delete(value)}>
              {I18n.t("delete")}
            </a>
          </span>
        );
      },
      sortable: false,
    },
  ];

  onCreateTagButtonClick = () => {
    this.setState({isCreateTagModalOpen: true});
  };

  closeCreateTagModal = () => {
    this.setState({isCreateTagModalOpen: false}, () => {
      this.fetchData();
    });
  };

  // see TODO in create_tag_modal.jsx
  render() {
    return (
      <React.Fragment>
        <button type="submit" onClick={this.onCreateTagButtonClick}>
          {I18n.t("helpers.submit.create", {
            model: I18n.t("activerecord.models.tag.one"),
          })}
        </button>
        <CreateTagModal
          assignment_id={this.props.assignment_id}
          course_id={this.props.course_id}
          appElement={document.getElementById("root") || undefined}
          loading={this.state.loading}
          isOpen={this.state.isCreateTagModalOpen}
          closeModal={this.closeCreateTagModal}
          authenticityToken={AUTH_TOKEN}
        />
        <ReactTable
          data={this.state.tags}
          columns={this.columns()}
          defaultSorted={[{id: "name"}]}
          loading={this.state.loading}
        />
      </React.Fragment>
    );
  }
}

export function makeTagTable(elem, props) {
  render(<TagTable {...props} />, elem);
}
