import React from "react";
import ReactTable from "react-table";
import {SingleSelectDropDown} from "../DropDownMenu/SingleSelectDropDown";
import {RangeFilter} from "./Helpers/range_filter";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class CriteriaFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      min: "",
      max: "",
      error: true,
      disabled: this.props.criteria.map(criteria => {
        return criteria.name;
      }),
    };
  }

  handleRange = e => {
    if (e.target.className === "input-min") {
      this.setState({min: e.target.value});
    } else {
      this.setState({max: e.target.value});
    }
  };

  componentDidUpdate(prevProps, prevState) {
    if (
      prevState.name !== this.state.name ||
      prevState.min !== this.state.min ||
      prevState.max !== this.state.max
    ) {
      if (this.state.name !== "" && (this.state.min !== "" || this.state.max !== "")) {
        this.setState({error: false});
      } else {
        this.setState({error: true});
      }
    }

    if (prevProps.criteria !== this.props.criteria) {
      this.setState({
        disabled: this.props.criteria.map(criteria => {
          return criteria.name;
        }),
      });
    }
  }

  criterionColumns = () => [
    {
      Header: I18n.t("activerecord.models.criterion.one"),
      accessor: "name",
      maxWidth: 85,
    },
    {
      Header: "Min",
      accessor: "min",
      maxWidth: 40,
      className: "number",
    },
    {
      Header: "Max",
      accessor: "max",
      maxWidth: 40,
      className: "number",
    },
    {
      Header: "",
      id: "action",
      minWidth: 18,
      Cell: row => {
        return (
          <div onClick={() => this.props.removeCriteria(row.original)}>
            <FontAwesomeIcon icon="fa-solid fa-xmark" className={"no-padding"} />
          </div>
        );
      },
    },
  ];

  renderSelectedCriteria = () => {
    return (
      <ReactTable
        columns={this.criterionColumns()}
        data={this.props.criteria}
        className="auto-overflow criterion"
      />
    );
  };

  addCriteria = e => {
    e.preventDefault();
    this.props.addCriteria({name: this.state.name, min: this.state.min, max: this.state.max});
    let disabled = this.state.disabled;
    disabled.push(this.state.name);
    this.setState({
      name: "",
      min: "",
      max: "",
      disabled: disabled,
    });
  };

  removeCriteria = (e, criteria) => {
    e.preventDefault();
    this.props.removeCriteria(criteria);
  };

  render() {
    return (
      <div className={"criterion-filter"}>
        <div>
          <p>Criteria</p>
          <SingleSelectDropDown
            options={this.props.options}
            selected={this.state.name}
            onSelect={selection => {
              this.setState({name: selection});
            }}
            disabled={this.state.disabled}
          />
          <RangeFilter handleInputs={this.handleRange} min={this.state.min} max={this.state.max} />
          <button
            id={"Add criteria"}
            value={"Add Criteria"}
            onClick={e => this.addCriteria(e)}
            disabled={this.state.error}
          >
            Add Criteria
          </button>
        </div>
        {this.renderSelectedCriteria()}
      </div>
    );
  }
}
