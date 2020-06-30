import React from 'react';
import ReactTable from 'react-table';
import { render } from 'react-dom';
import ReactDOM from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applications: null,
      details: false
    }
  }

  toggle = () => {
    if (this.state.applications === null) {
      this.fetchData()
    }
    this.setState({details: !this.state.details})
  }

  columns = [
    {
      Header: I18n.t('annotations.used_by'),
      accessor: row => row['users.first_name'],
      id: 'user',
      minWidth: 200,
      maxWidth: 200,
      resizeable: false,
      PivotValue: ({value}) => value,
      Cell: row => {
        return '(' + row.original['users.first_name'] + ') ' + row.original['users.first_name'] +
          ' ' + row.original['users.last_name'];
      }
    },
    {
      Header: I18n.t('activerecord.models.submission.one'),
      accessor: row => row['groups.group_name'],
      id: 'group',
      aggregate: (vals, pivots) => I18n.t('annotations.used_times', {'number': pivots.length}),
      sortable: false,
      Aggregated: row => (
        <span>
          {'(' + row.value + ')'}
        </span>
      ),
      Cell: row => {
        return (
          <div>
            <a href={Routes.edit_assignment_submission_result_path(
              row.original['groupings.assessment_id'],
              row.original['results.submission_id'],
              row.original['results.id']
            )}
            >
              {row.original['groups.group_name']}
            </a>
          </div>
        );
      },
      maxWidth: 200,
    }
  ];

  fetchData = () => {
    $.ajax({
      url: Routes.annotation_text_stats_assignment_annotation_categories_path(this.props.assignment_id),
      data: {
        annotation_text_id: this.props.annotation_id
      },
      dataType: 'json'
    }).then(res => {
      this.setState({applications: res['uses'], num_times_used: res['num_times_used']});
    });
  };

  render() {

    let annotation_table =  (
      <ReactTable
        className='auto-overflow'
        data={this.state.applications}
        columns={this.columns}
        filterable
        pivotBy={['user']}
      />);

    if (this.state.details) {
      return (<fieldset>
        <a onclick={this.toggle()}>{I18n.t('annotations.count') + this.state.num_times_used}</a>
        {annotation_table}
      </fieldset>);
    } else {
      return <a onClick={this.toggle()}>{I18n.t('annotations.count') + this.state.num_times_used}</a>;
    }
  }
}


export function makeAnnotationStatPanel(elem, props) {
  return render(<AnnotationStatPanel {...props} />, elem);
}
