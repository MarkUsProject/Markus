import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";

class AdminUsersList extends React.Component {
  constructor() {
    super();
    this.state = {
      users: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.admin_users_path(), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(data => {
        this.setState({users: data, loading: false});
      });
  };

  columns = [
    {
      Header: I18n.t("activerecord.attributes.user.user_name"),
      accessor: "user_name",
      id: "user_name",
      minWidth: 120,
    },
    {
      Header: I18n.t("activerecord.attributes.user.first_name"),
      accessor: "first_name",
      minWidth: 120,
    },
    {
      Header: I18n.t("activerecord.attributes.user.last_name"),
      accessor: "last_name",
      minWidth: 120,
    },
    {
      Header: I18n.t("activerecord.attributes.user.email"),
      accessor: "email",
      minWidth: 150,
    },
    {
      Header: I18n.t("activerecord.attributes.user.id_number"),
      accessor: "id_number",
      minWidth: 90,
      className: "number",
    },
    {
      Header: I18n.t("activerecord.attributes.user.user_type"),
      accessor: "type",
      minWidth: 90,
      Cell: ({value}) => {
        if (value === "AdminUser") {
          return I18n.t("activerecord.models.admin_user.one");
        } else {
          return I18n.t("activerecord.models.end_user.one");
        }
      },
      filterMethod: (filter, row) => {
        if (filter.value === "all") {
          return true;
        } else {
          return filter.value === row[filter.id];
        }
      },
      Filter: selectFilter,
      filterOptions: [
        {
          text: I18n.t("activerecord.models.admin_user.one"),
          value: "AdminUser",
        },
        {
          text: I18n.t("activerecord.models.end_user.one"),
          value: "EndUser",
        },
      ],
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      minWidth: 70,
      Cell: ({value}) => <a href={Routes.edit_admin_user_path(value)}>{I18n.t("edit")}</a>,
      sortable: false,
      filterable: false,
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.users}
        columns={this.columns}
        filterable
        defaultSorted={[{id: "user_name"}]}
        loading={this.state.loading}
      />
    );
  }
}

export function makeAdminUsersList(elem, props) {
  const root = createRoot(elem);
  root.render(<AdminUsersList {...props} />);
}
