export const defaultSearchPlaceholderText = () => I18n.t("table.search");

export default function CaseSensitiveSearchFilter({column, filterValue, headerId}) {
  const inputId = `${headerId}-filter`;
  let caseSensitive = filterValue?.caseSensitive ?? false;
  return (
    <div style={{display: "flex", alignItems: "center", gap: "4px"}}>
      <input
        id={inputId}
        placeholder={defaultSearchPlaceholderText()}
        type="text"
        style={{flex: 1, minWidth: 0}}
        value={filterValue?.value ?? ""}
        // Named "Search" followed by the header cell's text, e.g. "Search Group"
        aria-label={I18n.t("search")}
        aria-labelledby={`${inputId} ${headerId}`}
        onChange={event => {
          column.setFilterValue({
            value: event.target.value,
            caseSensitive: filterValue?.caseSensitive ?? false,
          });
        }}
      />
      <label
        title={I18n.t("table.case_sensitive_search")}
        style={{display: "flex", alignItems: "center", cursor: "pointer"}}
      >
        <input
          type="checkbox"
          checked={caseSensitive}
          onChange={event => {
            column.setFilterValue({
              value: filterValue?.value ?? "",
              caseSensitive: event.target.checked,
            });
          }}
          aria-label={I18n.t("table.case_sensitive_search")}
          data-testid={`${column.id}_case_sensitive`}
        />
        <span style={{fontSize: "1.05em", marginLeft: "2px"}}>
          {I18n.t("table.case_sensitive_indicator")}
        </span>
      </label>
    </div>
  );
}
