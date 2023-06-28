import React from "react";
import Modal from "react-modal";

const INITIAL_MODAL_STATE = {
  currentAnnotationValue: "",
};

export class FilterModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = INITIAL_MODAL_STATE;
  }

  handleChange = event => {
    this.setState({currentAnnotationValue: event.target.value});
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.filterData.annotationValue = this.state.currentAnnotationValue;
    this.props.onRequestClose();
  };

  clearFilters = event => {
    event.preventDefault();
    this.setState({currentAnnotationValue: ""});
  };

  render() {
    return (
      <div>
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={() => {
            this.setState({currentAnnotationValue: this.props.filterData.annotationValue});
            this.props.onRequestClose();
          }}
        >
          <h3>{"Filter By:"}</h3>
          <div className={"modal-container-vertical"}>
            <form onSubmit={this.onSubmit}>
              <label>
                <p>{I18n.t("results.filters.annotation")}</p>
                <input
                  id="annotation"
                  type={"text"}
                  value={this.state.currentAnnotationValue}
                  onChange={this.handleChange}
                  placeholder="Type here"
                />
              </label>
              <div>
                <section className={"modal-container dialog-actions"}>
                  <input
                    id={"clear_all"}
                    type="button"
                    value={I18n.t("results.filters.clear_all")}
                    onClick={this.clearFilters}
                  />
                  <input id={"Save"} type="submit" value={I18n.t("results.filters.save")} />
                </section>
              </div>
            </form>
          </div>
        </Modal>
      </div>
    );
  }
}
