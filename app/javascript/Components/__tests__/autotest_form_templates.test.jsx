import React from "react";
import {render, screen, fireEvent} from "@testing-library/react";
import Form from "@rjsf/core";
import validator from "@rjsf/validator-ajv8";
import {
  aiConfigUiSchema,
  CardItemTemplate,
  FieldTemplate,
  ObjectFieldTemplate,
  testerTypeNames,
  TitleFieldTemplate,
} from "../Helpers/autotest_form_templates";

const templates = {FieldTemplate, ObjectFieldTemplate};

const schema = {
  type: "object",
  required: ["scope"],
  properties: {
    scope: {type: "string", title: "Scope"},
    model_name: {type: "string", title: "Model name"},
    llama_mode: {type: "string", title: "Llama mode"},
  },
};
const uiSchema = {llama_mode: {"ui:options": {advanced: true}}};

const form = (props = {}) => (
  <Form schema={schema} uiSchema={uiSchema} validator={validator} templates={templates} {...props}>
    <p />
  </Form>
);

const renderForm = props => render(form(props));

const toggleLabel = key => I18n.t(`automated_tests.${key}_advanced_settings`);

describe("ObjectFieldTemplate", () => {
  it("hides advanced fields until the toggle opens them", () => {
    renderForm();
    expect(screen.queryByLabelText(/Llama mode/)).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", {name: toggleLabel("show")}));

    expect(screen.getByLabelText(/Llama mode/)).toBeInTheDocument();
    expect(screen.getByRole("button", {name: toggleLabel("hide")})).toBeInTheDocument();
  });

  it("renders no toggle when no field is advanced", () => {
    renderForm({uiSchema: {}});
    expect(screen.queryByRole("button", {name: toggleLabel("show")})).not.toBeInTheDocument();
    expect(screen.getByLabelText(/Llama mode/)).toBeInTheDocument();
  });

  it("starts open when an advanced field holds a saved value", () => {
    renderForm({formData: {scope: "code", llama_mode: "cli"}});
    expect(screen.getByLabelText(/Llama mode/)).toHaveValue("cli");
  });

  it("starts open when an advanced field has an error", () => {
    renderForm({extraErrors: {llama_mode: {__errors: ["bad mode"]}}});
    expect(screen.getByLabelText(/Llama mode/)).toBeInTheDocument();
  });

  it("opens when an advanced field gets an error after the form loads", () => {
    const {rerender} = renderForm();
    expect(screen.queryByLabelText(/Llama mode/)).not.toBeInTheDocument();

    rerender(form({extraErrors: {llama_mode: {__errors: ["bad mode"]}}}));

    expect(screen.getByLabelText(/Llama mode/)).toBeInTheDocument();
    expect(screen.getByText("bad mode")).toBeInTheDocument();
  });

  it("stays open after the user fixes an error in an advanced field", () => {
    const {container} = renderForm({
      schema: {...schema, required: ["scope", "llama_mode"]},
      formData: {scope: "code"},
    });
    const formElement = container.querySelector("form");
    const logged = jest.spyOn(console, "error").mockImplementation(() => {}); // rjsf logs the failed validation
    fireEvent.submit(formElement);
    logged.mockRestore();
    fireEvent.change(screen.getByLabelText(/Llama mode/), {target: {value: "server"}});
    fireEvent.submit(formElement);

    expect(screen.getByLabelText(/Llama mode/)).toHaveValue("server");
  });

  it("keeps an advanced value in the form data after the section closes", () => {
    const onChange = jest.fn();
    renderForm({onChange});
    fireEvent.click(screen.getByRole("button", {name: toggleLabel("show")}));
    fireEvent.change(screen.getByLabelText(/Llama mode/), {target: {value: "server"}});
    fireEvent.click(screen.getByRole("button", {name: toggleLabel("hide")}));

    expect(onChange.mock.calls.at(-1)[0].formData.llama_mode).toBe("server");
  });
});

