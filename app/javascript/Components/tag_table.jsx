import React from "react";
import {createRoot} from "react-dom/client";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";

import CreateTagModal from "./Modals/create_tag_modal";
import EditTagModal from "./Modals/edit_tag_modal";
import {ResultContext} from "./Result/result_context";
import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

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

    const columnHelper = createColumnHelper();
    this.columns = [
      columnHelper.accessor("name", {
        header: () => I18n.t("activerecord.attributes.tags.name"),
      }),
      columnHelper.accessor("creator", {
        header: () => I18n.t("activerecord.attributes.tags.user"),
      }),
      columnHelper.accessor("description", {
        header: () => I18n.t("activerecord.attributes.tags.description"),
      }),
      columnHelper.accessor("use", {
        header: () => I18n.t("tags.use"),
        cell: props => {
          return <div>{I18n.t("tags.submissions_used", {count: props.getValue()})}</div>;
        },
      }),
      columnHelper.accessor("id", {
        header: () => I18n.t("actions"),
        cell: props => {
          const value = props.getValue();
          return (
            <span>
              <a
                href="#"
                onClick={() => this.edit(value)}
                aria-label={I18n.t("edit")}
                title={I18n.t("edit")}
              >
                <FontAwesomeIcon icon={faPencil} />
              </a>
              &nbsp;|&nbsp;
              <a
                href="#"
                onClick={() => this.delete(value)}
                aria-label={I18n.t("delete")}
                title={I18n.t("delete")}
              >
                <FontAwesomeIcon icon={faTrashCan} />
              </a>
            </span>
          );
        },
        enableSorting: false,
      }),
    ];
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
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
  }

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
      <>
        {!this.state.loading && (
          <button type="submit" onClick={this.onCreateTagButtonClick}>
            {I18n.t("helpers.submit.create", {
              model: I18n.t("activerecord.models.tag.one"),
            })}
          </button>
        )}
        <Table data={this.state.tags} columns={this.columns} loading={this.state.loading} />
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
      </>
    );
  }
}

export function makeTagTable(elem, props) {
  const root = createRoot(elem);
  root.render(<TagTable {...props} />);
}
