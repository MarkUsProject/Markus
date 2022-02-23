import React from "react";
import {render} from "react-dom";

class NewExamTemplateModal extends React.Component {
  constructor(props) {
    super(props);
  }

  renderBasicForm = () => {
    return (
      <div className={"modal-container-vertical"}>
        <div className={"inline-labels"}>
          <label className={"required"}>Exam Template Name</label>
          <input type={"text"} name={"new_url"} />
          <label className={"required"}>{I18n.t("exam_templates.create.upload")}</label>
          <input type={"file"} name={"pdf_to_split"} />
        </div>
        <div className={"modal-container"}>
          <input type="submit" value={I18n.t("save")} />
        </div>
      </div>
    );
  };

  render() {
    return this.renderBasicForm();
  }
}

export function makeNewExamTemplateModal(elem, props) {
  render(<NewExamTemplateModal {...props} />, elem);
}
