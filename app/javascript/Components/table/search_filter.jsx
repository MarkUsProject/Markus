export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function SearchFilter({column, filterValue, headerId}) {
  const inputId = `${headerId}-filter`;
  return (
    <input
      id={inputId}
      placeholder={defaultSearchPlaceholderText()}
      type="text"
      onChange={e => column.setFilterValue(e.target.value)}
      value={filterValue?.toString() || ""}
      style={{width: "100%"}}
      // Named "Search" followed by the header cell's text, e.g. "Search User Name"
      aria-label={defaultSearchPlaceholderText()}
      aria-labelledby={`${inputId} ${headerId}`}
    />
  );
}
