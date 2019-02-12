/* Wrapper around react-table's CheckboxTable component.
 */
import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import checkboxHOC from 'react-table/lib/hoc/selectTable';


function withSelection(WrappedComponent) {
  return class extends React.Component {
    constructor(props) {
      super(props);
      this.toggleSelection = this.toggleSelection.bind(this);
      this.toggleAll = this.toggleAll.bind(this);
      this.isSelected = this.isSelected.bind(this);
      this.resetSelection = this.resetSelection.bind(this);
      this.getCheckboxProps = this.getCheckboxProps.bind(this);
      this.state = {
        selection: [],
        selectAll: false,
      }
    }

    // From https://react-table.js.org/#/story/select-table-hoc.
    toggleSelection(key, shift, row) {
      // Input key is of the form `select-${id_}`.
      key = parseInt(key.slice(key.indexOf('-') + 1), 10);
      if (isNaN(key)) {
        return;
      }
      let selection = [
        ...this.state.selection
      ];
      const keyIndex = selection.indexOf(key);
      if (keyIndex >= 0) {
        selection.splice(keyIndex, 1);
      } else {
        selection.push(key);
      }
      // update the state
      this.setState({ selection });
    }

    toggleAll() {
      const selectAll = !this.state.selectAll;
      const selection = [];
      if (selectAll) {
        // we need to get at the internals of ReactTable
        const wrappedInstance = this.wrapped.checkboxTable.getWrappedInstance();
        // the 'sortedData' property contains the currently accessible records based on the filter and sort
        const currentRecords = wrappedInstance.getResolvedState().sortedData;
        // we just push all the IDs onto the selection array
        currentRecords.forEach((item) => {
          selection.push(item._original._id);
        })
      }
      this.setState({ selectAll, selection });
    }

    isSelected(key) {
      return this.state.selection.includes(key);
    }

    resetSelection() {
      this.setState({selectAll: false, selection: []});
    }

    getCheckboxProps() {
      return {
        isSelected: this.isSelected,
        toggleSelection: this.toggleSelection,
        toggleAll: this.toggleAll,
        selectAll: this.state.selectAll,
        selectType: 'checkbox',
      };
    }

    render() {
      return (
        <WrappedComponent
          ref={(r) => this.wrapped = r}

          resetSelection={this.resetSelection}
          getCheckboxProps={this.getCheckboxProps}
          selectAll={this.state.selectAll}
          selection={this.state.selection}
          {...this.props}
        />
      );
    }
  }
}


export const CheckboxTable = checkboxHOC(ReactTable);

export {
  withSelection
};
