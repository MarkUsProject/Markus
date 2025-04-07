import React from "react";
import {createRoot} from "react-dom/client";
import PropTypes from "prop-types";

import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";

class TATable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
      counts: {all: 0, active: 0, inactive: 0},
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    fetch(Routes.course_tas_path(this.props.course_id), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.setState({data: res.data, counts: res.counts, loading: false});
      });
  }

  removeTA = ta_id => {
    fetch(Routes.course_ta_path(this.props.course_id, ta_id), {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
    })
      .then(response => {
        if (response.ok) {
          this.fetchData();
        }
      })
      .catch(error => {
        console.error("Error removing TA:", error);
      });
  };

  render() {
    const {data} = this.state;
    return (
      <ReactTable
        data={data}
        columns={[
          {
            Header: I18n.t("activerecord.attributes.user.user_name"),
            accessor: "user_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.first_name"),
            accessor: "first_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.last_name"),
            accessor: "last_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.email"),
            accessor: "email",
          },
          {
            Header: I18n.t("roles.active") + "?",
            accessor: "hidden",
            Cell: ({value}) => (value ? I18n.t("roles.inactive") : I18n.t("roles.active")),
            filterMethod: (filter, row) => {
              if (filter.value === "all") {
                return true;
              } else {
                return (
                  (filter.value === "active" && !row[filter.id]) ||
                  (filter.value === "inactive" && row[filter.id])
                );
              }
            },
            Filter: selectFilter,
            filterOptions: [
              {
                value: "active",
                text: `${I18n.t("roles.active")} (${this.state.counts.active})`,
              },
              {
                value: "inactive",
                text: `${I18n.t("roles.inactive")} (${this.state.counts.inactive})`,
              },
            ],
            filterAllOptionText: `${I18n.t("all")} (${this.state.counts.all})`,
          },
          {
            Header: I18n.t("actions"),
            accessor: "id",
            Cell: data => (
              <>
                <span>
                  <a href={Routes.edit_course_ta_path(this.props.course_id, data.value)}>
                    {I18n.t("edit")}
                  </a>
                </span>
                &nbsp;|&nbsp;
                <span>
                  <a href="#" onClick={() => this.removeTA(data.value)}>
                    {I18n.t("remove")}
                  </a>
                </span>
              </>
            ),
            filterable: false,
            sortable: false,
          },
        ]}
        filterable
        loading={this.state.loading}
      />
    );
  }
}

TATable.propTypes = {
  course_id: PropTypes.number,
};

function makeTATable(elem, props) {
  const root = createRoot(elem);
  root.render(<TATable {...props} />);
}

export {makeTATable, TATable};
