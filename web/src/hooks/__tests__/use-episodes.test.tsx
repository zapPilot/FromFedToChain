import { renderHook, act } from "@testing-library/react";
import { useEpisodes } from "../use-episodes";
import { useEpisodesStore } from "@/stores/episodes-store";
import { useSearchParams, useRouter, usePathname } from "next/navigation";

// Mock store
jest.mock("@/stores/episodes-store", () => ({
  useEpisodesStore: Object.assign(
    jest.fn(), // Default export as hook
    { getState: jest.fn() }, // Static method
  ),
}));

// Mock router hooks
jest.mock("next/navigation", () => ({
  useSearchParams: jest.fn(),
  useRouter: jest.fn(),
  usePathname: jest.fn(),
}));

describe("useEpisodes", () => {
  const mockStore = {
    selectedLanguage: "",
    selectedCategory: "",
    searchQuery: "", // Added
    setLanguage: jest.fn(),
    setCategory: jest.fn(),
    allEpisodes: [],
    filteredEpisodes: [], // Added
    isLoading: false,
    loadEpisodes: jest.fn(),
  };

  const mockRouter = {
    replace: jest.fn(),
    push: jest.fn(),
  };

  const mockSearchParams = new URLSearchParams();

  beforeEach(() => {
    jest.clearAllMocks();

    // Reset mock store state
    mockStore.selectedLanguage = "";
    mockStore.selectedCategory = "";
    mockStore.searchQuery = "";
    mockStore.filteredEpisodes = [];

    // Setup mocks
    (useEpisodesStore as unknown as jest.Mock).mockReturnValue(mockStore);
    (useEpisodesStore as any).getState.mockReturnValue(mockStore);
    (useSearchParams as jest.Mock).mockReturnValue(mockSearchParams);
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
    (usePathname as jest.Mock).mockReturnValue("/episodes");
  });

  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <>{children}</>
  );

  it("should initialize store from URL parameters", () => {
    const params = new URLSearchParams();
    params.set("lang", "en-US");
    params.set("category", "ai");
    (useSearchParams as jest.Mock).mockReturnValue(params);

    renderHook(() => useEpisodes(false), { wrapper: Wrapper });

    expect(mockStore.setLanguage).toHaveBeenCalledWith("en-US");
    expect(mockStore.setCategory).toHaveBeenCalledWith("ai");
  });

  it("should auto-load episodes if enabled", () => {
    renderHook(() => useEpisodes(true));
    expect(mockStore.loadEpisodes).toHaveBeenCalled();
  });
});
