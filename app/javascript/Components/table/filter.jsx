import React from "react";
import SearchFilter from "./search_filter";
import SelectFilter from "./select_filter";
import CaseSensitiveSearchFilter from "./case_sensitive_search_filter";

function Filter({column, filterValue, facetedUniqueValues}) {
  const {filterVariant} = column.columnDef.meta ?? {};
  if (filterVariant === "select") {
    return (
      <SelectFilter
        column={column}
        filterValue={filterValue}
        facetedUniqueValues={facetedUniqueValues}
      />
    );
  } else if (filterVariant === "case-sensitive-text") {
    return <CaseSensitiveSearchFilter column={column} filterValue={filterValue} />;
  } else {
    return <SearchFilter column={column} filterValue={filterValue} />;
  }
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