describe("FieldTemplate", () => {
  const optional = I18n.t("automated_tests.optional");

  it("marks optional fields and stars required ones", () => {
    const {container} = renderForm();
    const scopeLabel = container.querySelector("label[for='root_scope']");
    const modelLabel = container.querySelector("label[for='root_model_name']");

    expect(scopeLabel).toHaveTextContent("Scope*");
    expect(scopeLabel).not.toHaveTextContent(optional);
    expect(modelLabel).toHaveTextContent(`Model name${optional}`);
  });

  it("adds the optional mark after a JSX title", () => {
    const {container} = renderForm({
      uiSchema: {model_name: {"ui:title": <span className="jsx-title">Custom</span>}},
    });
    const label = container.querySelector("label[for='root_model_name']");

    expect(label.querySelector(".jsx-title")).toHaveTextContent("Custom");
    expect(label).toHaveTextContent(`Custom${optional}`);
    expect(label).not.toHaveTextContent("[object Object]");
  });

  it("skips the mark on hidden fields and checkboxes", () => {
    const {container} = renderForm({
      schema: {
        type: "object",
        properties: {
          secret: {type: "string"},
          enabled: {type: "boolean", title: "Enabled"},
        },
      },
      uiSchema: {secret: {"ui:widget": "hidden"}},
    });

    expect(container.querySelectorAll(".optional-label")).toHaveLength(0);
    expect(screen.getByLabelText("Enabled")).toBeInTheDocument();
  });

  it("keeps ui:classNames on the field wrapper", () => {
    const {container} = renderForm({uiSchema: {scope: {"ui:classNames": "tester-item"}}});
    expect(container.querySelector(".tester-item #root_scope")).toBeInTheDocument();
  });

  it("renders one named checkbox per role for a referenced enum", () => {
    renderForm({
      schema: {
        type: "object",
        definitions: {test_data_categories: {type: "string", enum: ["instructor", "student"]}},
        properties: {
          category: {
            type: "array",
            title: "Run by",
            uniqueItems: true,
            items: {$ref: "#/definitions/test_data_categories"},
          },
        },
      },
      uiSchema: {
        category: {
          "ui:widget": "checkboxes",
          items: {"ui:enumNames": {instructor: "Instructors", student: "Students"}},
        },
      },
    });

    expect(screen.getAllByRole("checkbox")).toHaveLength(2);
    expect(screen.getByLabelText("Instructors")).toBeInTheDocument();
    expect(screen.getByLabelText("Students")).toBeInTheDocument();
  });
});

describe("aiConfigUiSchema", () => {
  const aiSchema = {
    type: "object",
    required: ["scope", "submission", "model"],
    properties: Object.fromEntries(
      [
        "json_schema",
        "llama_mode",
        "model",
        "model_name",
        "prompt_text",
        "scope",
        "submission",
      ].map(name => [name, {type: "string"}])
    ),
  };

  const renderAiForm = () => renderForm({schema: aiSchema, uiSchema: aiConfigUiSchema()});

  it("puts required fields first, even when the schema lists them A to Z", () => {
    const {container} = renderAiForm();
    const ids = [...container.querySelectorAll("input, select, textarea")].map(el => el.id);

    expect(ids.slice(0, 3)).toEqual(["root_scope", "root_submission", "root_model"]);
  });

  it("gives every field a label and help text", () => {
    const {container} = renderAiForm();

    expect(container.querySelector("label[for='root_scope']")).toHaveTextContent(
      I18n.t("automated_tests.ai_config.scope.title")
    );
    expect(
      screen.getByText(I18n.t("automated_tests.ai_config.scope.description"))
    ).toBeInTheDocument();
  });

  it("skips the help line for fields marked hint: false", () => {
    const uiSchema = aiConfigUiSchema();
    expect(uiSchema.prompt_text["ui:description"]).toBeUndefined();
    expect(uiSchema.scope["ui:description"]).toBe(
      I18n.t("automated_tests.ai_config.scope.description")
    );
  });

  it("names stored values and prompts a choice in lists", () => {
    const uiSchema = aiConfigUiSchema();

    expect(uiSchema.model["ui:enumNames"]["openai-remote"]).toBe(
      "OpenAI-style server, like the AI gateway"
    );
    expect(uiSchema.scope["ui:enumNames"]).toEqual({
      code: I18n.t("automated_tests.ai_config.scope.options.code"),
      text: I18n.t("automated_tests.ai_config.scope.options.text"),
      image: I18n.t("automated_tests.ai_config.scope.options.image"),
    });
    expect(uiSchema.scope["ui:placeholder"]).toBe(I18n.t("automated_tests.choose_one"));
    expect(uiSchema.model["ui:placeholder"]).toBeUndefined();
  });

  it("renders prompt_text as a textarea", () => {
    const {container} = renderAiForm();
    expect(container.querySelector("textarea#root_prompt_text")).toBeInTheDocument();
  });

  it("puts rare fields behind the advanced toggle", () => {
    renderAiForm();
    expect(screen.queryByLabelText(/llama\.cpp mode/)).not.toBeInTheDocument();
    expect(screen.getByRole("button", {name: toggleLabel("show")})).toBeInTheDocument();
  });

  it("works for a config that lacks some of the listed fields", () => {
    const {container} = renderForm({
      schema: {type: "object", properties: {scope: {type: "string"}}},
      uiSchema: aiConfigUiSchema(),
    });
    expect(container.querySelector("#root_scope")).toBeInTheDocument();
  });
});

