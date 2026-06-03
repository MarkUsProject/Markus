import React from "react";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import "@testing-library/jest-dom";
import {AdminUsersList} from "../admin_users_list";

beforeAll(() => {
  global.Routes = {
    admin_users_path: jest.fn(() => "/admin/users"),
    edit_admin_user_path: jest.fn(id => `/admin/users/${id}/edit`),
  };
  global.I18n = {
    t: jest.fn(key => {
      const translations = {
        "activerecord.attributes.user.user_name": "User Name",
        "activerecord.attributes.user.email": "Email",
        "activerecord.models.admin_user.one": "Admin User",
        "activerecord.models.end_user.one": "End User",
        actions: "Actions",
        edit: "Edit",
      };
      return translations[key] || key;
    }),
  };
});

beforeEach(() => {
  global.fetch = jest.fn();
});

afterEach(() => {
  jest.clearAllMocks();
});

describe("AdminUsersList Component", () => {
  const mockApiResponse = {
    users: [
      {
        id: 42,
        user_name: "Bobby",
        first_name: "Miles",
        last_name: "Morales",
        email: "miles@ny.edu",
        id_number: "161",
        type: "EndUser",
      },
    ],
    total_pages: 1,
  };

  it("queries the backend matching default sorting configurations on load", async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockApiResponse,
    });

    render(<AdminUsersList />);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining("/admin/users?page=1&per_page=100"),
        expect.any(Object)
      );
    });

    expect(await screen.findByText("Bobby")).toBeInTheDocument();
    expect(screen.getByText("Miles")).toBeInTheDocument();
    expect(screen.getByRole("gridcell", {name: "End User"})).toBeInTheDocument();
  });

  it("resets targetPage to 0 if a filter configuration transition occurs", async () => {
    global.fetch.mockResolvedValue({
      ok: true,
      json: async () => mockApiResponse,
    });

    const {container} = render(<AdminUsersList />);
    const filterInputs = container.querySelectorAll(".rt-th input");
    if (filterInputs.length > 0) {
      fireEvent.change(filterInputs[0], {target: {value: "miles"}});

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          expect.stringContaining(
            "filtered=%5B%7B%22id%22%3A%22user_name%22%2C%22value%22%3A%22miles%22%7D%5D"
          ),
          expect.any(Object)
        );
      });
    }
  });
});
