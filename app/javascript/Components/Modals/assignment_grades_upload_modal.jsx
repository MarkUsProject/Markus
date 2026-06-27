import React from "react";
import Modal from "react-modal";

class AssignmentGradesUploadModal extends React.Component {
  componentDidMount() {
    Modal.setAppElement("body");
  }

  authenticityToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || "";
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>
          {I18n.t("upload_the", {
            item: I18n.t("assignments.grades"),
          })}
        </h2>
        <form
          action={Routes.upload_grades_course_assignment_path(
            this.props.course_id,
            this.props.assignment_id
          )}
          encType="multipart/form-data"
          method="post"
        >
          <div className="modal-container-vertical">
            <input type="hidden" name="authenticity_token" value={this.authenticityToken()} />
            <p>
              <input type="file" name="upload_file" required={true} accept=".csv" />
            </p>
            <p>
              <label htmlFor="encoding">{I18n.t("encoding")}</label>
              <select id="encoding" name="encoding" defaultValue="UTF-8">
                {this.props.encodings.map(([label, value]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </p>
            <p>
              <label htmlFor="overwrite">
                <input type="checkbox" id="overwrite" name="overwrite" />{" "}
                {I18n.t("assignments.upload_grades.overwrite")}
              </label>
            </p>
            <section className="dialog-actions">
              <input
                type="submit"
                value={I18n.t("upload")}
                data-disable-with={I18n.t("uploading_please_wait")}
              />
              <input onClick={this.props.onRequestClose} type="reset" value={I18n.t("cancel")} />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}

export default AssignmentGradesUploadModal;
