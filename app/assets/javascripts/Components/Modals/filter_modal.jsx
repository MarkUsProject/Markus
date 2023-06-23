import React from "react";
import Modal from "react-modal";

class FilterModal extends React.Component {
  static defaultProps = {};

  constructor(props) {
    super(props);
    this.state = {savedAnnotationValue: "", currentAnnotationValue: ""};
  }

  handleChange = event => {
    this.setState({currentAnnotationValue: event.target.value});
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.setState({savedAnnotationValue: event.target.annotation.value});
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
          className="filter-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={() => {
            this.setState({currentAnnotationValue: this.state.savedAnnotationValue});
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
                  type="text"
                  value={this.state.currentAnnotationValue}
                  onChange={this.handleChange}
                  placeholder={"Type here"}
                />
              </label>
              <div>
                <div className="modal-footer" id="modal-footer">
                  <section className={"modal-container dialog-actions"}>
                    <input
                      type="button"
                      value={I18n.t("results.filters.clear_all")}
                      onClick={this.clearFilters}
                    />
                    <input type="submit" value={I18n.t("results.filters.save")} />
                  </section>
                </div>
              </div>
            </form>
          </div>
        </Modal>
      </div>
    );
  }
}

export default FilterModal;
