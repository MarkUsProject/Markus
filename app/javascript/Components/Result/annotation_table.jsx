import React from "react";
import {createColumnHelper} from "@tanstack/react-table";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import Table from "../table/table";
import {renderMathInElement} from "../../common/math_helper";

const columnHelper = createColumnHelper();

function AnnotationContent({content}) {
  const contentRef = React.useRef(null);
  const html = React.useMemo(() => ({__html: safe_marked(content)}), [content]);

  React.useLayoutEffect(() => {
    renderMathInElement(contentRef.current);
  }, [html]);

  return <div ref={contentRef} dangerouslySetInnerHTML={html} />;
}

export class AnnotationTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columns: this.getColumns(
        props.detailed,
        props.annotations.some(a => !!a.deduction)
      ),
      sorting: [{id: "deduction"}, {id: "filename"}, {id: "number"}],
    };
  }

  componentDidUpdate(prevProps) {
    const hadDeductions = prevProps.annotations.some(a => !!a.deduction);
    const hasDeductions = this.props.annotations.some(a => !!a.deduction);
    if (
      prevProps.detailed !== this.props.detailed ||
      hadDeductions !== hasDeductions ||
      prevProps.released_to_students !== this.props.released_to_students ||
      prevProps.remark_submitted !== this.props.remark_submitted
    ) {
      this.setState({columns: this.getColumns(this.props.detailed, hasDeductions)});
    }
  }

  columns = [
    columnHelper.accessor("number", {
      header: "#",
      maxSize: 50,
      filterFn: "includesString",
      meta: {className: "-wrap"},
      cell: ({row}) => {
        let remove_button = "";
        if (!this.props.released_to_students && !this.props.remark_submitted) {
          remove_button = (
            <a
              href="#"
              title={I18n.t("delete")}
              onClick={() => this.props.removeAnnotation(row.original.id)}
            >
              <FontAwesomeIcon icon="fa-solid fa-trash" />
            </a>
          );
        }
        return (
          <div>
            {remove_button}
            <span className="alignright">{row.original.number}</span>
          </div>
        );
      },
    }),
    columnHelper.accessor("filename", {
      header: I18n.t("attributes.filename"),
      maxSize: 150,
      meta: {className: "-wrap"},
      cell: ({row}) => {
        let full_path = row.original.path
          ? row.original.path + "/" + row.original.filename
          : row.original.filename;
        let name;
        if (row.original.line_start !== undefined) {
          name = I18n.t("results.annotation.filename_with_line", {
            filename: full_path,
            line: row.original.line_start,
          });
        } else {
          name = full_path;
        }
        return (
          <a
            onClick={() =>
              this.props.selectFile(
                full_path,
                row.original.submission_file_id,
                row.original.line_start,
                row.original.id
              )
            }
          >
            {name}
          </a>
        );
      },
    }),
    columnHelper.accessor("content", {
      header: I18n.t("annotations.text"),
      meta: {className: "-wrap"},
      cell: ({row, getValue}) => {
        let value,
          edit_button = "";
        if (
          !this.props.released_to_students &&
          !row.original.deduction &&
          !this.props.remark_submitted
        ) {
          edit_button = (
            <a
              href="#"
              title={I18n.t("edit")}
              onClick={() => this.props.editAnnotation(row.original.id)}
            >
              <FontAwesomeIcon icon="fa-solid fa-pen" />
            </a>
          );
        }

        if (row.original.is_remark) {
          value = `${getValue()} (${I18n.t("results.annotation.remark_flag")})`;
        } else {
          value = getValue();
        }
        return (
          <div>
            <AnnotationContent content={value} />
            <div className={"alignright"}>{edit_button}</div>
          </div>
        );
      },
    }),
  ];

  detailedColumns = [
    columnHelper.accessor("creator", {
      header: I18n.t("activerecord.attributes.annotation.creator"),
      maxSize: 120,
      meta: {className: "-wrap"},
      cell: ({row, getValue}) => {
        if (row.original.is_remark) {
          return `${getValue()} (${I18n.t("results.annotation.remark_flag")})`;
        } else {
          return getValue();
        }
      },
    }),
    columnHelper.accessor("annotation_category", {
      header: I18n.t("activerecord.models.annotation_category", {count: 1}),
      maxSize: 150,
      filterFn: "includesString",
      meta: {className: "-wrap"},
    }),
  ];

  deductionColumn = columnHelper.accessor(
    row => {
      if (!row.deduction) {
        return "";
      } else {
        return "[" + row.criterion_name + "] -" + row.deduction;
      }
    },
    {
      id: "deduction",
      header: I18n.t("activerecord.attributes.annotation_text.deduction"),
      maxSize: 120,
      meta: {className: "-wrap"},
      cell: ({row}) => {
        if (!row.original.deduction) {
          return "";
        } else {
          return (
            <div>
              {"[" + row.original.criterion_name + "] "}
              <span className={"red-text"}>{"-" + row.original.deduction}</span>
            </div>
          );
        }
      },
      sortingFn: (rowA, rowB, columnId) => {
        const a = rowA.getValue(columnId);
        const b = rowB.getValue(columnId);
        if (a === b) {
          return 0;
        } else if (a === "") {
          return 1;
        } else if (b === "") {
          return -1;
        } else if (a > b) {
          return 1;
        }
        return -1;
      },
    }
  );

  getColumns = (detailed, hasDeductions) => {
    const columns = detailed ? [...this.columns, ...this.detailedColumns] : [...this.columns];
    if (hasDeductions) columns.push(this.deductionColumn);
    return columns;
  };

  onSortingChange = updaterOrValue => {
    this.setState(prevState => ({
      sorting:
        typeof updaterOrValue === "function" ? updaterOrValue(prevState.sorting) : updaterOrValue,
    }));
  };

  render() {
    const sorting = this.state.columns.includes(this.deductionColumn)
      ? this.state.sorting
      : this.state.sorting.filter(sort => sort.id !== "deduction");

    return (
      <div id={"annotation_table"}>
        <Table
          data={this.props.annotations}
          columns={this.state.columns}
          sorting={sorting}
          onSortingChange={this.onSortingChange}
        />
      </div>
    );
  }
}
