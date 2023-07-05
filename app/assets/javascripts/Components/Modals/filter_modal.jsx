import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";
import {Dropdown} from "../../DropDownMenu/DropDown";

const INITIAL_MODAL_STATE = {
  currentAnnotationValue: "",
  currentSectionValue: "",
  currentMarkingStateValue: "",
  currentTas: [],
  currentTags: [],
};

export class FilterModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentAnnotationValue: this.props.filterData.annotationValue,
      currentSectionValue: this.props.filterData.sectionValue,
      currentMarkingStateValue: this.props.filterData.markingStateValue,
      currentTas: this.props.filterData.tas,
      currentTags: this.props.filterData.tags,
    };
  }

  toggleOptionTas = user_name => {
    const newArray = [...this.state.currentTas];
    if (newArray.includes(user_name)) {
      this.setState({currentTas: newArray.filter(item => item !== user_name)});
      // else, add
    } else {
      newArray.push(user_name);
      this.setState({currentTas: newArray});
    }
  };

  toggleOptionTags = tag => {
    const newArray = [...this.state.currentTags];
    if (newArray.includes(tag)) {
      this.setState({currentTags: newArray.filter(item => item !== tag)});
      // else, add
    } else {
      newArray.push(tag);
      this.setState({currentTags: newArray});
    }
  };

  renderTasDropdown = () => {
    return (
      <MultiSelectDropdown
        options={this.props.tas}
        selected={this.state.currentTas}
        toggleOption={this.toggleOptionTas}
      />
    );
  };

  renderTagsDropdown = () => {
    let options = [];
    if (this.props.available_tags.length !== 0) {
      options = options.concat(this.props.available_tags.map(item => item.name));
    }
    if (this.props.current_tags.length !== 0) {
      options = options.concat(this.props.current_tags.map(item => item.name));
    }
    return (
      <MultiSelectDropdown
        options={options}
        selected={this.state.currentTags}
        toggleOption={this.toggleOptionTags}
      />
    );
  };

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
      tas: this.state.currentTas,
      tags: this.state.currentTags,
    });
    this.props.onRequestClose();
  };

  clearFilters = event => {
    event.preventDefault();
    this.setState(INITIAL_MODAL_STATE);
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
              currentTas: this.props.filterData.tas,
            });
            this.props.onRequestClose();
          }}
        >
          <h3>{"Filter By:"}</h3>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container"}>
              <div className={"modal-container-vertical"}>
                <label className={"annotation-input"}>
                  <p>{I18n.t("results.filters.annotation")}</p>
                  <input
                    id="annotation"
                    type={"text"}
                    value={this.state.currentAnnotationValue}
                    onChange={this.handleChange}
                    placeholder="Type here"
                  />
                </label>
                <p>Section</p>
                <Dropdown
                  options={this.props.sections}
                  selected={this.state.currentSectionValue}
                  select={selection => {
                    this.setState({currentSectionValue: selection});
                  }}
                />
                <div>
                  <p>{"TAs"}</p>
                  {this.renderTasDropdown()}
                </div>
              </div>
              <div className={"modal-container-vertical"}>
                <div>
                  <p>Marking State</p>
                  <Dropdown
                    options={["Partial", "Complete", "Released", "Remark Requested"]}
                    selected={this.state.currentMarkingStateValue}
                    select={selection => {
                      this.setState({currentMarkingStateValue: selection});
                    }}
                  />
                </div>

                <div>
                  <p>{"Tags"}</p>
                  {this.renderTagsDropdown()}
                </div>
              </div>
            </div>
            <div className={"modal-footer"}>
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
        </Modal>
      </div>
    );
  }
}
