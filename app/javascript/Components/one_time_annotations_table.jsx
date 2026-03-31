import React from "react";
import {createRoot} from "react-dom/client";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {renderMathInElement} from "../common/math_helper";

class OneTimeAnnotationsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
    };

    const columnHelper = createColumnHelper();
    this.columns = [
      columnHelper.accessor("group_name", {
        id: "group_name",
        header: () => I18n.t("activerecord.models.group.one"),
        cell: props => {
          const row = props.row;
          let remove_button = (
            <a
              title={I18n.t("delete")}
              onClick={() => this.removeAnnotation(row.original.id, row.original.result_id)}
            >
              <FontAwesomeIcon icon="fa-solid fa-trash" />
            </a>
          );
          if (row.original.result_id) {
            const path = Routes.edit_course_result_path(
              this.props.course_id,
              row.original.result_id
            );
            return (
              <div>
                {remove_button}
                <a className="alignright" href={path}>
                  {row.original.group_name}
                </a>
              </div>
            );
          } else {
            return (
              <div>
                {remove_button}
                <span className="alignright">{row.original.group_name}</span>
              </div>
            );
          }
        },
      }),
      columnHelper.accessor("creator", {
        id: "creator",
        header: () => I18n.t("activerecord.attributes.annotation_text.creator"),
      }),
      columnHelper.accessor("last_editor", {
        id: "last_editor",
        header: () => I18n.t("annotations.last_edited_by"),
      }),
      columnHelper.accessor("content", {
        id: "content",
        header: () => I18n.t("activerecord.models.annotation_text.one"),
        cell: props => {
          const row = props.row;
          return (
            <AnnotationTextCell
              content={row.original.content}
              id={row.original.id}
              editAnnotation={this.editAnnotation}
            />
          );
        },
        size: 600,
      }),
    ];
    this.tableRef = React.createRef();
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    this.setState({loading: true}, () => {
      fetch(
        Routes.uncategorized_annotations_course_assignment_annotation_categories_path(
          this.props.course_id,
          this.props.assignment_id
        ),
        {
          headers: {
            Accept: "application/json, text/javascript",
          },
        }
      )
        .then(response => {
          if (response.ok) {
            return response.json();
          }
        })
        .then(res => {
          this.setState({
            data: res,
            loading: false,
          });
        });
    });
  };

  componentDidUpdate(_prevProps, prevState) {
    if (prevState.loading && !this.state.loading) {
      renderMathInElement(this.tableRef.current);
    }
  }

  editAnnotation = (annot_id, content) => {
    $.ajax({
      url: Routes.update_annotation_text_course_assignment_annotation_categories_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {content: content, annotation_text_id: annot_id},
      method: "PUT",
      remote: true,
      dataType: "script",
    }).always(this.fetchData);
  };

  removeAnnotation = annot_id => {
    $.ajax({
      url: Routes.destroy_annotation_text_course_assignment_annotation_categories_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {annotation_text_id: annot_id},
      method: "delete",
      remote: true,
      dataType: "script",
    }).then(this.fetchData);
  };

  render() {
    return (
      <div id="one_time_annotations_table_wrapper" ref={this.tableRef}>
        <Table
          key="one_time_annotations_table"
          data={this.state.data}
          columns={this.columns}
          initialState={{
            sorting: [{id: "group_name"}],
          }}
          loading={this.state.loading}
          noDataText={I18n.t("annotations.empty_uncategorized")}
        />
      </div>
    );
  }
}

class AnnotationTextCell extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editMode: false,
      content: props.content,
    };
  }

  componentDidUpdate(prevProps) {
    if (prevProps.content !== this.props.content) {
      this.setState({content: this.props.content});
    }
  }

  render() {
    //Show input field and save and cancel buttons
    if (this.state.editMode) {
      let save_button = (
        <a
          className="button inline-button"
          onClick={() => {
            if (this.props.content !== this.state.content) {
              this.props.editAnnotation(this.props.id, this.state.content);
            }
            this.setState({editMode: false});
          }}
        >
          {I18n.t("save")}
        </a>
      );
      let cancel_button = (
        <a
          className="button inline-button"
          onClick={() =>
            this.setState({
              editMode: false,
              content: this.props.content,
            })
          }
        >
          {I18n.t("cancel")}
        </a>
      );
      return (
        <div>
          <input
            type="textarea"
            className="rt-cell-textarea"
            defaultValue={this.state.content}
            onChange={e => this.setState({content: e.target.value})}
          />
          <div className={"alignright"}>{save_button}</div>
          <div className={"alignright"}>{cancel_button}</div>
        </div>
      );
    } else {
      let edit_button = (
        <a title={I18n.t("edit")} onClick={() => this.setState({editMode: true})}>
          <FontAwesomeIcon icon="fa-solid fa-pen" />
        </a>
      );
      return (
        <div>
          <div
            dangerouslySetInnerHTML={{
              __html: safe_marked(this.state.content),
            }}
          />
          <div className={"alignright"}>{edit_button}</div>
        </div>
      );
    }
  }
}

export function makeOneTimeAnnotationsTable(elem, props) {
  const root = createRoot(elem);
  root.render(<OneTimeAnnotationsTable {...props} />);
}