describe("CardItemTemplate", () => {
  const arraySchema = {
    type: "object",
    properties: {
      groups: {type: "array", items: {type: "object", properties: {name: {type: "string"}}}},
    },
  };
  const arrayUiSchema = {
    groups: {"ui:ArrayFieldItemTemplate": CardItemTemplate, items: {"ui:title": "Test Group"}},
  };
  const renderCards = (props = {}) =>
    renderForm({
      schema: arraySchema,
      uiSchema: arrayUiSchema,
      formData: {groups: [{name: "a"}, {name: "b"}]},
      ...props,
    });

  it("renders each item as a card with a numbered title", () => {
    renderCards();
    const cards = screen.getAllByRole("region");

    expect(cards).toHaveLength(2);
    expect(screen.getByRole("region", {name: "Test Group 1"})).toBeInTheDocument();
    expect(screen.getByRole("region", {name: "Test Group 2"})).toBeInTheDocument();
  });

  it("removes the item when its Remove button is clicked", () => {
    const onChange = jest.fn();
    renderCards({onChange});
    const second = screen.getByRole("region", {name: "Test Group 2"});

    fireEvent.click(second.querySelector(".rjsf-array-item-remove"));

    expect(onChange.mock.calls.at(-1)[0].formData.groups).toEqual([{name: "a"}]);
  });
});

describe("plain names and titles", () => {
  it("shows section titles without the required star", () => {
    const {container} = renderForm({
      schema: {
        type: "object",
        properties: {
          config: {
            type: "object",
            title: "Settings",
            required: ["scope"],
            properties: {scope: {type: "string"}},
          },
        },
        required: ["config"],
      },
      uiSchema: {},
      templates: {...templates, TitleFieldTemplate},
    });
    const legend = container.querySelector("legend#root_config__title");

    expect(legend).toHaveTextContent("Settings");
    expect(legend.querySelector(".required")).toBeNull();
  });

  it("shows plain names for stored values, while saving the raw value", () => {
    const onChange = jest.fn();
    renderForm({
      schema: {type: "object", properties: {tester_type: {type: "string", enum: ["py", "ai"]}}},
      uiSchema: {tester_type: {"ui:enumNames": testerTypeNames(), "ui:placeholder": "Choose one"}},
      onChange,
    });
    const select = screen.getByRole("combobox");

    expect(screen.getByRole("option", {name: "Choose one"})).toBeInTheDocument();
    fireEvent.change(select, {
      target: {
        value: screen.getByRole("option", {name: I18n.t("automated_tests.tester_types.ai")}).value,
      },
    });

    expect(onChange.mock.calls.at(-1)[0].formData.tester_type).toBe("ai");
  });

  it("names every tester the autotester ships", () => {
    const names = testerTypeNames();
    expect(Object.keys(names)).toHaveLength(10);
    Object.values(names).forEach(name => expect(name).not.toMatch(/missing/));
  });
});
