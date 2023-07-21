import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";
import {SingleSelectDropDown} from "../../DropDownMenu/SingleSelectDropDown";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

const INITIAL_MODAL_STATE = {
  currentOrderBy: I18n.t("activerecord.attributes.group.group_name"),
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
  }

  toggleOptionTas = user_name => {
    const newArray = [...this.props.filterData.tas];
    if (newArray.includes(user_name)) {
      this.props.mutateFilterData({
        ...this.props.filterData,
        tas: newArray.filter(item => item !== user_name),
      });
    } else {
      newArray.push(user_name);
      this.props.mutateFilterData({
        ...this.props.filterData,
        tas: newArray,
      });
    }
  };

  clearSelectionTAs = () => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      tas: [],
    });
  };

  clearSelectionTags = () => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      tags: [],
    });
  };

  toggleOptionTags = tag => {
    const newArray = [...this.props.filterData.tags];
    if (newArray.includes(tag)) {
      this.props.mutateFilterData({
        ...this.props.filterData,
        tags: newArray.filter(item => item !== tag),
      });
    } else {
      newArray.push(tag);
      this.props.mutateFilterData({
        ...this.props.filterData,
        tags: newArray,
      });
    }
  };

  renderTasDropdown = () => {
    if (this.props.role !== "Ta") {
      return (
        <div className={"filter"}>
          <p>{I18n.t("activerecord.models.ta.other")}</p>
          <MultiSelectDropdown
            id={"Tas"}
            options={this.props.tas}
            selected={this.props.filterData.tas}
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
        selected={this.props.filterData.tags}
        toggleOption={this.toggleOptionTags}
        clearSelection={this.clearSelectionTags}
      />
    );
  };

  rangeFilter = (min, max, title, onMinChange, onMaxChange) => {
    return (
      <div className={"filter"}>
        <p>{title}</p>
        <div className={"range"} data-testid={title}>
          <input
            className={"input-min"}
            type="number"
            step="any"
            placeholder={"Min"}
            value={min}
            max={max}
            onChange={e => onMinChange(e)}
          />
          <span>{I18n.t("to")}</span>
          <input
            className={"input-max"}
            type="number"
            step="any"
            placeholder={"Max"}
            value={max}
            min={min}
            onChange={e => onMaxChange(e)}
          />
          <div className={"hidden"}>
            <FontAwesomeIcon icon={"fa-solid fa-circle-exclamation"} />
            <span className={"validity"}>{I18n.t("results.filters.invalid_range")}</span>
          </div>
        </div>
      </div>
    );
  };

  onTotalMarkMinChange = e => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      totalMarkRange: {...this.props.filterData.totalMarkRange, min: e.target.value},
    });
  };

  onTotalMarkMaxChange = e => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      totalMarkRange: {...this.props.filterData.totalMarkRange, max: e.target.value},
    });
  };

  onTotalExtraMarkMinChange = e => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      totalExtraMarkRange: {...this.props.filterData.totalExtraMarkRange, min: e.target.value},
    });
  };

  onTotalExtraMarkMaxChange = e => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      totalExtraMarkRange: {...this.props.filterData.totalExtraMarkRange, max: e.target.value},
    });
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onRequestClose();
  };

  clearFilters = event => {
    event.preventDefault();
    this.props.clearAllFilters();
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
                      options={[
                        I18n.t("activerecord.attributes.group.group_name"),
                        I18n.t("submissions.commit_date"),
                      ]}
                      selected={this.props.filterData.orderBy}
                      select={selection => {
                        this.props.mutateFilterData({
                          ...this.props.filterData,
                          orderBy: selection,
                        });
                      }}
                      defaultValue={I18n.t("activerecord.attributes.group.group_name")}
                    />
                    <div
                      className={"order"}
                      onChange={e => {
                        this.props.mutateFilterData({
                          ...this.props.filterData,
                          ascBool: !this.props.filterData.ascBool,
                        });
                      }}
                      data-testid={"radio-group"}
                    >
                      <input
                        type="radio"
                        checked={this.props.filterData.ascBool}
                        name="order"
                        value="Asc"
                        onChange={() => {}}
                        data-testid={"ascending"}
                      />
                      <label htmlFor="Asc">{I18n.t("results.filters.ordering.ascending")}</label>
                      <input
                        type="radio"
                        checked={!this.props.filterData.ascBool}
                        name="order"
                        value="Desc"
                        onChange={() => {}}
                        data-testid={"descending"}
                      />
                      <label htmlFor="Desc">{I18n.t("results.filters.ordering.descending")}</label>
                    </div>
                  </div>
                  <div className={"filter"} data-testid={"marking-state"}>
                    <p>{I18n.t("activerecord.attributes.result.marking_state")}</p>
                    <SingleSelectDropDown
                      options={[
                        I18n.t("submissions.state.in_progress"),
                        I18n.t("submissions.state.complete"),
                        I18n.t("submissions.state.released"),
                        I18n.t("submissions.state.remark_requested"),
                      ]}
                      selected={this.props.filterData.markingStateValue}
                      select={selection => {
                        this.props.mutateFilterData({
                          ...this.props.filterData,
                          markingStateValue: selection,
                        });
                      }}
                    />
                  </div>
                </div>
                <div className={"modal-container"}>
                  <div className={"filter"}>
                    <p>{I18n.t("activerecord.models.tag.other")}</p>
                    {this.renderTagsDropdown()}
                  </div>
                  <div className={"filter"} data-testid={"section"}>
                    <p>{I18n.t("activerecord.models.section.one")}</p>
                    <SingleSelectDropDown
                      options={this.props.sections}
                      selected={this.props.filterData.sectionValue}
                      select={selection => {
                        this.props.mutateFilterData({
                          ...this.props.filterData,
                          sectionValue: selection,
                        });
                      }}
                      defaultValue={""}
                    />
                  </div>
                </div>
                <div className={"modal-container"}>
                  {this.renderTasDropdown()}
                  <label className={"annotation-input"}>
                    <p>{I18n.t("activerecord.models.annotation.one")}</p>
                    <input
                      id="annotation"
                      type={"text"}
                      value={this.props.filterData.annotationValue}
                      onChange={e =>
                        this.props.mutateFilterData({
                          ...this.props.filterData,
                          annotationValue: e.target.value,
                        })
                      }
                      placeholder={I18n.t("to")}
                    />
                  </label>
                </div>

                <div className={"modal-container"}>
                  {this.rangeFilter(
                    this.props.filterData.totalMarkRange.min,
                    this.props.filterData.totalMarkRange.max,
                    I18n.t("results.filters.total_mark"),
                    this.onTotalMarkMinChange,
                    this.onTotalMarkMaxChange
                  )}
                  {this.rangeFilter(
                    this.props.filterData.totalExtraMarkRange.min,
                    this.props.filterData.totalExtraMarkRange.max,
                    I18n.t("results.filters.total_extra_mark"),
                    this.onTotalExtraMarkMinChange,
                    this.onTotalExtraMarkMaxChange
                  )}
                </div>
              </div>
            </div>
            <div className={"modal-footer"}>
              <section className={"modal-container dialog-actions"}>
                <input
                  id={"clear_all"}
                  type="reset"
                  value={I18n.t("clear_all")}
                  onClick={this.clearFilters}
                />
                <input type="submit" value={I18n.t("close")} />
              </section>
            </div>
          </form>
        </Modal>
      </div>
    );
  }
}
