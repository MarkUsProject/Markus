import React from "react";
import {SingleSelectDropDown} from "../DropDownMenu/SingleSelectDropDown";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class CriteriaFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
    };
  }

  criteriaFilter = (min, max, criteria) => {
    return (
      <li>
        <div className={"criteria-title"}>
          <span>{criteria}</span>
          <div className={"float-right"} onClick={() => this.removeCriteria(criteria)}>
            <FontAwesomeIcon icon="fa-solid fa-xmark" className={"x-mark"} />
          </div>
        </div>
        <div className={"range"} data-testid={criteria}>
          <input
            className={"input-min"}
            aria-label={criteria + " - " + I18n.t("min")}
            type="number"
            step="any"
            placeholder={I18n.t("min")}
            value={min}
            max={max}
            onChange={e => this.props.onMinChange(e, criteria)}
          />
          <span>{I18n.t("to")}</span>
          <input
            className={"input-max"}
            aria-label={criteria + " - " + I18n.t("max")}
            type="number"
            step="any"
            placeholder={I18n.t("max")}
            value={max}
            min={min}
            onChange={e => this.props.onMaxChange(e, criteria)}
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
      <ul className={"criterion-list"}>
        {criteria.map(criteria => {
          return this.criteriaFilter(criteria.min, criteria.max, criteria.name);
        })}
      </ul>
    );
  };

  addCriteria = e => {
    e.preventDefault();
    this.props.addCriteria({name: this.state.name});
    this.setState({
      name: "",
    });
  };

  removeCriteria = criteria => {
    this.props.removeCriteria(criteria);
  };

  render() {
    return (
      <div className={"criterion-filter"}>
        <div>
          <p>Criteria</p>
          <SingleSelectDropDown
            options={this.props.options
              .map(option => {
                return option.criterion;
              })
              .sort()}
            selected={this.state.name}
            onSelect={selection => {
              this.setState({name: selection});
            }}
            disabled={this.props.criteria.map(criteria => {
              return criteria.name;
            })}
          />
          <button
            className={"add-criteria"}
            value={"Add Criteria"}
            onClick={e => this.addCriteria(e)}
            disabled={this.state.name === ""}
          >
            Add Criteria
          </button>
        </div>
        {this.renderSelectedCriteria()}
      </div>
    );
  }
}
