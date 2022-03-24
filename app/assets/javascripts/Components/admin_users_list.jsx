import React from "react";
import {render} from "react-dom";
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
    $.ajax({
      url: Routes.admin_users_path(),
      dataType: "json",
    }).then(data => {
      this.setState({users: data, loading: false});
    });
  };

  columns = userTypes => [
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
      filterMethod: (filter, row) => {
        if (filter.value === "all") {
          return true;
        } else {
          return filter.value === row[filter.id];
        }
      },
      Filter: selectFilter,
      filterOptions: userTypes.map(type => {
        return {text: type, value: type};
      }),
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      minWidth: 70,
      Cell: ({value}) => <a href="#">{I18n.t("edit")}</a>,
      sortable: false,
      filterable: false,
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.users}
        columns={this.columns(["AdminUser", "EndUser"])}
        filterable
        defaultSorted={[{id: "user_name"}]}
        loading={this.state.loading}
      />
    );
  }
}

export function makeAdminUsersList(elem, props) {
  render(<AdminUsersList {...props} />, elem);
}
