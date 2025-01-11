import React from "react";
import {createRoot} from "react-dom/client";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import ReactTable from "react-table";
import {dateSort} from "./Helpers/table_helpers";

class ExamScanLogTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.view_logs_course_assignment_exam_templates_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      {
        headers: {
          Accept: "application/json",
        },
      }
    )
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(data => {
        this.setState({data: data, loading: false});
      });
  };

  columns = [
    {
      Header: I18n.t("split_pdf_logs.file_information"),
      columns: [
        {
          Header: I18n.t("activerecord.attributes.split_pdf_log.exam_template"),
          accessor: "exam_template",
        },
        {
          Header: I18n.t("attributes.date"),
          accessor: "date",
          sortMethod: dateSort,
          minWidth: 250,
        },
        {
          Header: I18n.t("activerecord.attributes.split_pdf_log.filename"),
          id: "filename",
          Cell: row => {
            const path = Routes.download_raw_split_file_course_exam_template_path(
              this.props.course_id,
              row.original.exam_template_id,
              {split_pdf_log_id: row.original.file_id}
            );
            return <a href={path}>{row.original.filename}</a>;
          },
          minWidth: 200,
        },
      ],
    },
    {
      Header: I18n.t("split_pdf_logs.pages"),
      columns: [
        {
          Header: I18n.t("activerecord.attributes.split_pdf_log.original_num_pages"),
          accessor: "original_num_pages",
          className: "number",
        },
        {
          Header: I18n.t("split_pdf_logs.pages_error"),
          Cell: row => {
            let errors = row.original.page_data.filter(p => p.status.startsWith("ERROR")).length;
            if (errors > 0) {
              return (
                <span className={"error-with-icon"}>
                  <FontAwesomeIcon icon="fa-solid fa-warning" className="icon-left" />
                  {errors}
                </span>
              );
            } else {
              return <span></span>;
            }
          },
          className: "number",
        },
        {
          Header: I18n.t("split_pdf_logs.pages_fixed"),
          Cell: row => row.original.page_data.filter(p => p.status === "FIXED").length,
          className: "number",
        },
      ],
    },
    {
      Header: I18n.t("split_pdf_logs.papers_found"),
      columns: [
        {
          Header: I18n.t("submissions.state.complete"),
          accessor: "num_groups_in_complete",
          className: "number",
        },
        {
          Header: I18n.t("submissions.state.incomplete"),
          accessor: "num_groups_in_incomplete",
          className: "number",
        },
      ],
    },
  ];

  render() {
    const {data} = this.state;
    return (
      <ReactTable
        data={data}
        columns={this.columns}
        filterable
        defaultSorted={[{id: "date", desc: true}]}
        SubComponent={row => (
          <ExamScanErrorsTable
            course_id={this.props.course_id}
            data={row.original.page_data}
            exam_template_id={row.original.exam_template_id}
            split_pdf_log_id={row.original.file_id}
            assignment_id={this.props.assignment_id}
          />
        )}
        loading={this.state.loading}
      />
    );
  }
}

class ExamScanErrorsTable extends React.Component {
  constructor() {
    super();
  }

  columns = [
    {
      Header: "Raw page number",
      accessor: "raw_page_number",
      maxWidth: 120,
      className: "number",
    },
    {
      Header: "Status",
      accessor: "status",
      Cell: row => {
        if (row.value === "FIXED") {
          return row.value;
        } else {
          return (
            <span>
              {row.value}&nbsp; (
              <a
                href={Routes.assign_errors_course_exam_template_path(
                  this.props.course_id,
                  this.props.exam_template_id,
                  {
                    split_pdf_log_id: this.props.split_pdf_log_id,
                    split_page_id: row.original.id,
                  }
                )}
              >
                {I18n.t("exam_templates.assign_errors.fix_errors")}
              </a>
              )
            </span>
          );
        }
      },
    },
    {
      Header: I18n.t("activerecord.models.group.one"),
      accessor: "group",
      maxWidth: 150,
    },
    {
      Header: "Exam page number",
      accessor: "exam_page_number",
      maxWidth: 120,
      className: "number",
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.props.data}
        columns={this.columns}
        style={{maxWidth: "800px", marginTop: "5px", marginBottom: "5px"}}
        minRows={1}
      />
    );
  }
}

export function makeExamScanLogTable(elem, props) {
  const root = createRoot(elem);
  root.render(<ExamScanLogTable {...props} />);
}
