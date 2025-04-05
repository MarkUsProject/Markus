import React from "react";
import Modal from "react-modal";
import ReactTable from "react-table";
import Flatpickr from "react-flatpickr";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class ReleaseUrlsModal extends React.Component {
  constructor() {
    super();
    this.state = {loading: false};
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  refreshViewTokens = result_ids => {
    if (!confirm(I18n.t("submissions.refresh_token_confirmation"))) {
      return;
    }
    this.setState({loading: true}, () => {
      $.ajax({
        type: "PUT",
        url: Routes.refresh_view_tokens_course_assignment_results_url(
          this.props.course_id,
          this.props.assignment_id,
          {result_ids: result_ids}
        ),
      }).then(res => this.props.refreshViewTokens(res, () => this.setState({loading: false})));
    });
  };

  refreshViewTokenExpiry = (expiry_datetime, result_ids) => {
    if (
      result_ids.length > 1 &&
      !confirm(
        expiry_datetime
          ? I18n.t("submissions.update_all_token_expiry_confirmation", {date: expiry_datetime})
          : I18n.t("submissions.clear_all_token_expiry_confirmation")
      )
    ) {
      return;
    }
    this.setState({loading: true}, () => {
      $.ajax({
        type: "PUT",
        url: Routes.update_view_token_expiry_course_assignment_results_url(
          this.props.course_id,
          this.props.assignment_id,
          {result_ids: result_ids, expiry_datetime: expiry_datetime}
        ),
      }).then(res => this.props.refreshViewTokenExpiry(res, () => this.setState({loading: false})));
    });
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <div className="rt-action-box">
          <button onClick={() => this.refreshViewTokens(this.props.data.map(d => d["result_id"]))}>
            {I18n.t("submissions.refresh_all_tokens")}
          </button>
          <Flatpickr
            placeholder={I18n.t("submissions.update_all_token_expiry")}
            onClose={selectedDates => {
              this.refreshViewTokenExpiry(
                selectedDates[0],
                this.props.data.map(d => d["result_id"])
              );
            }}
            options={{
              altInput: true,
              altFormat: I18n.t("time.format_string.flatpickr"),
              dateFormat: "Z",
              enableTime: true,
              showMonths: 2,
            }}
          />
          <a
            className={"button"}
            href={Routes.download_view_tokens_course_assignment_results_url(
              this.props.course_id,
              this.props.assignment_id,
              {result_ids: this.props.data.map(d => d["result_id"])}
            )}
          >
            {I18n.t("download")}
          </a>
        </div>
        <ReactTable
          data={this.props.data}
          filterable
          defaultSorted={[{id: "group_name"}]}
          loading={this.state.loading}
          columns={[
            {
              show: false,
              accessor: "_id",
              id: "_id",
            },
            {
              Header: I18n.t("activerecord.models.group.one"),
              accessor: "group_name",
              id: "group_name",
              Cell: this.props.groupNameWithMembers,
              minWidth: 250,
              filterMethod: this.props.groupNameFilter,
            },
            {
              Header: I18n.t("submissions.release_token"),
              id: "result_view_token",
              filterable: false,
              sortable: false,
              minWidth: 250,
              Cell: row => {
                return (
                  <div>
                    <a
                      href="#"
                      className="refresh"
                      onClick={() => this.refreshViewTokens([row.original.result_id])}
                      title={I18n.t("refresh")}
                    >
                      <FontAwesomeIcon icon="fa-solid fa-refresh" className="icon-left" />
                    </a>
                    {row.original.result_view_token}
                  </div>
                );
              },
            },
            {
              Header: I18n.t("submissions.release_token_expires"),
              id: "result_view_token_expiry",
              filterable: false,
              sortable: false,
              minWidth: 200,
              Cell: row => {
                return (
                  <Flatpickr
                    value={row.original.result_view_token_expiry}
                    onClose={selectedDates =>
                      this.refreshViewTokenExpiry(selectedDates[0], [row.original.result_id])
                    }
                    options={{
                      altInput: true,
                      altFormat: I18n.t("time.format_string.flatpickr"),
                      dateFormat: "Z",
                    }}
                  />
                );
              },
            },
          ]}
          SubComponent={row => {
            if (row.original.result_view_token) {
              const url = Routes.view_marks_course_result_url(
                this.props.course_id,
                row.original.result_id,
                {view_token: row.original.result_view_token}
              );
              return (
                <div style={{whiteSpace: "pre-wrap"}}>
                  {I18n.t("submissions.release_url_with_token", {url: url})}
                </div>
              );
            } else {
              return "";
            }
          }}
        />
      </Modal>
    );
  }
}

export default ReleaseUrlsModal;
