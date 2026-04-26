import React from "react";
import SearchFilter from "./search_filter";
import SelectFilter from "./select_filter";

function Filter({column, filterValue, facetedUniqueValues}) {
  const {filterVariant} = column.columnDef.meta ?? {};

  return filterVariant === "select" ? (
    <SelectFilter
      column={column}
      filterValue={filterValue}
      facetedUniqueValues={facetedUniqueValues}
    />
  ) : (
    <SearchFilter column={column} filterValue={filterValue} />
  );
}

function FilterCell({size, column, filterValue, facetedUniqueValues}) {
  return (
    <div
      className={`rt-th ${column.columnDef.meta?.headerClassName || ""}`}
      role="columnheader"
      tabIndex="-1"
      style={{
        width: size,
        maxWidth: column.columnDef.maxSize || "none",
      }}
    >
      {column.getCanFilter() && (
        <Filter
          column={column}
          filterValue={filterValue}
          facetedUniqueValues={facetedUniqueValues}
        />
      )}
    </div>
  );
}

export default React.memo(FilterCell);
