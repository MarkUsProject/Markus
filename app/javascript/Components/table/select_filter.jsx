import React from "react";

export default function SelectFilter({column}) {
  const uniqueValuesMap = column.getFacetedUniqueValues();

  const sortedUniqueValues = React.useMemo(() => {
    return Array.from(uniqueValuesMap.keys())
      .filter(value => value !== "")
      .sort();
  }, [uniqueValuesMap]);

  const totalRowCount = React.useMemo(() => {
    return [...uniqueValuesMap.values()].reduce((sum, count) => sum + count, 0);
  }, [uniqueValuesMap]);

  return (
    <select
      onChange={e => column.setFilterValue(e.target.value)}
      value={column.getFilterValue()?.toString() || ""}
      style={{width: "100%"}}
    >
      <option value="">All ({totalRowCount})</option>
      {sortedUniqueValues.map(value => (
        <option value={value} key={value}>
          {value} ({uniqueValuesMap.get(value).toString()})
        </option>
      ))}
    </select>
  );
}
