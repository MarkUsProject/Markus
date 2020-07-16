import React from 'react';
import {render} from 'react-dom';

class GradesSummaryDisplay extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      columns: [],
      loading: true,
      showHidden: false,
      filtered: [{id: 'hidden', value: false}]
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.populate_course_summaries_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res.data,
        columns: res.columns,
        loading: false,
      });
    });
  }

  nameColumns = [
    {
      id: 'hidden',
      accessor: 'hidden',
      filterMethod: (filter, row) => {
        return filter.value || !row.hidden;
      },
      className: 'rt-hidden',
      headerClassName: 'rt-hidden',
      resizable: false,
      width: 0,
    },
    {
      Header: I18n.t('activerecord.attributes.user.user_name'),
      accessor: 'user_name',
      filterable: true,
    },
    {
      Header: I18n.t('activerecord.attributes.user.first_name'),
      accessor: 'first_name',
      filterable: true,
    },
    {
      Header: I18n.t('activerecord.attributes.user.last_name'),
      accessor: 'last_name',
      filterable: true,
    },
  ];

  updateShowHidden = (event) => {
    let showHidden = event.target.checked;
    let filtered = [];
    for (let i = 0; i < this.state.filtered.length; i++) {
      if (this.state.filtered[i].id !== 'hidden') {
        filtered.push(this.state.filtered[i]);
      }
    }
    if (!showHidden) {
      filtered.push({id: 'hidden', value: false});
    }
    this.setState({filtered, showHidden});
  };

  render() {
  }
}

export function makeGradeSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
