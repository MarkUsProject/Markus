import React from "react";

import ReactTable from "react-table";

export class CourseSummaryTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showHidden: false,
      filtered: [{id: "hidden", value: false}],
    };
  }

  static defaultProps = {
    assessments: [],
    marking_schemes: [],
    data: [],
  };

  nameColumns = [
    {
      id: "hidden",
      accessor: "hidden",
      filterMethod: (filter, row) => {
        return filter.value || !row.hidden;
      },
      className: "rt-hidden",
      headerClassName: "rt-hidden",
      resizable: false,
      width: 0,
    },
    {
      Header: I18n.t("activerecord.attributes.user.user_name"),
      accessor: "user_name",
      filterable: true,
    },
    {
      Header: I18n.t("activerecord.attributes.user.first_name"),
      accessor: "first_name",
      filterable: true,
    },
    {
      Header: I18n.t("activerecord.attributes.user.last_name"),
      accessor: "last_name",
      filterable: true,
    },
  ];

  updateShowHidden = event => {
    let showHidden = event.target.checked;
    let filtered = [];
    for (let i = 0; i < this.state.filtered.length; i++) {
      if (this.state.filtered[i].id !== "hidden") {
        filtered.push(this.state.filtered[i]);
      }
    }
    if (!showHidden) {
      filtered.push({id: "hidden", value: false});
    }
    this.setState({filtered, showHidden});
  };

  dataColumns = () => {
    let columns = [];
    this.props.assessments.map(data => {
      columns.push({
        accessor: `assessment_marks.${data["id"]}.mark`,
        Header: data["name"],
        minWidth: 50,
        className: "number",
        headerStyle: {textAlign: "right"},
      });
    });
    this.props.marking_schemes.map(data => {
      columns.push({
        accessor: `weighted_marks.${data["id"]}.mark`,
        Header: data["name"],
        minWidth: 50,
        className: "number",
        headerStyle: {textAlign: "right"},
      });
    });
    return columns;
  };

  render() {
    return [
      !this.props.student && (
        <div key="show-hidden" style={{height: "2em"}}>
          <input
            id="show_hidden"
            name="show_hidden"
            type="checkbox"
            checked={this.state.showHidden}
            onChange={this.updateShowHidden}
            style={{marginLeft: "5px", marginRight: "5px"}}
          />
          <label htmlFor="show_hidden">{I18n.t("students.display_inactive")}</label>
        </div>
      ),
      <ReactTable
        key="course-summary-table"
        data={this.props.data}
        columns={
          this.props.student ? this.dataColumns() : this.nameColumns.concat(this.dataColumns())
        }
        defaultSorted={[
          {
            id: "user_name",
          },
        ]}
        loading={this.props.loading}
        filtered={this.state.filtered}
        onFilteredChange={filtered => this.setState({filtered})}
        className={"auto-overflow"}
      />,
    ];
  }
}
