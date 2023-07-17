import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";
import {SingleSelectDropDown} from "../../DropDownMenu/SingleSelectDropDown";

const INITIAL_MODAL_STATE = {
  currentOrderBy: "Group Name",
  currentAscBool: true,
  currentAnnotationValue: "",
  currentSectionValue: "",
  currentMarkingStateValue: "",
  currentTas: [],
  currentTags: [],
  currentTotalMarkRange: {
    min: "",
    max: "",
  },
  currentTotalExtraMarkRange: {
    min: "",
    max: "",
  },
};

export class FilterModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentOrderBy: this.props.filterData.orderBy,
      currentAscBool: this.props.filterData.ascBool,
      currentAnnotationValue: this.props.filterData.annotationValue,
      currentSectionValue: this.props.filterData.sectionValue,
      currentMarkingStateValue: this.props.filterData.markingStateValue,
      currentTas: this.props.filterData.tas,
      currentTags: this.props.filterData.tags,
      currentTotalMarkRange: this.props.filterData.totalMarkRange,
      currentTotalExtraMarkRange: this.props.filterData.totalExtraMarkRange,
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

  clearSelectionTAs = () => {
    this.setState({currentTas: []});
  };

  clearSelectionTags = () => {
    this.setState({currentTags: []});
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
    if (this.props.role !== "Ta") {
      return (
        <div className={"filter"}>
          <p>{I18n.t("results.filters.tas")}</p>
          <MultiSelectDropdown
            id={"Tas"}
            options={this.props.tas}
            selected={this.state.currentTas}
            toggleOption={this.toggleOptionTas}
            clearSelection={this.clearSelectionTAs}
          />
        </div>
      );
    }
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
        id={"Tags"}
        options={options}
        selected={this.state.currentTags}
        toggleOption={this.toggleOptionTags}
        clearSelection={this.clearSelectionTags}
      />
    );
  };

  renderTotalMarkRange = () => {
    return (
      <div className={"range"} onChange={e => this.handleTotalMark(e)} data-testid={"Total Mark"}>
        <input
          className={"input-min"}
          type="number"
          step="0.01"
          placeholder={"Min"}
          value={this.state.currentTotalMarkRange.min}
          max={this.state.currentTotalMarkRange.max}
          onChange={() => {}}
        />
        <span>to</span>
        <input
          className={"input-max"}
          type="number"
          step="0.01"
          placeholder={"Max"}
          value={this.state.currentTotalMarkRange.max}
          min={this.state.currentTotalMarkRange.min}
          onChange={() => {}}
        />
        <p className={"validity"}></p>
      </div>
    );
  };

  renderTotalExtraMarkRange = () => {
    return (
      <div
        className={"range"}
        onChange={e => this.handleTotalExtraMark(e)}
        data-testid={"Total Extra Mark"}
      >
        <input
          className={"input-min"}
          type="number"
          step="0.01"
          placeholder={"Min"}
          value={this.state.currentTotalExtraMarkRange.min}
          max={this.state.currentTotalExtraMarkRange.max}
          onChange={() => {}}
        />
        <span>to</span>
        <input
          className={"input-max"}
          type="number"
          step="0.01"
          placeholder={"Max"}
          value={this.state.currentTotalExtraMarkRange.max}
          min={this.state.currentTotalExtraMarkRange.min}
          onChange={() => {}}
        />
        <p className={"validity"}></p>
      </div>
    );
  };

  handleTotalMark(e) {
    if (e.target.className === "input-min") {
      this.setState({
        currentTotalMarkRange: {...this.state.currentTotalMarkRange, min: e.target.value},
      });
    } else {
      this.setState({
        currentTotalMarkRange: {...this.state.currentTotalMarkRange, max: e.target.value},
      });
    }
  }

  handleTotalExtraMark(e) {
    if (e.target.className === "input-min") {
      this.setState({
        currentTotalExtraMarkRange: {...this.state.currentTotalExtraMarkRange, min: e.target.value},
      });
    } else {
      this.setState({
        currentTotalExtraMarkRange: {...this.state.currentTotalExtraMarkRange, max: e.target.value},
      });
    }
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.mutateFilterData({
      ...this.props.filterData,
      orderBy: this.state.currentOrderBy,
      ascBool: this.state.currentAscBool,
      annotationValue: this.state.currentAnnotationValue,
      sectionValue: this.state.currentSectionValue,
      markingStateValue: this.state.currentMarkingStateValue,
      tas: this.state.currentTas,
      tags: this.state.currentTags,
      totalMarkRange: this.state.currentTotalMarkRange,
      totalExtraMarkRange: this.state.currentTotalExtraMarkRange,
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
              currentOrderBy: this.props.filterData.orderBy,
              currentAscBool: this.props.filterData.ascBool,
              currentAnnotationValue: this.props.filterData.annotationValue,
              currentSectionValue: this.props.filterData.sectionValue,
              currentMarkingStateValue: this.props.filterData.markingStateValue,
              currentTas: this.props.filterData.tas,
              currentTags: this.props.filterData.tags,
              currentTotalMarkRange: this.props.filterData.totalMarkRange,
              currentTotalExtraMarkRange: this.props.filterData.totalExtraMarkRange,
            });
            this.props.onRequestClose();
          }}
        >
          <h3>{I18n.t("results.filters.filter_by")}</h3>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-scrollable"}>
              <div className={"modal-container-vertical"}>
                <div className={"modal-container"}>
                  <div className={"filter"} data-testid={"order-by"}>
                    <p>{I18n.t("results.filters.order_by")} </p>
                    <SingleSelectDropDown
                      options={["Group Name", "Submission Date"]}
                      selected={this.state.currentOrderBy}
                      select={selection => {
                        this.setState({currentOrderBy: selection});
                      }}
                      defaultValue={"Group Name"}
                    />
                    <div
                      className={"order"}
                      onChange={e => {
                        this.setState({currentAscBool: !this.state.currentAscBool});
                      }}
                      data-testid={"radio-group"}
                    >
                      <input
                        type="radio"
                        checked={this.state.currentAscBool}
                        name="order"
                        value="Asc"
                        onChange={() => {}}
                        data-testid={"ascending"}
                      />
                      <label htmlFor="Asc">Ascending</label>
                      <input
                        type="radio"
                        checked={!this.state.currentAscBool}
                        name="order"
                        value="Desc"
                        onChange={() => {}}
                        data-testid={"descending"}
                      />
                      <label htmlFor="Desc">Descending</label>
                    </div>
                  </div>
                  <div className={"filter"} data-testid={"marking-state"}>
                    <p>Marking State</p>
                    <SingleSelectDropDown
                      options={[
                        I18n.t("submissions.state.in_progress"),
                        I18n.t("submissions.state.complete"),
                        I18n.t("submissions.state.released"),
                        I18n.t("submissions.state.remark_requested"),
                      ]}
                      selected={this.state.currentMarkingStateValue}
                      select={selection => {
                        this.setState({currentMarkingStateValue: selection});
                      }}
                    />
                  </div>
                </div>
                <div className={"modal-container"}>
                  <div className={"filter"}>
                    <p>{I18n.t("results.filters.tags")}</p>
                    {this.renderTagsDropdown()}
                  </div>
                  <div className={"filter"} data-testid={"section"}>
                    <p>Section</p>
                    <SingleSelectDropDown
                      options={this.props.sections}
                      selected={this.state.currentSectionValue}
                      select={selection => {
                        this.setState({currentSectionValue: selection});
                      }}
                      defaultValue={""}
                    />
                  </div>
                </div>
                <div className={"modal-container"}>
                  {this.renderTasDropdown()}
                  <label className={"annotation-input"}>
                    <p>{I18n.t("results.filters.annotation")}</p>
                    <input
                      id="annotation"
                      type={"text"}
                      value={this.state.currentAnnotationValue}
                      onChange={e => this.setState({currentAnnotationValue: e.target.value})}
                      placeholder={I18n.t("results.filters.text_box_placeholder")}
                    />
                  </label>
                </div>

                <div className={"modal-container"}>
                  <div className={"filter"}>
                    <p>Total Mark</p>
                    {this.renderTotalMarkRange()}
                  </div>
                  <div className={"filter"}>
                    <p>Total Extra Mark</p>
                    {this.renderTotalExtraMarkRange()}
                  </div>
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
