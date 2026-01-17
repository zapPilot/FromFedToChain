import { render, screen, fireEvent } from "@testing-library/react";
import CategoryFilter from "../CategoryFilter";
import { Category } from "@/types/content";

describe("CategoryFilter", () => {
  const mockOnCategoryChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should render all categories + 'All'", () => {
    render(
      <CategoryFilter
        selectedCategory={null}
        onCategoryChange={mockOnCategoryChange}
      />,
    );

    // "All" button
    expect(screen.getByText("All")).toBeInTheDocument();

    // Check for some expected categories
    expect(screen.getByText(/Daily News/)).toBeInTheDocument();
    expect(screen.getByText(/Ethereum/)).toBeInTheDocument();
    expect(screen.getByText(/Macro/)).toBeInTheDocument();
  });

  it("should highlight selected category", () => {
    render(
      <CategoryFilter
        selectedCategory="ethereum"
        onCategoryChange={mockOnCategoryChange}
      />,
    );

    const ethereumButton = screen.getByText(/Ethereum/).closest("button");
    expect(ethereumButton).toHaveClass("bg-white");

    const allButton = screen.getByText("All").closest("button");
    expect(allButton).not.toHaveClass("bg-white");
  });

  it("should call onCategoryChange when clicked", () => {
    render(
      <CategoryFilter
        selectedCategory={null}
        onCategoryChange={mockOnCategoryChange}
      />,
    );

    const ethereumButton = screen.getByText(/Ethereum/);
    fireEvent.click(ethereumButton);

    expect(mockOnCategoryChange).toHaveBeenCalledWith("ethereum");
  });

  it("should call onCategoryChange with null when 'All' is clicked", () => {
    render(
      <CategoryFilter
        selectedCategory="ethereum"
        onCategoryChange={mockOnCategoryChange}
      />,
    );

    const allButton = screen.getByText("All");
    fireEvent.click(allButton);

    expect(mockOnCategoryChange).toHaveBeenCalledWith(null);
  });
});
