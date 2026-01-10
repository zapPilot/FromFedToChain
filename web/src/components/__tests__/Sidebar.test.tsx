import { render, screen } from "@testing-library/react";
import { Sidebar } from "../Sidebar";
import "@testing-library/jest-dom";

// Mock the hooks
jest.mock("@/hooks/use-episodes", () => ({
  useEpisodes: () => ({
    selectedCategory: null,
    selectedLanguage: "en-US",
    setCategory: jest.fn(),
    setLanguage: jest.fn(),
    clearFilters: jest.fn(),
  }),
}));

describe("Sidebar", () => {
  it("renders the brand header", () => {
    render(<Sidebar />);
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).toHaveTextContent("From Fed to Chain");
  });

  it("renders navigation sections", () => {
    render(<Sidebar />);
    expect(screen.getByText("Discover")).toBeInTheDocument();
    expect(screen.getByText("Market Sectors")).toBeInTheDocument();
    expect(screen.getByText("Region")).toBeInTheDocument();
  });

  it("renders all episode button", () => {
    render(<Sidebar />);
    expect(screen.getByText("All Episodes")).toBeInTheDocument();
  });

  it("renders category links", () => {
    render(<Sidebar />);
    // Check for a few categories
    expect(screen.getByText("Daily News")).toBeInTheDocument();
    expect(screen.getByText("Ethereum")).toBeInTheDocument();
    expect(screen.getByText("Macro Economics")).toBeInTheDocument();
  });

  it("renders language selectors", () => {
    render(<Sidebar />);
    expect(screen.getByTitle("English")).toBeInTheDocument();
    expect(screen.getByTitle("繁體中文")).toBeInTheDocument();
    expect(screen.getByTitle("日本語")).toBeInTheDocument();
  });
});
