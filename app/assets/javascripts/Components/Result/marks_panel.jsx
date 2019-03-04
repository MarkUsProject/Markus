import React from 'react';
import { render } from 'react-dom';


export class MarksPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: new Set(),
    }
  }

  componentDidMount() {
    if (!this.props.released_to_students) {
      // TODO: Convert this to pure React
      // Capture the mouse event to add "active-criterion" to the clicked element
      $(document).on('click', '.rubric_criterion, .flexible_criterion, .checkbox_criterion', (e) => {
        if (!$(this).hasClass('unassigned')) {
          e.preventDefault();
          activeCriterion($(this));
        }
      });
    }

    // Expand by default if:
    //   1) The result has been released, or
    //   2) A mark has not yet been given, and the current user can give the mark.
    let expanded = new Set();
    this.props.marks.forEach(data => {
      const key = `${data.criterion_type}-${data.id}`;
      if ((data.mark === null || data.mark === undefined) &&
          (this.props.assigned_criteria === null || this.props.assigned_criteria.includes(key))) {
        expanded.add(key);
      }
    });
  }

  expandAll = (onlyUnmarked) => {
    let expanded = new Set();
    this.props.marks.forEach(markData => {
      if (!onlyUnmarked || markData.mark === null || markData.mark === undefined) {
        expanded.add(`${markData.criterion_type}-${markData.id}`);
      }
    });
    this.setState({ expanded });
  };

  collapseAll = () => {
    this.setState({ expanded: new Set() });
  };

  toggleExpanded = (key) => {
    if (this.state.expanded.has(key)) {
      this.state.expanded.delete(key);
    } else {
      this.state.expanded.add(key);
    }
    this.setState({ expanded: this.state.expanded })
  };

  updateMark = (criterion_type, criterion_id, mark) => {
    let result = this.props.updateMark(criterion_type, criterion_id, mark);
    if (result !== undefined) {
      result.then(() => {
        this.state.expanded.delete(`${criterion_type}-${criterion_id}`);
        this.setState({ expanded: this.state.expanded });
      })
    }
  };

  renderMarkComponent = (markData) => {
    const key = `${markData.criterion_type}-${markData.id}`;
    const unassigned = this.props.assigned_criteria !== null && !this.props.assigned_criteria.includes(key);

    const props = {
      key: key,
      released_to_students: this.props.released_to_students,
      unassigned: unassigned,
      updateMark: this.updateMark,
      expanded: this.state.expanded.has(key),
      oldMark: this.props.old_marks[`criterion_${markData.criterion_type}_${markData.id}`],
      toggleExpanded: () => this.toggleExpanded(key),
      ... markData
    };
    if (markData.criterion_type === 'CheckboxCriterion') {
      return <CheckboxCriterionInput {... props} />;
    } else if (markData.criterion_type === 'FlexibleCriterion') {
      return <FlexibleCriterionInput {... props} />;
    } else if (markData.criterion_type === 'RubricCriterion') {
      return <RubricCriterionInput {... props} />;
    } else {
      return null;
    }
  };

  render() {
    const markComponents = this.props.marks.map(this.renderMarkComponent);

    return (
      <div id='mark_viewer' className='flex-col'>
        {!this.props.released_to_students &&
         <div className='mark_tools'>
           <button className='inline-button' onClick={() => this.expandAll()}>
             {I18n.t('results.expand_all')}
           </button>
           <button className='inline-button' onClick={() => this.expandAll(true)}>
             {I18n.t('results.expand_unmarked')}
           </button>
           <button className='inline-button' onClick={() => this.collapseAll()}>
             {I18n.t('results.collapse_all')}
           </button>
         </div>
        }
        <div id='mark_criteria'>
          <ul className='marks-list'>
            {markComponents}
          </ul>
        </div>
      </div>
    );
  }
}


class CheckboxCriterionInput extends React.Component {
  constructor(props) {
    super(props);
  }

  handleChange = (event) => {
    if (event.target.value === 'yes') {
      this.props.updateMark(this.props.criterion_type, this.props.id, this.props.max_mark);
    } else {
      this.props.updateMark(this.props.criterion_type, this.props.id, 0);
    }
  };

  render() {
    const unassignedClass = this.props.unassigned ? 'unassigned' : '';
    const expandedClass = this.props.expanded ? 'expanded' : 'collapsed';
    return (
      <li id={`checkbox_criterion_${this.props.id}`}
          className={`checkbox_criterion ${expandedClass} ${unassignedClass}`}>
        <div data-id={this.props.id}>
          <div className='criterion-name'
               onClick={this.props.toggleExpanded}
          >
            <div className={this.props.expanded ? 'arrow-up' : 'arrow-down'}
                 style={{float: 'left'}}
            />
            {this.props.name}
          </div>
          <div>
            {!this.props.released_to_students &&
             <span className='checkbox-criterion-inputs'>
              <label>
                <input
                  type='radio'
                  value='yes'
                  onChange={this.handleChange}
                  checked={this.props.mark === this.props.max_mark}
                  disabled={this.props.released_to_students || this.props.unassigned}
                />
                {I18n.t('answer_yes')}
              </label>
              <label>
              <input
                type='radio'
                value='no'
                onChange={this.handleChange}
                checked={this.props.mark === 0}
                disabled={this.props.released_to_students || this.props.unassigned}
              />
                {I18n.t('answer_no')}
              </label>
            </span>
            }
            <span className='mark'>
              {this.props.mark === null ? '-' : this.props.mark}
              &nbsp;/&nbsp;
              {this.props.max_mark}
            </span>
          </div>
          {this.props.oldMark !== undefined &&
           <div className='old-mark'>
             {`(${I18n.t('results.remark.old_mark')}: ${this.props.oldMark})`}
           </div>
          }
          <div className='criterion-description'>
            {this.props.description}
          </div>
        </div>
      </li>
    );
  }
}


class FlexibleCriterionInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      rawText: this.props.mark === null ? '' : String(this.props.mark)
    };
  }

  handleChange = (event) => {
    const mark = parseFloat(event.target.value);
    if (isNaN(mark)) {
      return;
    } else if (mark === this.props.mark) {
      // This can happen if the user types a decimal point at the end of the input.
      this.setState({rawText: event.target.value})
    } else {
      this.props.updateMark(
        this.props.criterion_type, this.props.id, mark
      );
    }
  };

  componentDidUpdate(oldProps) {
    if (oldProps.mark !== this.props.mark) {
      this.setState({ rawText: String(this.props.mark) })
    }
  }

  render() {
    const unassignedClass = this.props.unassigned ? 'unassigned' : '';
    const expandedClass = this.props.expanded ? 'expanded' : 'collapsed';

    let markElement;
    if (this.props.released_to_students) { // Student view
      markElement = this.props.mark;
    } else {
      markElement = (
        <input
          type='text'
          size={4}
          value={this.state.rawText}
          onChange={this.handleChange}
          disabled={this.props.unassigned}
        />
      );
    }

    return (
      <li id={`flexible_criterion_${this.props.id}`}
          className={`flexible_criterion ${expandedClass} ${unassignedClass}`}>
        <div data-id={this.props.id}>
          <div className='criterion-name'
               onClick={this.props.toggleExpanded}
          >
            <div className={this.props.expanded ? 'arrow-up' : 'arrow-down'}
                 style={{float: 'left'}}
            />
            {this.props.name}
          </div>
          <div className='criterion-description'>
            {this.props.description}
          </div>
          <span className='mark'>
            {markElement}
            &nbsp;/&nbsp;
            {this.props.max_mark}
          </span>
          {this.props.oldMark !== undefined &&
           <div className='old-mark'>
             {`(${I18n.t('results.remark.old_mark')}: ${this.props.oldMark})`}
           </div>
          }
        </div>
      </li>
    );
  }
}


class RubricCriterionInput extends React.Component {
  constructor(props) {
    super(props);
  }

  // The parameter `level` is the level number selected.
  handleChange = (level) => {
    this.props.updateMark(
      this.props.criterion_type, this.props.id, level * this.props.max_mark / 4
    );
  };

  renderRubricLevel = (i) => {
    const levelMark = (i * this.props.max_mark / 4).toFixed(2);
    let selectedClass = '';
    let oldMarkClass = '';
    if (this.props.mark !== undefined &&
        this.props.mark !== null &&
        levelMark === this.props.mark.toFixed(2)) {
      selectedClass = 'selected'
    }
    if (this.props.oldMark !== undefined &&
        this.props.oldMark !== null &&
        levelMark === this.props.oldMark.toFixed(2)) {
      oldMarkClass = 'old-mark';
    }

    return (
      <tr
        data-level-index={i} onClick={() => this.handleChange(i)}
        key={`${this.props.id}-${i}`}
        className={`rubric-level ${selectedClass} ${oldMarkClass}`}
      >
        <td className='level-description'>
          <strong>{this.props[`level_${i}_name`]}</strong>&nbsp;
          {this.props[`level_${i}_description`]}
        </td>
        <td className={'mark'}>
          {(i * this.props.max_mark / 4).toFixed(2)}
          &nbsp;/&nbsp;
          {this.props.max_mark}
        </td>
      </tr>
    );
  };

  render() {
    const levels = [0, 1, 2, 3, 4].map(this.renderRubricLevel);
    const expandedClass = this.props.expanded ? 'expanded' : 'collapsed';
    const unassignedClass = this.props.unassigned ? 'unassigned' : '';
    return (
      <li id={`rubric_criterion_${this.props.id}`}
          className={`rubric_criterion ${expandedClass} ${unassignedClass}`}>
        <div data-id={this.props.id}>
          <div className='criterion-name'
               onClick={this.props.toggleExpanded}
          >
            <div className={this.props.expanded ? 'arrow-up' : 'arrow-down'}
                 style={{float: 'left'}}
            />
            {this.props.name}
          </div>
          <table className='rubric-levels'>
            <tbody>
              {levels}
            </tbody>
          </table>
        </div>
      </li>
    );
  }
}
