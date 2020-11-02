import React from "react";
import Modal from "react-modal";

class CreateModifyAnnotationPanel extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      content: this.props.content,
      category_id: this.props.category_id,
    };
  }

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

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit({ ...this.state });
  };

  handleChange = (event) => {
    let name = event.target.name;
    let val = event.target.value;
    this.setState({ [name]: val });
  };

  checkCriterion = (event) => {
    event.preventDefault();
    this.handleChange(event);
    let val = event.target.value;
    let categories_with_criteria = this.props.categories
      .filter((category) => category.flexible_criterion_id !== null)
      .map((category) => category.id);

    if (categories_with_criteria.includes(parseInt(val, 10))) {
      this.setState({ show_deduction_disclaimer: true });
    } else {
      this.setState({ show_deduction_disclaimer: false });
    }
  };

  render() {
    let options = [
      <option value="">{I18n.t("annotation_categories.one_time_only")}</option>,
    ];
    this.props.categories.forEach((category) => {
      options.push(
        <option value={category.id}>{category.annotation_category_name}</option>
      );
    });

    return (
      <Modal
        className="react-modal dialog"
        isOpen={this.props.show}
        onRequestClose={this.props.onRequestClose}
      >
        <div
          style={{
            width: "600px",
            display: "block",
          }}
        >
          <h2>{this.props.title}</h2>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <div>
                <label>
                  <textarea
                    required={true}
                    id="new_annotation_content"
                    name="content"
                    placeholder={I18n.t("results.annotation.placeholder")}
                    value={this.state.content}
                    onChange={this.handleChange}
                    rows="8"
                  />
                </label>
                <h3>{I18n.t("preview")}</h3>
                <div id="annotation_preview" className="preview"></div>
                {this.props.is_reviewer ? (
                  <input
                    type="hidden"
                    id="new_annotation_category"
                    name="category_id"
                    value={I18n.t("annotation_categories.one_time_only")}
                  />
                ) : (
                  <div>
                    <h3>
                      {I18n.t("activerecord.models.annotation_category.one")}
                    </h3>
                    <select
                      id="new_annotation_category"
                      name="category_id"
                      onChange={this.checkCriterion}
                      value={this.state.category_id}
                    >
                      {options}
                    </select>

                    <p
                      id="deduction_disclaimer"
                      className={
                        this.state.show_deduction_disclaimer ? "" : "hidden"
                      }
                    >
                      {I18n.t("annotations.default_deduction")}
                    </p>
                  </div>
                )}

                <section className="modal-container dialog-actions">
                  <input type="submit" value={I18n.t("save")} />
                </section>
              </div>
            </div>
          </form>
        </div>
      </Modal>
    );
  }
}

export default CreateModifyAnnotationPanel;
