import React from 'react';
import { render } from 'react-dom';
import ReactTable from 'react-table';


export class SummaryPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      old_marks: {},
      marks: [],
      released: true,
      remark_submitted: false,
      assignment_max_mark: 0,
      old_total: 0,
      total: 0,
      subtotal: 0,
      extraMarkSubtotal: 0,
      extraMarks: [],
      criterionSummaryData: [],
      showNewExtraMark: false,
      graceTokenDeductions: [],
      is_reviewer: false
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id)
    }).then(res => {
      let released = res.released_to_students;
      let remark_submitted = res.remark_submitted;
      let old_marks = res.old_marks;
      let marks = res.marks;
      let extraMarks = res.extra_marks;
      let criterionSummaryData = [];
      let subtotal = 0;
      let extraMarkSubtotal = 0;
      marks.forEach(data => {
        data.max_mark = parseFloat(data.max_mark);
        data.mark = data['marks.mark'];
        criterionSummaryData.push({
          criterion: data.name,
          mark: data.mark,
          old_mark: old_marks[`criterion_${data.criterion_type}_${data.id}`],
          max_mark: data.max_mark
        });
        subtotal += data.mark || 0;
      });
      extraMarks.forEach(data => {
        if (data.unit === 'points') {
          extraMarkSubtotal += data.extra_mark;
        } else { // Percentage
          extraMarkSubtotal += data.extra_mark * res.assignment_max_mark / 100;
        }
      });
      this.setState({
        marks, released, old_marks,
        remark_submitted,
        criterionSummaryData,
        subtotal,
        extraMarkSubtotal,
        extraMarks,
        total: res.total,
        old_total: res.old_total,
        assignment_max_mark: res.assignment_max_mark,
        showNewExtraMark: false,
        graceTokenDeductions: res.grace_token_deductions,
        is_reviewer: res.is_reviewer
      });
    });
  };

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
      show: this.state.remark_submitted
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
    if (this.state.remark_submitted) {
      oldTotal = (
        <div className='mark_total'>
          <span>
            {I18n.t('results.remark.old_total')}
          </span>
          <span className='final_mark'>
            <span>{this.state.old_total}</span>
            &nbsp;/&nbsp;
            {this.state.assignment_max_mark}
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
          <span>{this.state.total}</span>
          &nbsp;/&nbsp;
          {this.state.assignment_max_mark}
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
          let mark_value = (row.value * this.state.assignment_max_mark / 100).toFixed(2);
          return `${mark_value} (${row.value}%)`;
        }
      }
    },
    {
      Header: '',
      id: 'action',
      show: !this.state.released,
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
              onClick={() => this.destroyExtraMark(row.original.id)}
              className='inline-button'>
              {I18n.t('remove')}
            </button>
          );
        }
      }
    }
  ];

  destroyExtraMark = (id) => {
    if (!confirm(I18n.t('results.delete_extra_mark_confirm'))) {
      return;
    }

    $.ajax({
      url: Routes.remove_extra_mark_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id,
        // TODO: Fix this route so that the id refers to a Result rather than ExtraMark.
        id
      ),
      method: 'POST',
    }).then(() => {
      // TODO: Optimize this so not everything is fetched again.
      this.fetchData();
    })
  };

  newExtraMark = () => {
    this.setState({showNewExtraMark: true});
  };

  createExtraMark = (event) => {
    let row = event.target.parentElement.parentElement;
    let description = row.children[0].children[0].value;
    let extra_mark = row.children[1].children[0].value;
    $.ajax({
      url: Routes.add_extra_mark_assignment_result_path(
        this.props.assignment_id, this.props.result_id
      ),
      method: 'POST',
      data: {
        extra_mark: {
          description: description,
          extra_mark: extra_mark
        }
      }
    }).then(() => {
      this.fetchData()
    })
  };

  renderExtraMarks = () => {
    // If there are no extra marks and this result is released, display nothing.
    if (this.state.is_reviewer ||
        (this.state.released && this.state.extraMarks.length === 0)) {
      return '';
    }

    let data;
    if (this.state.showNewExtraMark) {
      data = this.state.extraMarks.concat([
        {
          _new: true,
          extra_mark: 0,
          description: '',
          id: null
        }
      ]);
    } else {
      data = this.state.extraMarks;
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
        {!this.state.released &&
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
            {this.state.extraMarkSubtotal.toFixed(2)}
          </span>
        </div>
      </div>
    );
  };

  renderGraceTokenDeductions = () => {
    if (this.state.graceTokenDeductions.length === 0) {
      return '';
    } else {
      let rows = this.state.graceTokenDeductions.flatMap(d => {
        return [
          <tr>
            <th colSpan={2}>
              {`${d['users.user_name']} - (${d['users.first_name']} ${d['users.last_name']})`}
            </th>
          </tr>,
          <tr>
            <td>
              {I18n.t('grace_period_submission_rules.credit',
                      {count: d.deduction})}
            </td>
            <td>
              {!this.state.released &&
               <button
                 className='inline-button'
                 onClick={() => this.deleteGraceTokenDeduction(d.id)}
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

  deleteGraceTokenDeduction = (id) => {
    if (!confirm(I18n.t('grace_period_submission_rules.confirm_remove_deduction'))) {
      return;
    }

    $.ajax({
      url: Routes.delete_grace_period_deduction_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      method: 'POST',
      data: {deduction_id: id}
    }).then(this.fetchData)
  };

  render() {
    return (
      <div>
        <ReactTable
          columns={this.criterionColumns()}
          data={this.state.criterionSummaryData} />
        <div className='mark_total'>
          {I18n.t('results.subtotal')}
          <span className='final_mark'>
            {this.state.subtotal}
            &nbsp;/&nbsp;
            {this.state.assignment_max_mark}
          </span>
        </div>
        {this.renderGraceTokenDeductions()}
        {this.renderExtraMarks()}
        {this.renderTotalMark()}
      </div>
    );
  }
}


export function makeSummaryPanel(elem, props) {
  return render(<SummaryPanel {...props} />, elem);
}
