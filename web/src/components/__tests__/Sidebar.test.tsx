import { render, screen, fireEvent } from "@testing-library/react";
import { Sidebar } from "../Sidebar";
import "@testing-library/jest-dom";

// Define mock functions
const mockSetCategory = jest.fn();
const mockSetLanguage = jest.fn();
const mockClearFilters = jest.fn();

// Default mock values
const defaultMockValues = {
  selectedCategory: null,
  selectedLanguage: "en-US",
};

let mockValues = { ...defaultMockValues };

// Mock the hooks
jest.mock("@/hooks/use-episodes", () => ({
  useEpisodes: () => ({
    selectedCategory: mockValues.selectedCategory,
    selectedLanguage: mockValues.selectedLanguage,
    setCategory: mockSetCategory,
    setLanguage: mockSetLanguage,
    clearFilters: mockClearFilters,
  }),
}));

describe("Sidebar", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockValues = { ...defaultMockValues };
  });

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

  it("calls clearFilters when clicking All Episodes", () => {
    render(<Sidebar />);
    const allBtn = screen.getByText("All Episodes").closest("button");
    fireEvent.click(allBtn!);
    expect(mockClearFilters).toHaveBeenCalled();
  });

  it("renders category links and handles selection", () => {
    render(<Sidebar />);
    // Check for a few categories
    expect(screen.getByText("Daily News")).toBeInTheDocument();

    // Click category
    fireEvent.click(screen.getByText("Daily News"));
    expect(mockSetCategory).toHaveBeenCalledWith("daily-news");
  });

  it("shows active state for selected category", () => {
    mockValues = { ...defaultMockValues, selectedCategory: "macro" as any };
    render(<Sidebar />);

    // Macro should have active styles (checking roughly by class or just that it renders)
    // The component implementation adds specific classes so we can't easily check computed styles in jsdom without better setup,
    // but we can assume if it renders without error with the prop, the branch is taken.
    // Ideally we check for a class like 'bg-white/10' or presence of the EMOJI which is conditional
    expect(screen.getByText("📊")).toBeInTheDocument(); // Emoji only shows when selected
  });

  it("shows active state for selected language", () => {
    mockValues = { ...defaultMockValues, selectedLanguage: "ja-JP" };
    render(<Sidebar />);

    // Check if JA is selected.
    // We can check if the button has the active class
    const jpBtn = screen.getByTitle("日本語");
    expect(jpBtn).toHaveClass("bg-white/10");
  });

  it("calls setLanguage when clicking language", () => {
    render(<Sidebar />);
    const zhBtn = screen.getByTitle("繁體中文");
    fireEvent.click(zhBtn);
    expect(mockSetLanguage).toHaveBeenCalledWith("zh-TW");
  });
});
