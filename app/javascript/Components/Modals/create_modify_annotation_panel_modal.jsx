import React from "react";
import Modal from "react-modal";

import MarkdownEditor from "../markdown_editor";
import {ResultContext} from "../Result/result_context";

class CreateModifyAnnotationPanel extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      content: this.props.content,
      category_id: this.props.category_id,
      show_autocomplete: false,
      annotation_text_id: "",
      change_all: false,
    };
  }

  static contextType = ResultContext;

  updateAnnotationCompletion = () => {
    const annotationTextList = document.getElementById("annotation_text_list");
    const value = this.state.content;

    this.setState({
      annotation_text_id: "",
    });

    if (value.length < 2) {
      this.setState({show_autocomplete: false});
      return;
    }

    const url = Routes.find_annotation_text_course_assignment_annotation_categories_path(
      this.context.course_id,
      this.context.assignment_id,
      {string: value}
    );

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
        if (res.length === 0) {
          this.setState({show_autocomplete: false});
          return;
        }

        this.setState({show_autocomplete: true});
        annotationTextList.innerHTML = "";
        document.getElementById("annotation_completion_text").innerText = I18n.t(
          "results.annotation.similar_annotations_found",
          {
            count: res.length,
          }
        );
        res.forEach(elem => {
          const annotation = document.createElement("li");
          annotation.setAttribute("key", 1);
          annotation.setAttribute("id", elem.id);
          annotation.onclick = () => {
            this.setState({
              content: elem.content,
              category_id: elem.annotation_category_id,
              annotation_text_id: elem.id,
            });
          };
          annotation.innerText = elem.content;
          annotationTextList.appendChild(annotation);
        });
      })
      .catch(e => console.error(e));
  };

  onModalOpen = () => {
    var typing_timer;
    const textArea = $("#new_annotation_content");
    const submitBtn = $("#annotation-submit-btn");

    textArea.keydown(function (e) {
      var keyCode = e.keyCode || e.which;
      if (keyCode == 9) {
        e.preventDefault();
        var start = this.selectionStart;
        var end = this.selectionEnd;
        this.value = this.value.substring(0, start) + "  " + this.value.substring(end);
        this.selectionStart = this.selectionEnd = start + 2;
      }
    });

    if (!this.context.is_reviewer) {
      textArea.keyup(e => {
        if (typing_timer) {
          clearTimeout(typing_timer);
        }
        typing_timer = setTimeout(() => this.updateAnnotationCompletion(), 300);
      });
    }

    Mousetrap(document.getElementById("annotation-modal")).bind("mod+enter", function (e) {
      e.preventDefault();
      submitBtn.click();
    });
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  componentDidUpdate(prevProps, prevState) {
    if (
      prevProps.content !== this.props.content ||
      prevProps.category_id !== this.props.category_id
    ) {
      this.setState({
        content: this.props.content,
        category_id: this.props.category_id,
        show_deduction_disclaimer: false,
      });
    }
  }

  onSubmit = event => {
    event.preventDefault();
    const {content, category_id, annotation_text_id, change_all} = this.state;
    this.props
      .onSubmit({
        content,
        category_id,
        annotation_text_id,
        annotation_text: {
          change_all: change_all ? 1 : 0,
        },
      })
      .then(() => {
        // reset defaults
        this.setState({
          content: this.props.content,
          category_id: this.props.category_id,
          show_autocomplete: false,
          annotation_text_id: "",
          change_all: false,
        });
      });
  };

  handleChange = event => {
    let name = event.target.name;
    let val = event.target.value;
    this.setState({[name]: val});
  };

  handleCheckbox = event => {
    let name = event.target.name;
    this.setState({[name]: !this.state[name]});
  };

  checkCriterion = event => {
    event.preventDefault();
    this.handleChange(event);
    let val = event.target.value;
    let categories_with_criteria = this.props.categories
      .filter(category => category.flexible_criterion_id !== null)
      .map(category => category.id);

    if (categories_with_criteria.includes(parseInt(val, 10))) {
      this.setState({show_deduction_disclaimer: true});
    } else {
      this.setState({show_deduction_disclaimer: false});
    }
  };

  render() {
    let options = [
      <option key="one_time_annotation" value="">
        {I18n.t("annotation_categories.one_time_only")}
      </option>,
    ];
    this.props.categories.forEach(category => {
      options.push(
        <option key={category.id} value={category.id}>
          {category.annotation_category_name}
        </option>
      );
    });

    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.show}
        onAfterOpen={this.onModalOpen}
        onRequestClose={this.props.onRequestClose}
        parentSelector={() => document.querySelector("#content")}
      >
        <div
          id="annotation-modal"
          style={{
            width: "600px",
            display: "block",
          }}
        >
          <h2>{this.props.title}</h2>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <MarkdownEditor
                content={this.state.content}
                handleChange={this.handleChange}
                show_autocomplete={this.state.show_autocomplete}
                text_area_id="new_annotation_content"
                auto_completion_text_id="annotation_completion_text"
                auto_completion_list_id="annotation_text_list"
                updateAnnotationCompletion={this.updateAnnotationCompletion}
              />
              <input
                type="hidden"
                id="annotation_text_id"
                name="annotation_text_id"
                value={this.props.annotation_text_id}
              />
              {this.context.is_reviewer ? (
                <input
                  type="hidden"
                  id="new_annotation_category"
                  name="category_id"
                  value={I18n.t("annotation_categories.one_time_only")}
                />
              ) : (
                <div className="inline-labels">
                  <label htmlFor="new_annotation_category">
                    {I18n.t("activerecord.models.annotation_category.one")}
                  </label>

                  <select
                    id="new_annotation_category"
                    name="category_id"
                    onChange={this.checkCriterion}
                    value={this.state.category_id}
                    disabled={!this.props.isNew}
                  >
                    {options}
                  </select>

                  <p
                    id="deduction_disclaimer"
                    className={this.state.show_deduction_disclaimer ? "" : "hidden"}
                  >
                    {I18n.t("annotations.default_deduction")}
                  </p>
                </div>
              )}

              {this.props.changeOneOption && (
                <p>
                  <input
                    type="checkbox"
                    id="change_all"
                    name="change_all"
                    checked={this.state.change_all}
                    onChange={this.handleCheckbox}
                  />
                  <label htmlFor="change_all"> {I18n.t("annotations.update_all")}</label>{" "}
                </p>
              )}

              <section className="modal-container dialog-actions">
                <input
                  id="annotation-submit-btn"
                  type="submit"
                  title="Ctrl/⌘ + Enter"
                  value={I18n.t("save")}
                />
              </section>
            </div>
          </form>
        </div>
      </Modal>
    );
  }
}

export default CreateModifyAnnotationPanel;
