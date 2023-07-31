import React from "react";
import {SingleSelectDropDown} from "../DropDownMenu/SingleSelectDropDown";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class CriteriaFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      criterion: "",
    };
  }

  criterionRange = (min, max, criterion) => {
    return (
      <li key={criterion}>
        <div className={"criterion-title"}>
          <span>{criterion}</span>
          <div className={"float-right"} onClick={() => this.removeCriterion(criterion)}>
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
    const criteria = this.props.criteria;
    return (
      <ul className={"criteria-list"}>
        {criteria.map(criterion => {
          return this.criterionRange(criterion.min, criterion.max, criterion.name);
        })}
      </ul>
    );
  };

  addCriterion = e => {
    e.preventDefault();
    this.props.addCriterion({name: this.state.criterion});
    this.setState({
      criterion: "",
    });
  };

  removeCriterion = criterion => {
    this.props.removeCriterion(criterion);
  };

  render() {
    return (
      <div className={"criteria-filter"}>
        <div className={"title"}>
          <p>{I18n.t("activerecord.models.criterion.other")}</p>
          <SingleSelectDropDown
            options={this.props.options
              .map(option => {
                return option.criterion;
              })
              .sort()}
            selected={this.state.criterion}
            onSelect={selection => {
              this.setState({criterion: selection});
            }}
            disabled={this.props.criteria.map(criterion => {
              return criterion.name;
            })}
            defaultValue={""}
          />
          <button
            className={"add-criterion"}
            onClick={e => this.addCriterion(e)}
            disabled={this.state.criterion === ""}
          >
            {I18n.t("results.filters.add_criterion")}
          </button>
        </div>
        {this.renderSelectedCriteria()}
      </div>
    );
  }
}
