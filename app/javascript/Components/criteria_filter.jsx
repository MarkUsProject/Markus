import React from "react";
import {SingleSelectDropDown} from "./DropDown/SingleSelectDropDown";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class CriteriaFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedCriterion: "",
    };
  }

  criterionRange = (min, max, criterion) => {
    return (
      <li key={criterion}>
        <div className={"criterion-title"}>
          <span>{criterion}</span>
          <div
            className={"float-right clickable"}
            onClick={() => this.props.onDeleteCriterion(criterion)}
            data-testid={"remove-criterion"}
          >
            <FontAwesomeIcon icon="fa-solid fa-xmark" className={"x-mark"} />
          </div>
        </div>
        <div className={"range"} data-testid={criterion}>
          <input
            className={"input-min"}
            aria-label={criterion + " - " + I18n.t("min")}
            type="number"
            step="any"
            placeholder={I18n.t("min")}
            value={min}
            max={max}
            onChange={e => this.props.onMinChange(e, criterion)}
          />
          <span>{I18n.t("to")}</span>
          <input
            className={"input-max"}
            aria-label={criterion + " - " + I18n.t("max")}
            type="number"
            step="any"
            placeholder={I18n.t("max")}
            value={max}
            min={min}
            onChange={e => this.props.onMaxChange(e, criterion)}
          />
          <div className={"hidden"}>
            <FontAwesomeIcon icon={"fa-solid fa-circle-exclamation"} />
            <span className={"validity"}>{I18n.t("results.filters.invalid_range")}</span>
          </div>
        </div>
      </li>
    );
  };

  renderSelectedCriteria = () => {
    const criteria = Object.entries(this.props.criteria);
    return (
      <ul className={"criteria-list"}>
        {criteria.map(criterion => {
          return this.criterionRange(criterion[1].min, criterion[1].max, criterion[0]);
        })}
      </ul>
    );
  };

  onAddCriterion = e => {
    e.preventDefault();
    this.props.onAddCriterion(this.state.selectedCriterion);
    this.setState({
      selectedCriterion: "",
    });
  };

  render() {
    return (
      <div className={"criteria-filter"}>
        <div className={"title"}>
          <p>{I18n.t("activerecord.models.criterion.other")}</p>
          <SingleSelectDropDown
            options={this.props.options.map(option => option.criterion)}
            selected={this.state.selectedCriterion}
            onSelect={selection => {
              this.setState({selectedCriterion: selection});
            }}
            disabled={Object.keys(this.props.criteria)}
            defaultValue={""}
          />
          <button
            className={"add-criterion"}
            onClick={e => this.onAddCriterion(e)}
            disabled={this.state.selectedCriterion === ""}
          >
            {I18n.t("results.filters.add_criterion")}
          </button>
        </div>
        {this.renderSelectedCriteria()}
      </div>
    );
  }
}
