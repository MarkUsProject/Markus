import React from 'react';
import { render } from 'react-dom';
import ReactTable from 'react-table';


export class SummaryPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showNewExtraMark: false,
    }
  }

  criterionColumns = () => [
    {
      Header: I18n.t('activerecord.models.criterion.one'),
      accessor: 'criterion',
      classes: ['left']
    },
    {
      Header: 'Old Mark',
      accessor: 'old_mark',
      className: 'number',
      show: this.props.remark_submitted
    },
    {
      Header: I18n.t('activerecord.models.mark.one'),
      id: 'mark',
      className: 'number',
      Cell: row => {
        let mark = row.original.mark;
        if (mark === undefined || mark === null) {
          mark = '-';
        }
        return `${mark} / ${row.original.max_mark}`;
      }
    }
  ];

  renderTotalMark = () => {
    let oldTotal = '';
    if (this.props.remark_submitted) {
      oldTotal = (
        <div className='mark_total'>
          <span>
            {I18n.t('results.remark.old_total')}
          </span>
          <span className='final_mark'>
            <span>{this.props.old_total}</span>
            &nbsp;/&nbsp;
            {this.props.assignment_max_mark}
          </span>
        </div>
      );
    }
    let currentTotal = (
      <div className='mark_total'>
        <span>
          {I18n.t('activerecord.attributes.result.total_mark')}
        </span>
        <span className='final_mark'>
          <span>{this.props.total}</span>
          &nbsp;/&nbsp;
          {this.props.assignment_max_mark}
        </span>
      </div>
    );

    return (<div>{oldTotal}{currentTotal}</div>)
  };

  extraMarksColumns = () => [
    {
      Header: I18n.t('activerecord.attributes.extra_mark.description'),
      accessor: 'description',
      minWidth: 150,
      Cell: (row) => {
        if (row.original._new) {
          return <input type={'text'} defaultValue='' style={{width: '100%'}}/>;
        } else {
          return row.value;
        }
      }
    },
    {
      Header: I18n.t('activerecord.attributes.extra_mark.extra_mark'),
      accessor: 'extra_mark',
      minWidth: 80,
      className: 'number',
      Cell: (row) => {
        if (row.original._new) {
          return <input type={'number'} step='any' defaultValue={0} />;
        } else if (row.original.unit === 'points') {
          return row.value;
        } else {
          // Percentage
          let mark_value = (row.value * this.props.assignment_max_mark / 100).toFixed(2);
          return `${mark_value} (${row.value}%)`;
        }
      }
    },
    {
      Header: '',
      id: 'action',
      show: !this.props.released_to_students,
      Cell: (row) => {
        if (row.original._new) {
          return (
            <button
              onClick={this.createExtraMark}
              className='inline-button'>
              {I18n.t('save')}
            </button>
          );
        } else {
          return (
            <button
              onClick={() => this.props.destroyExtraMark(row.original.id)}
              className='inline-button'>
              {I18n.t('remove')}
            </button>
          );
        }
      }
    }
  ];

  newExtraMark = () => {
    this.setState({showNewExtraMark: true});
  };

  createExtraMark = (event) => {
    let row = event.target.parentElement.parentElement;
    let description = row.children[0].children[0].value;
    let extra_mark = row.children[1].children[0].value;
    this.props.createExtraMark(description, extra_mark).then(() =>
      this.setState({showNewExtraMark: false})
    );
  };

  renderExtraMarks = () => {
    // If there are no extra marks and this result is released, display nothing.
    if (this.props.is_reviewer ||
        (this.props.released_to_students && this.props.extra_marks.length === 0)) {
      return '';
    }

    let data;
    if (this.state.showNewExtraMark) {
      data = this.props.extra_marks.concat([
        {
          _new: true,
          extra_mark: 0,
          description: '',
          id: null
        }
      ]);
    } else {
      data = this.props.extra_marks;
    }

    return (
      <div className='extra-marks-pane'>
        <div className='bonus-deduction'>
          <strong>{I18n.t('activerecord.models.extra_mark.other')}</strong>
        </div>
        {data.length > 0 &&
         <ReactTable
           columns={this.extraMarksColumns()}
           data={data} />
        }
        {!this.props.released_to_students &&
         <div>
           <button onClick={this.newExtraMark}>
             {I18n.t('helpers.submit.create',
                     {model: I18n.t('activerecord.models.extra_mark.one')})}
           </button>
         </div>
        }
        <div className='mark_total'>
          {I18n.t('results.total_extra_marks')}
          <span className='final_mark'>
            {this.props.extraMarkSubtotal.toFixed(2)}
          </span>
        </div>
      </div>
    );
  };

  renderGraceTokenDeductions = () => {
    if (this.props.graceTokenDeductions.length === 0) {
      return '';
    } else {
      let rows = this.props.graceTokenDeductions.flatMap(d => {
        return [
          <tr key={d['users.user_name']}>
            <th colSpan={2}>
              {`${d['users.user_name']} - (${d['users.first_name']} ${d['users.last_name']})`}
            </th>
          </tr>,
          <tr key={d['users.user_name'] + '-deduction'}>
            <td>
              {I18n.t('grace_period_submission_rules.credit',
                      {count: d.deduction})}
            </td>
            <td>
              {!this.props.released_to_students &&
               <button
                 className='inline-button'
                 onClick={() => this.props.deleteGraceTokenDeduction(d.id)}
               >
                 {I18n.t('remove')}
               </button>
              }
            </td>
          </tr>
        ]
      });

      return (
        <div>
          <h3>{I18n.t('activerecord.models.grace_period_deduction.other')}</h3>
          <table>
            <tbody>
            {rows}
            </tbody>
          </table>
        </div>
      );
    }
  };

  render() {
    return (
      <div className={'marks-summary-pane'}>
        <ReactTable
          columns={this.criterionColumns()}
          data={this.props.criterionSummaryData} />
        <div className='mark_total'>
          {I18n.t('results.subtotal')}
          <span className='final_mark'>
            {this.props.subtotal}
            &nbsp;/&nbsp;
            {this.props.assignment_max_mark}
          </span>
        </div>
        {this.renderGraceTokenDeductions()}
        {this.renderExtraMarks()}
        {this.renderTotalMark()}
      </div>
    );
  }
}
