import React from "react";
import Modal from "react-modal";
import {MultiSelectDropdown} from "../../DropDownMenu/MultiSelectDropDown";
import {SingleSelectDropDown} from "../../DropDownMenu/SingleSelectDropDown";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class FilterModal extends React.Component {
  constructor(props) {
    super(props);
  }

  onToggleOptionTas = user_name => {
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

  onClearSelectionTAs = () => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      tas: [],
    });
  };

  onClearSelectionTags = () => {
    this.props.mutateFilterData({
      ...this.props.filterData,
      tags: [],
    });
  };

  onToggleOptionTags = tag => {
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
    if (this.props.role === "Instructor") {
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
                    onSelect={selection => {
                      this.props.mutateFilterData({
                        ...this.props.filterData,
                        orderBy: selection,
                      });
                    }}
                    defaultValue={I18n.t("activerecord.attributes.group.group_name")}
                  />
                  <div className={"order"} data-testid={"radio-group"}>
                    <input
                      type="radio"
                      checked={this.props.filterData.ascending}
                      name="order"
                      onChange={() => {
                        this.props.mutateFilterData({...this.props.filterData, ascending: true});
                      }}
                      data-testid={"ascending"}
                    />
                    <label htmlFor="Asc">{I18n.t("results.filters.ordering.ascending")}</label>
                    <input
                      type="radio"
                      checked={!this.props.filterData.ascending}
                      name="order"
                      onChange={() => {
                        this.props.mutateFilterData({...this.props.filterData, ascending: false});
                      }}
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
                    selected={this.props.filterData.markingState}
                    onSelect={selection => {
                      this.props.mutateFilterData({
                        ...this.props.filterData,
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
                    options={this.props.sections}
                    selected={this.props.filterData.section}
                    onSelect={selection => {
                      this.props.mutateFilterData({
                        ...this.props.filterData,
                        section: selection,
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
                    type={"text"}
                    value={this.props.filterData.annotationText}
                    onChange={e =>
                      this.props.mutateFilterData({
                        ...this.props.filterData,
                        annotationText: e.target.value,
                      })
                    }
                    placeholder={I18n.t("results.filters.text_box_placeholder")}
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
              <input type="reset" value={I18n.t("clear_all")} onClick={this.onClearFilters} />
              <input type="submit" value={I18n.t("close")} />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}
