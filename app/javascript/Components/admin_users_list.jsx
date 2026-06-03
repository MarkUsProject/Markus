import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";
import {faPencil} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class AdminUsersList extends React.Component {
  constructor() {
    super();
    this.state = {
      users: [],
      pages: 0,
      loading: true,
      page: 0,
      pageSize: 100, // Explicitly locked to 100
    };
    this.previousFiltered = "[]";
    this.previousSorted = "[]";
  }

  fetchDataServerSide = state => {
    this.setState({loading: true});
    const currentFilteredStr = JSON.stringify(state.filtered);
    const currentSortedStr = JSON.stringify(state.sorted);

    let targetPage = state.page;
    if (this.previousFiltered !== currentFilteredStr || this.previousSorted !== currentSortedStr) {
      targetPage = 0;
      this.previousFiltered = currentFilteredStr;
      this.previousSorted = currentSortedStr;
    }

    const params = new URLSearchParams({
      page: targetPage + 1,
      per_page: state.pageSize,
      sorted: currentSortedStr,
      filtered: currentFilteredStr,
    });

    fetch(`${Routes.admin_users_path()}?${params.toString()}`, {
      headers: {Accept: "application/json"},
    })
      .then(response => {
        if (response.ok) return response.json();
        throw new Error("Failed to fetch grid data");
      })
      .then(data => {
        this.setState({
          users: data && data.users ? data.users : [],
          pages: data && data.total_pages ? data.total_pages : 1,
          loading: false,
          page: targetPage,
          pageSize: state.pageSize,
        });
      })
      .catch(err => {
        console.error("Pagination error:", err);
        this.setState({users: [], pages: 1, loading: false});
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
      Cell: ({value}) =>
        value === "AdminUser"
          ? I18n.t("activerecord.models.admin_user.one")
          : I18n.t("activerecord.models.end_user.one"),
      Filter: selectFilter,
      filterOptions: [
        {text: I18n.t("activerecord.models.admin_user.one"), value: "AdminUser"},
        {text: I18n.t("activerecord.models.end_user.one"), value: "EndUser"},
      ],
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      minWidth: 70,
      Cell: ({value}) => (
        <a
          href={Routes.edit_admin_user_path(value)}
          aria-label={I18n.t("edit")}
          title={I18n.t("edit")}
        >
          <FontAwesomeIcon icon={faPencil} />
        </a>
      ),
      sortable: false,
      filterable: false,
    },
  ];

  render() {
    return (
      <ReactTable
        manual
        data={this.state.users}
        pages={this.state.pages}
        page={this.state.page}
        pageSize={this.state.pageSize}
        columns={this.columns}
        filterable
        showPagination={true}
        showPaginationBottom={true}
        showPageSizeOptions={false}
        defaultPageSize={100}
        defaultSorted={[{id: "user_name"}]}
        loading={this.state.loading}
        onFetchData={this.fetchDataServerSide}
        onPageChange={page => this.setState({page})}
      />
    );
  }
}

export function makeAdminUsersList(elem, props) {
  const root = createRoot(elem);
  root.render(<AdminUsersList {...props} />);
}
