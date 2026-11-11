import React from "react";
import {getTemplate, getUiOptions} from "@rjsf/utils";
import {getDefaultRegistry} from "@rjsf/core";

// The ai tester's config fields, in display order. Required fields come first.
// `hint: false` skips the help line for fields whose label says enough.
// `options` lists the stored values that get plain names. `choose` adds a "Choose one" prompt.
const AI_CONFIG_FIELDS = [
  {name: "scope", choose: true, options: ["code", "text", "image"]},
  {name: "submission"},
  {name: "model", options: ["remote", "openai-remote"]},
  {name: "model_name"},
  {name: "remote_url", hint: false, choose: true},
  {name: "prompt"},
  {name: "prompt_text", widget: "textarea", hint: false},
  {name: "question"},
  {name: "system_prompt", advanced: true},
  {name: "solution", advanced: true},
  {name: "solution_image", advanced: true, hint: false},
  {name: "test_output", advanced: true, hint: false},
  {name: "submission_type", advanced: true},
  {name: "submission_image", advanced: true, hint: false},
  {name: "output", advanced: true},
  {name: "output_template", advanced: true},
  {name: "json_schema", advanced: true},
  {name: "llama_mode", advanced: true, choose: true},
];

/** Returns the uiSchema for the ai tester's `config` object: field order, labels, help text and widgets. */
export function aiConfigUiSchema() {
  const fields = AI_CONFIG_FIELDS.map(({name, widget, advanced, choose, options, hint = true}) => [
    name,
    {
      "ui:title": I18n.t(`automated_tests.ai_config.${name}.title`),
      ...(hint && {"ui:description": I18n.t(`automated_tests.ai_config.${name}.description`)}),
      ...(widget && {"ui:widget": widget}),
      ...(advanced && {"ui:options": {advanced: true}}),
      ...(choose && {"ui:placeholder": I18n.t("automated_tests.choose_one")}),
      ...(options && {
        "ui:enumNames": Object.fromEntries(
          options.map(value => [
            value,
            I18n.t(`automated_tests.ai_config.${name}.options.${value}`),
          ])
        ),
      }),
    },
  ]);
  return {
    "ui:classNames": "tester-config",
    "ui:title": I18n.t("automated_tests.ai_config.title"),
    "ui:order": [...AI_CONFIG_FIELDS.map(field => field.name), "*"],
    ...Object.fromEntries(fields),
  };
}

/** Plain names for the values MarkUs and the autotester store, keyed by value. */
export function testerTypeNames() {
  return {
    ai: I18n.t("automated_tests.tester_types.ai"),
    custom: I18n.t("automated_tests.tester_types.custom"),
    haskell: I18n.t("automated_tests.tester_types.haskell"),
    java: I18n.t("automated_tests.tester_types.java"),
    js: I18n.t("automated_tests.tester_types.js"),
    jupyter: I18n.t("automated_tests.tester_types.jupyter"),
    py: I18n.t("automated_tests.tester_types.py"),
    pyta: I18n.t("automated_tests.tester_types.pyta"),
    r: I18n.t("automated_tests.tester_types.r"),
    racket: I18n.t("automated_tests.tester_types.racket"),
  };
}

/** Renders an object or array title as a plain heading. Stars stay on fields. */
export function TitleFieldTemplate({id, title, optionalDataControl}) {
  return (
    <legend id={id}>
      {title}
      {optionalDataControl}
    </legend>
  );
}

const isAdvanced = (uiSchema, name) => !!getUiOptions(uiSchema?.[name]).advanced;

const hasValue = value =>
  value !== undefined && value !== null && value !== "" && !(Array.isArray(value) && !value.length);

// Looked up on first use, so tests that mock @rjsf/core can still import this file.
let defaultTemplates;
const getDefaultTemplate = name => (defaultTemplates ??= getDefaultRegistry().templates)[name];

/**
 * Renders an object like the default template, but moves properties marked
 * `"ui:options": {advanced: true}` into a section that opens with a toggle.
 * The section starts open when one of its fields holds a value. An error in
 * one of its fields opens it, and it stays open after the error clears.
 */
export function ObjectFieldTemplate(props) {
  const {properties, uiSchema, formData, errorSchema} = props;
  const advanced = properties.filter(prop => isAdvanced(uiSchema, prop.name));
  const hasError = advanced.some(prop => errorSchema?.[prop.name]);
  const [open, setOpen] = React.useState(() =>
    advanced.some(prop => hasValue(formData?.[prop.name]))
  );
  const DefaultTemplate = getDefaultTemplate("ObjectFieldTemplate");

  if (hasError && !open) {
    setOpen(true);
  }
  if (!advanced.length) {
    return <DefaultTemplate {...props} />;
  }

  const basic = properties.filter(prop => !isAdvanced(uiSchema, prop.name));
  const section = {
    name: "__advanced",
    content: (
      <div className="advanced-settings" key="__advanced">
        <button
          type="button"
          className="inline-button"
          disabled={hasError}
          onClick={() => setOpen(!open)}
        >
          {open
            ? I18n.t("automated_tests.hide_advanced_settings")
            : I18n.t("automated_tests.show_advanced_settings")}
        </button>
        {open && advanced.map(prop => prop.content)}
      </div>
    ),
  };
  return <DefaultTemplate {...props} properties={[...basic, section]} />;
}

/**
 * Renders one item of an array, like a tester or a test group, as a card.
 * The header holds a numbered title ("Test Group 2") and the item's buttons.
 */
export function CardItemTemplate(props) {
  const {children, buttonsProps, hasToolbar, index, registry, uiSchema} = props;
  const ItemButtons = getTemplate(
    "ArrayFieldItemButtonsTemplate",
    registry,
    getUiOptions(uiSchema)
  );
  const titleId = `${buttonsProps.fieldPathId.$id}__card_title`;

  return (
    <section className="settings-card" aria-labelledby={titleId}>
      <header className="settings-card-header">
        <h3 className="settings-card-title" id={titleId}>
          {`${uiSchema?.["ui:title"] ?? ""} ${index + 1}`.trim()}
        </h3>
        {hasToolbar && (
          <div className="settings-card-actions">
            <ItemButtons {...buttonsProps} />
          </div>
        )}
      </header>
      <div className="settings-card-body">{children}</div>
    </section>
  );
}

/**
 * Renders a field like the default template, and adds "(optional)" after the
 * label of each field that is not required.
 */
export function FieldTemplate(props) {
  const {id, label, children, errors, help, description, hidden, required, displayLabel} = props;
  const {registry, uiSchema} = props;
  const uiOptions = getUiOptions(uiSchema);
  const WrapIfAdditionalTemplate = getTemplate("WrapIfAdditionalTemplate", registry, uiOptions);

  if (hidden) {
    return <div className="hidden">{children}</div>;
  }
  const showLabel = displayLabel && uiOptions.widget !== "checkbox" && !!label;
  return (
    <WrapIfAdditionalTemplate {...props}>
      {showLabel && (
        <label className="control-label" htmlFor={id}>
          {label}
          {required ? (
            <span className="required">*</span>
          ) : (
            <span className="optional-label">{I18n.t("automated_tests.optional")}</span>
          )}
        </label>
      )}
      {displayLabel && description ? description : null}
      {children}
      {errors}
      {help}
    </WrapIfAdditionalTemplate>
  );
}
