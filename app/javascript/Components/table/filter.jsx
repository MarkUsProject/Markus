import React from "react";
import SearchFilter from "./search_filter";
import SelectFilter from "./select_filter";

export default function Filter({column}) {
  const {filterVariant} = column.columnDef.meta ?? {};

  return filterVariant === "select" ? (
    <SelectFilter column={column} />
  ) : (
    <SearchFilter column={column} />
  );
}
