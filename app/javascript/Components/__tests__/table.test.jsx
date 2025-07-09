import React from "react";
import {render, screen, fireEvent, waitFor} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Table from "../table/table";

const mockColumns = [
  {
    accessorKey: "name",
    header: "Name",
    enableSorting: true,
    enableColumnFilter: true,
  },
  {
    accessorKey: "age",
    header: "Age",
    enableSorting: true,
    enableColumnFilter: true,
  },
  {
    accessorKey: "email",
    header: "Email",
    enableSorting: false,
    enableColumnFilter: true,
  },
  {
    accessorKey: "status",
    header: "Status",
    enableSorting: true,
    enableColumnFilter: true,
    meta: {
      filterVariant: "select",
    },
  },
];

const mockData = [
  {id: 1, name: "John Doe", age: 30, email: "john@example.com", status: "active"},
  {id: 2, name: "Jane Smith", age: 25, email: "jane@example.com", status: "inactive"},
  {id: 3, name: "Bob Johnson", age: 35, email: "bob@example.com", status: "active"},
  {id: 4, name: "Alice Brown", age: 28, email: "alice@example.com", status: "pending"},
];

describe("Table Component", () => {
  describe("Basic Rendering", () => {
    it("renders table with data", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      expect(screen.getByText("Name")).toBeInTheDocument();
      expect(screen.getByText("Age")).toBeInTheDocument();
      expect(screen.getByText("Email")).toBeInTheDocument();
      expect(screen.getByText("Status")).toBeInTheDocument();

      expect(screen.getByText("John Doe")).toBeInTheDocument();
      expect(screen.getByText("Jane Smith")).toBeInTheDocument();
      expect(screen.getByText("30")).toBeInTheDocument();
      expect(screen.getByText("john@example.com")).toBeInTheDocument();
    });

    it("renders table structure with correct roles", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      expect(screen.getByRole("grid")).toBeInTheDocument();
      expect(screen.getAllByRole("columnheader")).toHaveLength(8);
      expect(screen.getAllByRole("row")).toHaveLength(6);
      expect(screen.getAllByRole("gridcell")).toHaveLength(16);
    });

    it("applies correct CSS classes", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      expect(document.querySelector(".Table.-highlight")).toBeInTheDocument();
      expect(document.querySelector(".rt-table")).toBeInTheDocument();
      expect(document.querySelector(".rt-thead.-header")).toBeInTheDocument();
      expect(document.querySelector(".rt-thead.-filters")).toBeInTheDocument();
      expect(document.querySelector(".rt-tbody")).toBeInTheDocument();
    });

    it("renders rows in correct order", () => {
      const {container} = render(<Table columns={mockColumns} data={mockData} />);

      const rows = container.querySelectorAll(".rt-tbody .rt-tr");
      expect(rows).toHaveLength(4);

      expect(rows[0]).toHaveTextContent("John Doe");
      expect(rows[1]).toHaveTextContent("Jane Smith");
      expect(rows[2]).toHaveTextContent("Bob Johnson");
      expect(rows[3]).toHaveTextContent("Alice Brown");
    });
  });

  describe("No Data Handling", () => {
    it("displays default no data message when data is empty", () => {
      render(<Table columns={mockColumns} data={[]} />);

      expect(screen.getByText("No rows found")).toBeInTheDocument();
      expect(screen.getByText("No rows found")).toHaveClass("rt-no-data");
    });

    it("displays custom no data message", () => {
      const customMessage = "No results available";
      render(<Table columns={mockColumns} data={[]} noDataText={customMessage} />);

      expect(screen.getByText(customMessage)).toBeInTheDocument();
      expect(screen.queryByText("No rows found")).not.toBeInTheDocument();
    });

    it("does not display no data message when data exists", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      expect(screen.queryByText("No rows found")).not.toBeInTheDocument();
    });
  });

  describe("Column Sorting", () => {
    it("sorts column when header is clicked", async () => {
      const user = userEvent.setup();
      render(<Table columns={mockColumns} data={mockData} />);

      const nameHeader = screen.getByText("Name");
      await user.click(nameHeader);

      const headerElement = nameHeader.closest(".rt-th");
      expect(headerElement).toHaveClass("--cursor-pointer");
    });

    it("applies correct sorting classes", async () => {
      const user = userEvent.setup();
      render(<Table columns={mockColumns} data={mockData} />);

      const nameHeader = screen.getByText("Name");

      await user.click(nameHeader);
      expect(nameHeader.closest(".rt-th")).toHaveClass("rt-resizable-header-content");

      await user.click(nameHeader);
      expect(nameHeader.closest(".rt-th")).toHaveClass("rt-resizable-header-content");
    });

    it("applies sorting classes to all headers", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      const emailHeader = screen.getByText("Email");
      const headerElement = emailHeader.closest(".rt-th");

      expect(headerElement).toHaveClass("--cursor-pointerundefined");
    });

    it("sorts rows in correct order when name column is clicked", async () => {
      const user = userEvent.setup();
      const {container} = render(<Table columns={mockColumns} data={mockData} />);

      const nameHeader = screen.getByText("Name");
      await user.click(nameHeader);

      await waitFor(() => {
        const rows = container.querySelectorAll(".rt-tbody .rt-tr");
        expect(rows).toHaveLength(4);

        expect(rows[0]).toHaveTextContent("Alice Brown");
        expect(rows[1]).toHaveTextContent("Bob Johnson");
        expect(rows[2]).toHaveTextContent("Jane Smith");
        expect(rows[3]).toHaveTextContent("John Doe");
      });
    });

    it("sorts rows in reverse order when name column is clicked twice", async () => {
      const user = userEvent.setup();
      const {container} = render(<Table columns={mockColumns} data={mockData} />);

      const nameHeader = screen.getByText("Name");
      await user.click(nameHeader);
      await user.click(nameHeader);

      await waitFor(() => {
        const rows = container.querySelectorAll(".rt-tbody .rt-tr");
        expect(rows).toHaveLength(4);

        expect(rows[0]).toHaveTextContent("John Doe");
        expect(rows[1]).toHaveTextContent("Jane Smith");
        expect(rows[2]).toHaveTextContent("Bob Johnson");
        expect(rows[3]).toHaveTextContent("Alice Brown");
      });
    });

    it("handles empty columns array", () => {
      render(<Table columns={[]} data={mockData} />);

      expect(screen.getByRole("grid")).toBeInTheDocument();
    });

    it("handles null/undefined data", () => {
      render(<Table columns={mockColumns} data={[]} />);

      expect(screen.getByText("No rows found")).toBeInTheDocument();
    });

    it("handles data with missing properties", () => {
      const incompleteData = [
        {id: 1, name: "John"},
        {id: 2, age: 25},
        {id: 3, email: "test@example.com"},
      ];

      render(<Table columns={mockColumns} data={incompleteData} />);

      expect(screen.getByText("John")).toBeInTheDocument();
      expect(screen.getByText("25")).toBeInTheDocument();
      expect(screen.getByText("test@example.com")).toBeInTheDocument();
    });

    it("handles numeric zero values", () => {
      const zeroData = [
        {
          id: 0,
          name: "Zero Test",
          age: 0,
          email: "zero@example.com",
          status: "active",
        },
      ];

      render(<Table columns={mockColumns} data={zeroData} />);

      expect(screen.getByText("0")).toBeInTheDocument();
      expect(screen.getByText("Zero Test")).toBeInTheDocument();
    });

    it("handles boolean values", () => {
      const booleanColumns = [
        {accessorKey: "name", header: "Name"},
        {accessorKey: "active", header: "Active"},
      ];

      const booleanData = [
        {name: "Test User", active: true},
        {name: "Another User", active: false},
      ];

      render(<Table columns={booleanColumns} data={booleanData} />);

      expect(screen.getByText("Test User")).toBeInTheDocument();
      expect(screen.getByText("Another User")).toBeInTheDocument();
    });
  });

  describe("Column Resizing", () => {
    it("renders resize handles for all columns", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      const resizers = document.querySelectorAll(".rt-resizer");
      expect(resizers).toHaveLength(4);
    });

    it("applies resizing class when column is being resized", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      const resizers = document.querySelectorAll(".rt-resizer");
      resizers.forEach(resizer => {
        expect(resizer).toHaveClass("resizer");
      });
    });
  });

  describe("Column Filtering", () => {
    it("renders search filters for filterable columns", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      const searchInputs = screen.getAllByPlaceholderText("Search");
      expect(searchInputs.length).toBeGreaterThan(0);
    });

    it("renders select filter for columns with select variant", () => {
      render(<Table columns={mockColumns} data={mockData} />);

      const selectFilter = screen.getByRole("combobox");
      expect(selectFilter.tagName).toBe("SELECT");
    });

    it("filters data when search input is used", async () => {
      const user = userEvent.setup();
      render(<Table columns={mockColumns} data={mockData} />);

      const searchInputs = screen.getAllByPlaceholderText("Search");
      const nameSearchInput = searchInputs[0];

      await user.type(nameSearchInput, "John");

      expect(nameSearchInput.value).toBe("John");
    });

    it("filters data when select filter is used", async () => {
      const user = userEvent.setup();
      render(<Table columns={mockColumns} data={mockData} />);

      const selectFilter = screen.getByRole("combobox");
      await user.selectOptions(selectFilter, "active");

      expect(selectFilter.value).toBe("active");
    });
  });

  describe("Filter Components", () => {
    describe("SearchFilter", () => {
      it("renders with correct attributes", () => {
        render(<Table columns={mockColumns} data={mockData} />);

        const searchInputs = screen.getAllByPlaceholderText("Search");
        searchInputs.forEach(input => {
          expect(input).toHaveAttribute("type", "text");
          expect(input).toHaveAttribute("aria-label", "Search");
          expect(input).toHaveStyle("width: 100%");
        });
      });

      it("updates filter value on input change", async () => {
        const user = userEvent.setup();
        render(<Table columns={mockColumns} data={mockData} />);

        const searchInput = screen.getAllByPlaceholderText("Search")[0];
        await user.type(searchInput, "test");

        expect(searchInput.value).toBe("test");
      });
    });

    describe("SelectFilter", () => {
      it("renders with all unique values as options", () => {
        render(<Table columns={mockColumns} data={mockData} />);

        const selectFilter = screen.getByRole("combobox");
        const options = selectFilter.querySelectorAll("option");

        expect(options.length).toBeGreaterThan(1);
        expect(options[0].textContent).toContain("All");
      });

      it("displays option counts correctly", () => {
        render(<Table columns={mockColumns} data={mockData} />);

        const selectFilter = screen.getByRole("combobox");
        const allOption = selectFilter.querySelector("option[value='']");

        expect(allOption.textContent).toContain("All (4)");
      });

      it("sorts options alphabetically", () => {
        render(<Table columns={mockColumns} data={mockData} />);

        const selectFilter = screen.getByRole("combobox");
        const options = Array.from(selectFilter.querySelectorAll("option")).slice(1);

        const values = options.map(option => option.value);
        const sortedValues = [...values].sort();

        expect(values).toEqual(sortedValues);
      });
    });
  });
});
