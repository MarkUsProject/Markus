import React from "react";
import {createRoot} from "react-dom/client";

import ReactTable from "react-table";

import CreateTagModal from "./Modals/create_tag_modal";
import EditTagModal from "./Modals/edit_tag_modal";
import {ResultContext} from "./Result/result_context";

class TagTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tags: [],
      loading: true,
      isCreateTagModalOpen: false,
      isEditTagModalOpen: false,
      currentTagId: "",
      currentTagName: "",
      currentTagDescription: "",
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
    const currentTag = this.state.tags.find(tag => tag.id === tag_id);
    this.setState({
      isEditTagModalOpen: true,
      currentTagId: tag_id,
      currentTagName: currentTag.name,
      currentTagDescription: currentTag.description,
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

  closeEditTagModal = () => {
    this.setState({isEditTagModalOpen: false}, () => {
      this.fetchData();
    });
  };

  render() {
    const contextValue = {
      course_id: this.props.course_id,
      assignment_id: this.props.assignment_id,
    };

    return (
      <React.Fragment>
        {!this.state.loading && (
          <button type="submit" onClick={this.onCreateTagButtonClick}>
            {I18n.t("helpers.submit.create", {
              model: I18n.t("activerecord.models.tag.one"),
            })}
          </button>
        )}
        <ReactTable
          data={this.state.tags}
          columns={this.columns()}
          defaultSorted={[{id: "name"}]}
          loading={this.state.loading}
        />
        {this.state.isCreateTagModalOpen && (
          <ResultContext.Provider value={contextValue}>
            <CreateTagModal
              isOpen={this.state.isCreateTagModalOpen}
              onRequestClose={this.closeCreateTagModal}
            />
          </ResultContext.Provider>
        )}
        {this.state.isEditTagModalOpen && (
          <EditTagModal
            assignment_id={this.props.assignment_id}
            course_id={this.props.course_id}
            tag_id={this.state.currentTagId}
            isOpen={this.state.isEditTagModalOpen}
            onRequestClose={this.closeEditTagModal}
            currentTagName={this.state.currentTagName}
            currentTagDescription={this.state.currentTagDescription}
          />
        )}
      </React.Fragment>
    );
  }
}

export function makeTagTable(elem, props) {
  const root = createRoot(elem);
  root.render(<TagTable {...props} />);
}
