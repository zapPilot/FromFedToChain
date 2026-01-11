import {
  formatDuration,
  parseDuration,
  formatDurationWithUnits,
} from "../format-duration";

describe("formatDuration", () => {
  it("formats seconds to MM:SS", () => {
    expect(formatDuration(65)).toBe("1:05");
    expect(formatDuration(0)).toBe("0:00");
    expect(formatDuration(59)).toBe("0:59");
  });

  it("formats seconds to HH:MM:SS", () => {
    expect(formatDuration(3665)).toBe("1:01:05");
  });

  it("supports alwaysShowHours", () => {
    expect(formatDuration(65, true)).toBe("0:01:05");
  });

  it("handles negative or infinite values", () => {
    expect(formatDuration(-1)).toBe("0:00");
    expect(formatDuration(Infinity)).toBe("0:00");
  });
});

describe("parseDuration", () => {
  it("parses MM:SS to seconds", () => {
    expect(parseDuration("01:05")).toBe(65);
    expect(parseDuration("1:05")).toBe(65);
    expect(parseDuration("0:59")).toBe(59);
  });

  it("parses HH:MM:SS to seconds", () => {
    expect(parseDuration("1:01:05")).toBe(3665);
  });

  it("returns 0 for invalid format", () => {
    expect(parseDuration("invalid")).toBe(0);
  });
});

describe("formatDurationWithUnits", () => {
  it("formats seconds with units", () => {
    expect(formatDurationWithUnits(3665)).toBe("1h 1m 5s");
    expect(formatDurationWithUnits(65)).toBe("1m 5s");
    expect(formatDurationWithUnits(59)).toBe("59s");
  });

  it("handles zero seconds", () => {
    expect(formatDurationWithUnits(0)).toBe("0s"); // Adjust assumption if code diff
  });

  it("handles negative or infinite values", () => {
    expect(formatDurationWithUnits(-1)).toBe("0s");
    expect(formatDurationWithUnits(Infinity)).toBe("0s");
  });
});
