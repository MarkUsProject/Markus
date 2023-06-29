import React from "react";
import Modal from "react-modal";

export class FilterModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentAnnotationValue: this.props.filterData.annotationValue,
      currentSectionValue: this.props.filterData.sectionValue,
      currentMarkingStateValue: this.props.filterData.markingStateValue,
    };
  }

  handleChange = event => {
    this.setState({currentAnnotationValue: event.target.value});
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.mutateFilterData({
      ...this.props.filterData,
      annotationValue: this.state.currentAnnotationValue,
      sectionValue: this.state.currentSectionValue,
      markingStateValue: this.state.currentMarkingStateValue,
    });
    this.props.onRequestClose();
  };

  clearFilters = event => {
    event.preventDefault();
    this.setState({
      currentAnnotationValue: "",
      currentSectionValue: "",
      currentMarkingStateValue: "",
    });
  };

  render() {
    if (this.props.loading) {
      return "";
    }
    return (
      <div>
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={() => {
            this.setState({
              currentAnnotationValue: this.props.filterData.annotationValue,
              currentSectionValue: this.props.filterData.sectionValue,
              currentMarkingStateValue: this.props.filterData.markingStateValue,
            });
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
              <label>
                <p>Section</p>
                <select
                  onChange={event => {
                    this.setState({currentSectionValue: event.target.value});
                  }}
                  value={this.state.currentSectionValue}
                  className={"dropdown"}
                >
                  <option value={""} key={""}></option>
                  {this.props.sections.map(section => (
                    <option value={section} key={section}>
                      {section}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                <p>Marking State</p>
                <select
                  onChange={event => {
                    this.setState({currentMarkingStateValue: event.target.value});
                  }}
                  value={this.state.currentMarkingStateValue}
                  className={"dropdown"}
                >
                  <option value={""} key={""}></option>
                  {["Partial", "Complete", "Released", "Remark Requested"].map(section => (
                    <option value={section} key={section}>
                      {section}
                    </option>
                  ))}
                </select>
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
