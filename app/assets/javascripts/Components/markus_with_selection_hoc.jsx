/* Wrapper around react-table's CheckboxTable component.
 */
import React from "react";

import ReactTable from "react-table";
import checkboxHOC from "react-table/lib/hoc/selectTable";

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
        last_selected: null,
      };
    }

    // From https://react-table.js.org/#/story/select-table-hoc.
    toggleSelection(key, shift, row) {
      // Input key is of the form `select-${id_}`.
      key = parseInt(key.slice(key.indexOf("-") + 1), 10);
      if (isNaN(key)) {
        return;
      }
      let selection = [...this.state.selection];
      let last_selected = null;
      if (shift && this.state.last_selected !== null && this.state.last_selected !== key) {
        // we need to get at the internals of ReactTable
        const wrappedInstance = this.wrapped.checkboxTable.getWrappedInstance();
        // the 'sortedData' property contains the currently accessible records based on the filter and sort
        const currentRecords = wrappedInstance.getResolvedState().sortedData;
        // find all keys between the last key selected and the current key selected
        const keys_in_range = new Set();
        currentRecords.some(record => {
          if (record._id === this.state.last_selected || record._id === key) {
            keys_in_range.add(record._id);
            if (keys_in_range.size > 1) {
              return true; // acts like a break statement
            }
          } else if (!!keys_in_range.size) {
            keys_in_range.add(record._id);
          }
          return false;
        });
        if (selection.indexOf(this.state.last_selected) < 0) {
          // if the last key selected unchecked the checkbox: remove all keys in range from the selection array
          selection = [...new Set(selection.filter(x => !keys_in_range.has(x)))];
        } else {
          // otherwise add all keys in range to the selection array
          selection = [...new Set([...selection, ...keys_in_range])];
        }
      } else {
        const keyIndex = selection.indexOf(key);
        if (keyIndex >= 0) {
          selection.splice(keyIndex, 1);
        } else {
          selection.push(key);
        }
        last_selected = key;
      }
      // update the state
      this.setState({selection, last_selected});
    }

    toggleAll() {
      const selectAll = !this.state.selectAll;
      const selection = [];
      const last_selected = null;
      if (selectAll) {
        // we need to get at the internals of ReactTable
        const wrappedInstance = this.wrapped.checkboxTable.getWrappedInstance();
        // the 'sortedData' property contains the currently accessible records based on the filter and sort
        const currentRecords = wrappedInstance.getResolvedState().sortedData;
        // we just push all the IDs onto the selection array
        currentRecords.forEach(item => {
          selection.push(item._original._id);
        });
      }
      this.setState({selectAll, selection, last_selected});
    }

    isSelected(key) {
      return this.state.selection.includes(key);
    }

    resetSelection() {
      this.setState({selectAll: false, selection: [], last_selected: null});
    }

    getCheckboxProps() {
      return {
        isSelected: this.isSelected,
        toggleSelection: this.toggleSelection,
        toggleAll: this.toggleAll,
        selectAll: this.state.selectAll,
        selectType: "checkbox",
      };
    }

    render() {
      return (
        <WrappedComponent
          ref={r => (this.wrapped = r)}
          resetSelection={this.resetSelection}
          getCheckboxProps={this.getCheckboxProps}
          selectAll={this.state.selectAll}
          selection={this.state.selection}
          {...this.props}
        />
      );
    }
  };
}

export const CheckboxTable = checkboxHOC(ReactTable);

export {withSelection};
