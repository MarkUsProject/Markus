import React from "react";
import {createRoot} from "react-dom/client";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {createColumnHelper} from "@tanstack/react-table";

import Table from "./table/table";
import {dateSort} from "./Helpers/table_helpers";

const columnHelper = createColumnHelper();

export class ExamScanLogTable extends React.Component {
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
        return [];
      })
      .then(data => {
        this.setState({data: data, loading: false});
      });
  };

  columns = [
    columnHelper.group({
      id: "file_information",
      header: I18n.t("split_pdf_logs.file_information"),
      enableSorting: false,
      columns: [
        columnHelper.accessor("exam_template", {
          header: I18n.t("activerecord.attributes.split_pdf_log.exam_template"),
          size: 100,
          filterFn: "includesString",
          sortingFn: "text",
        }),
        columnHelper.accessor("date", {
          header: I18n.t("attributes.date"),
          sortingFn: (a, b, columnId) => dateSort(a.getValue(columnId), b.getValue(columnId)),
          sortDescFirst: false,
          filterFn: "includesString",
          minSize: 250,
        }),
        columnHelper.accessor("filename", {
          header: I18n.t("activerecord.attributes.split_pdf_log.filename"),
          filterFn: "includesString",
          sortingFn: "text",
          cell: ({row, getValue}) => {
            const path = Routes.download_raw_split_file_course_exam_template_path(
              this.props.course_id,
              row.original.exam_template_id,
              {split_pdf_log_id: row.original.file_id}
            );
            return <a href={path}>{getValue()}</a>;
          },
          minSize: 200,
        }),
      ],
    }),
    columnHelper.group({
      id: "pages",
      header: I18n.t("split_pdf_logs.pages"),
      enableSorting: false,
      columns: [
        columnHelper.accessor("original_num_pages", {
          header: I18n.t("activerecord.attributes.split_pdf_log.original_num_pages"),
          size: 100,
          filterFn: "includesString",
          sortDescFirst: false,
          meta: {className: "number"},
        }),
        columnHelper.accessor(
          row => row.page_data.filter(p => p.status.startsWith("ERROR")).length,
          {
            id: "pages_error",
            header: I18n.t("split_pdf_logs.pages_error"),
            size: 100,
            filterFn: "includesString",
            sortDescFirst: false,
            cell: ({getValue}) => {
              const errors = getValue();
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
            meta: {className: "number"},
          }
        ),
        columnHelper.accessor(row => row.page_data.filter(p => p.status === "FIXED").length, {
          id: "pages_fixed",
          header: I18n.t("split_pdf_logs.pages_fixed"),
          size: 100,
          filterFn: "includesString",
          sortDescFirst: false,
          meta: {className: "number"},
        }),
      ],
    }),
    columnHelper.group({
      id: "papers_found",
      header: I18n.t("split_pdf_logs.papers_found"),
      enableSorting: false,
      columns: [
        columnHelper.accessor("num_groups_in_complete", {
          header: I18n.t("submissions.state.complete"),
          size: 100,
          filterFn: "includesString",
          sortDescFirst: false,
          meta: {className: "number"},
        }),
        columnHelper.accessor("num_groups_in_incomplete", {
          header: I18n.t("submissions.state.incomplete"),
          size: 100,
          filterFn: "includesString",
          sortDescFirst: false,
          meta: {className: "number"},
        }),
      ],
    }),
  ];

  render() {
    const {data} = this.state;
    return (
      <Table
        data={data}
        columns={this.columns}
        initialState={{sorting: [{id: "date", desc: true}]}}
        getRowCanExpand={() => true}
        renderSubComponent={({row}) => (
          <div>
            <h4>{I18n.t("split_pdf_logs.pages_error")}</h4>
            <ExamScanErrorsTable
              course_id={this.props.course_id}
              data={row.original.page_data}
              exam_template_id={row.original.exam_template_id}
              split_pdf_log_id={row.original.file_id}
              assignment_id={this.props.assignment_id}
            />
            <h4>{I18n.t("split_pdf_logs.incomplete_papers_found")}</h4>
            <ExamScanGroupsTable data={row.original.group_data} />
          </div>
        )}
        loading={this.state.loading}
      />
    );
  }
}

class ExamScanErrorsTable extends React.Component {
  columns = [
    columnHelper.accessor("raw_page_number", {
      header: "Raw page number",
      maxSize: 120,
      enableColumnFilter: false,
      sortDescFirst: false,
      meta: {className: "number"},
    }),
    columnHelper.accessor("status", {
      header: "Status",
      enableColumnFilter: false,
      sortingFn: "text",
      meta: {className: "-wrap"},
      cell: ({row, getValue}) => {
        if (getValue() === "FIXED") {
          return getValue();
        } else {
          return (
            <span>
              {getValue()}&nbsp; (
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
    }),
    columnHelper.accessor("group", {
      header: I18n.t("activerecord.models.group.one"),
      maxSize: 150,
      enableColumnFilter: false,
      sortingFn: "text",
      sortDescFirst: false,
    }),
    columnHelper.accessor("exam_page_number", {
      header: "Exam page number",
      maxSize: 120,
      enableColumnFilter: false,
      sortDescFirst: false,
      meta: {className: "number"},
    }),
  ];

  render() {
    return (
      <div style={{maxWidth: "800px", marginTop: "5px", marginBottom: "5px"}}>
        <Table data={this.props.data} columns={this.columns} />
      </div>
    );
  }
}

class ExamScanGroupsTable extends React.Component {
  columns = [
    columnHelper.accessor("group", {
      header: I18n.t("split_pdf_logs.paper"),
      enableColumnFilter: false,
      sortingFn: "text",
    }),
    columnHelper.accessor("missing_pages", {
      header: I18n.t("split_pdf_logs.missing_pages"),
      enableColumnFilter: false,
      sortDescFirst: false,
      cell: ({getValue}) => getValue().join(", "),
    }),
  ];

  render() {
    return (
      <div style={{maxWidth: "500px", marginTop: "5px", marginBottom: "5px"}}>
        <Table data={this.props.data} columns={this.columns} />
      </div>
    );
  }
}

export function makeExamScanLogTable(elem, props) {
  const root = createRoot(elem);
  root.render(<ExamScanLogTable {...props} />);
}
