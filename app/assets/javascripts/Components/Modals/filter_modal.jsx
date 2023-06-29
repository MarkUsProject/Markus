import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropdown";

const INITIAL_MODAL_STATE = {
  currentAnnotationValue: "",
};

const data = [
  {id: 1, title: "option 1"},
  {id: 2, title: "option 2"},
  {id: 3, title: "option 3"},
  {id: 4, title: "option 4"},
  {id: 5, title: "option 5"},
];

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
                <p>{"TAs"}</p>
                <MultiSelectDropdown data={data} />
              </div>

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
