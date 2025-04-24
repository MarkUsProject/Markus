import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../DropDown/MultiSelectDropDown";
import {SingleSelectDropDown} from "../DropDown/SingleSelectDropDown";
import {CriteriaFilter} from "../criteria_filter";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {ResultContext} from "../Result/result_context";

export class FilterModal extends React.Component {
  static contextType = ResultContext;

  onToggleOptionTas = user_name => {
    const newArray = [...this.props.filterData.tas];
    if (newArray.includes(user_name)) {
      this.props.updateFilterData({
        tas: newArray.filter(item => item !== user_name),
      });
    } else {
      newArray.push(user_name);
      this.props.updateFilterData({
        tas: newArray,
      });
    }
  };

  onClearSelectionTAs = () => {
    this.props.updateFilterData({
      tas: [],
    });
  };

  onClearSelectionTags = () => {
    this.props.updateFilterData({
      tags: [],
    });
  };

  onToggleOptionTags = tag => {
    const newArray = [...this.props.filterData.tags];
    if (newArray.includes(tag)) {
      this.props.updateFilterData({
        tags: newArray.filter(item => item !== tag),
      });
    } else {
      newArray.push(tag);
      this.props.updateFilterData({
        tags: newArray,
      });
    }
  };

  renderTasDropdown = () => {
    if (this.context.role === "Instructor") {
      let tas = this.props.tas.map(option => {
        return {key: option[0], display: option[0] + " - " + option[1]};
      });
      return (
        <div className={"filter"}>
          <p>{I18n.t("activerecord.models.ta.other")}</p>
          <MultiSelectDropdown
            title={"Tas"}
            options={tas}
            selected={this.props.filterData.tas}
            onToggleOption={this.onToggleOptionTas}
            onClearSelection={this.onClearSelectionTAs}
          />
        </div>
      );
    }
  };

