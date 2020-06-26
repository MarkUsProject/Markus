import React from 'react';
import ReactTable from 'react-table';
import { render } from 'react-dom';
import ReactDOM from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {}
  }

  componentDidMount() {
    this.fetchData();
  }

  remove_component = (panel) => {
    ReactDOM.unmountComponentAtNode(panel);
  }

  columns = [
    {
      Header: 'Applier',
      accessor: 'applier',
      maxWidth: 50,
      resizeable: false,
      Cell: row => {
        return (
          <div>
            {row.original.applier}
          </div>
        );
      }
    },
    {
      Header: 'Grouping_name',
      accessor: 'grouping_name',
      aggregate: (vals, pivots) => {
        console.log('vals')
        console.log(vals)
        console.log('pivots')
        console.log(pivots)
        return pivots[0].original.grouping_name + '...'
      },
      sortable: false,
      Aggregated: row => (
        <span>
          {row.value}
        </span>
      ),
      Cell: row => {
        return (
          <div>
            {row.original.grouping_name}
          </div>
        );
      },
      maxWidth: 150,
    }
  ];

  fetchData = () => {
    $.ajax({
      url: Routes.get_annotation_text_stats_assignment_annotation_categories_path(this.props.assignment_id),
      data: {
        annotation_text_id: this.props.annotation_id
      },
      dataType: 'json'
    }).then(res => {
      this.setState({applications: res['uses'], num_times_used: res['num_times_used']});
    });
  };

  render() {
    return (<fieldset>
      <p>{JSON.stringify(this.state)}</p>
      <ReactTable
        className='auto-overflow'
        data={this.state.applications}
        columns={this.columns}
        filterable
        pivotBy={['applier']}
      />
    </fieldset>);
  }
}


export function makeAnnotationStatPanel(elem, props) {
  return render(<AnnotationStatPanel {...props} />, elem);
}
