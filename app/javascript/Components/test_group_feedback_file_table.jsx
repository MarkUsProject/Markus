import React from "react";
import ReactTable from "react-table";
import mime from "mime/lite";
import {FileViewer} from "./Result/file_viewer";

export class TestGroupFeedbackFileTable extends React.Component {
  render() {
    const columns = [
      {
        Header: I18n.t("activerecord.attributes.submission.feedback_files"),
        accessor: "filename",
      },
    ];

    return (
      <ReactTable
        className={"auto-overflow test-result-feedback-files"}
        data={this.props.data}
        columns={columns}
        SubComponent={row => (
          <FileViewer
            selectedFile={row.original.filename}
            selectedFileURL={Routes.course_feedback_file_path(
              this.props.course_id,
              row.original.id
            )}
            mime_type={mime.getType(row["filename"])}
            selectedFileType={row.original.type}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        )}
      />
    );
  }
}