  renderTagsDropdown = () => {
    let options = [];
    if (this.props.available_tags.length !== 0) {
      options = options.concat(
        this.props.available_tags.map(item => {
          return {key: item.name, display: item.name};
        })
      );
    }
    if (this.props.current_tags.length !== 0) {
      options = options.concat(
        this.props.current_tags.map(item => {
          return {key: item.name, display: item.name};
        })
      );
    }
    return (
      <MultiSelectDropdown
        title={"Tags"}
        options={options}
        selected={this.props.filterData.tags}
        onToggleOption={this.onToggleOptionTags}
        onClearSelection={this.onClearSelectionTags}
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
            aria-label={title + " - " + I18n.t("min")}
            type="number"
            step="any"
            placeholder={I18n.t("min")}
            value={min}
            max={max}
            onChange={e => onMinChange(e)}
          />
          <span>{I18n.t("to")}</span>
          <input
            className={"input-max"}
            aria-label={title + " - " + I18n.t("max")}
            type="number"
            step="any"
            placeholder={I18n.t("max")}
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
    this.props.updateFilterData({
      totalMarkRange: {...this.props.filterData.totalMarkRange, min: e.target.value},
    });
  };

  onTotalMarkMaxChange = e => {
    this.props.updateFilterData({
      totalMarkRange: {...this.props.filterData.totalMarkRange, max: e.target.value},
    });
  };

  onTotalExtraMarkMinChange = e => {
    this.props.updateFilterData({
      totalExtraMarkRange: {...this.props.filterData.totalExtraMarkRange, min: e.target.value},
    });
  };

  onTotalExtraMarkMaxChange = e => {
    this.props.updateFilterData({
      totalExtraMarkRange: {...this.props.filterData.totalExtraMarkRange, max: e.target.value},
    });
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onAddCriterion = criterion => {
    let criteria = {...this.props.filterData.criteria};
    criteria[criterion] = {};
    this.props.updateFilterData({
      criteria: criteria,
    });
  };

  onCriterionMinChange = (e, criterion) => {
    let criteria = {...this.props.filterData.criteria};
    criteria[criterion].min = e.target.value;
    this.props.updateFilterData({
      criteria: criteria,
    });
  };

  onCriterionMaxChange = (e, criterion) => {
    let criteria = {...this.props.filterData.criteria};
    criteria[criterion].max = e.target.value;
    this.props.updateFilterData({
      criteria: criteria,
    });
  };

  onDeleteCriterion = criterion => {
    let criteria = {...this.props.filterData.criteria};
    delete criteria[criterion];
    this.props.updateFilterData({
      criteria: criteria,
    });
  };

  onClearFilters = event => {
    event.preventDefault();
    this.props.clearAllFilters();
  };

  render() {
    if (this.props.loading) {
      return "";
    }
    return (
      <Modal
        className="react-modal markus-dialog filter-modal"
        isOpen={this.props.isOpen}
        onRequestClose={() => {
          this.props.onRequestClose();
        }}
      >
        <h3 className={"filter-modal-title"}>
          <FontAwesomeIcon icon="fa-solid fa-filter" className={"filter-icon-title"} />
          {I18n.t("results.filter_submissions")}
        </h3>
        <form>
          <div className={"modal-container-scrollable"}>
            <div className={"modal-container-vertical"}>
              <div className={"modal-container"}>
                <div className={"filter"} data-testid={"order-by"}>
                  <p>{I18n.t("results.filters.order_by")} </p>
                  <SingleSelectDropDown
                    valueToDisplayName={{
                      group_name: I18n.t("activerecord.attributes.group.group_name"),
                      submission_date: I18n.t("submissions.commit_date"),
                      total_mark: I18n.t("results.total_mark"),
                    }}
                    options={["group_name", "submission_date", "total_mark"]}
                    selected={this.props.filterData.orderBy}
                    onSelect={selection => {
                      this.props.updateFilterData({
                        orderBy: selection,
                      });
                    }}
                    defaultValue={I18n.t("activerecord.attributes.group.group_name")}
                  />
                  <div className={"order"} data-testid={"radio-group"}>
                    <input
                      className={"filter-order"}
                      type="radio"
                      checked={this.props.filterData.ascending}
                      name="order"
                      onChange={() => {
                        this.props.updateFilterData({ascending: true});
                      }}
                      id={"Asc"}
                      data-testid={"ascending"}
                    />
                    <label className={"filter-order"} htmlFor="Asc">
                      {I18n.t("results.filters.ordering.ascending")}
                    </label>
                    <input
                      className={"filter-order"}
                      type="radio"
                      checked={!this.props.filterData.ascending}
                      name="order"
                      onChange={() => {
                        this.props.updateFilterData({ascending: false});
                      }}
                      id={"Desc"}
                      data-testid={"descending"}
                    />
                    <label className={"filter-order"} htmlFor="Desc">
                      {I18n.t("results.filters.ordering.descending")}
                    </label>
                  </div>
                </div>
                <div className={"filter"} data-testid={"marking-state"}>
                  <p>{I18n.t("activerecord.attributes.result.marking_state")}</p>
                  <SingleSelectDropDown
                    valueToDisplayName={{
                      in_progress: I18n.t("submissions.state.in_progress"),
                      complete: I18n.t("submissions.state.complete"),
                      released: I18n.t("submissions.state.released"),
                      remark_requested: I18n.t("submissions.state.remark_requested"),
                    }}
                    options={["in_progress", "complete", "released", "remark_requested"]}
                    selected={this.props.filterData.markingState}
                    onSelect={selection => {
                      this.props.updateFilterData({
                        markingState: selection,
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
                    options={this.props.sections.sort()}
                    selected={this.props.filterData.section}
                    onSelect={selection => {
                      this.props.updateFilterData({
                        section: selection,
                      });
                    }}
                    defaultValue={""}
                  />
                </div>
              </div>
              <div className={"modal-container"}>
                {this.renderTasDropdown()}
                <div className={"annotation-input"}>
                  <p>{I18n.t("activerecord.models.annotation.one")}</p>
                  <input
                    type={"text"}
                    value={this.props.filterData.annotationText}
                    onChange={e =>
                      this.props.updateFilterData({
                        annotationText: e.target.value,
                      })
                    }
                    placeholder={I18n.t("results.filters.text_box_placeholder")}
                  />
                </div>
              </div>

              <div className={"modal-container"}>
                {this.rangeFilter(
                  this.props.filterData.totalMarkRange.min,
                  this.props.filterData.totalMarkRange.max,
                  I18n.t("results.total_mark"),
                  this.onTotalMarkMinChange,
                  this.onTotalMarkMaxChange
                )}
                {this.rangeFilter(
                  this.props.filterData.totalExtraMarkRange.min,
                  this.props.filterData.totalExtraMarkRange.max,
                  I18n.t("results.total_extra_marks"),
                  this.onTotalExtraMarkMinChange,
                  this.onTotalExtraMarkMaxChange
                )}
              </div>
            </div>
            <div className={"modal-container-vertical"} data-testid={"criteria"}>
              <CriteriaFilter
                options={this.props.criterionSummaryData}
                criteria={this.props.filterData.criteria}
                onAddCriterion={this.onAddCriterion}
                onDeleteCriterion={this.onDeleteCriterion}
                onMinChange={this.onCriterionMinChange}
                onMaxChange={this.onCriterionMaxChange}
              />
            </div>
          </div>
          <div className={"modal-footer"}>
            <section className={"modal-container dialog-actions"}>
              <button onClick={this.onClearFilters}>{I18n.t("clear_all")}</button>
              <button onClick={this.props.onRequestClose}>{I18n.t("close")}</button>
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}
