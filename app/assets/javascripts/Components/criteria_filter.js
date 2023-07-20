import React from "react";
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

  renderSelectedCriteria = () => {
    let rows = this.props.criteria.map(criteria => {
      return [
        <tr key={criteria.name}>
          <th style={{minWidth: "80%"}}>{criteria.name}</th>

          <td>{criteria.min}</td>
          <td>{criteria.max}</td>
          <td>
            {
              <div onClick={e => this.removeCriteria(e, criteria)}>
                <FontAwesomeIcon icon="fa-solid fa-xmark" />
              </div>
            }
          </td>
        </tr>,
      ];
    });

    return (
      <div style={{alignSelf: "stretch"}}>
        <table style={{minWidth: "100%"}}>
          <tbody>{rows}</tbody>
        </table>
      </div>
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
      <div className={"filter"}>
        <div>
          <p>Criteria</p>
          <SingleSelectDropDown
            options={this.props.options}
            selected={this.state.name}
            select={selection => {
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
        {/*<ul>*/}
        {/*  {this.props.criteria.map(selected => {*/}
        {/*    return (*/}
        {/*      <li key={selected.name}>*/}
        {/*        <span>*/}
        {/*          {selected.name}*/}
        {/*        </span>*/}
        {/*      </li>*/}
        {/*    );*/}
        {/*  })}*/}
        {/*</ul>*/}
      </div>
    );
  }
}
