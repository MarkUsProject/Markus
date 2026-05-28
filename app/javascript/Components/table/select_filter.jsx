import React from "react";

export default function SelectFilter({column, filterValue, facetedUniqueValues}) {
  const sortedUniqueValues = React.useMemo(() => {
    return Array.from(facetedUniqueValues.keys())
      .filter(value => value !== "")
      .sort();
  }, [facetedUniqueValues]);

  const totalRowCount = React.useMemo(() => {
    return [...(facetedUniqueValues.values() || [])].reduce((sum, count) => sum + count, 0);
  }, [facetedUniqueValues]);

  return (
    <select
      onChange={e => column.setFilterValue(e.target.value)}
      value={filterValue?.toString() || ""}
      style={{width: "100%"}}
    >
      <option value="">All ({totalRowCount})</option>
      {sortedUniqueValues.map(value => (
        <option value={value} key={value}>
          {value} ({facetedUniqueValues.get(value).toString()})
        </option>
      ))}
    </select>
  );
}
