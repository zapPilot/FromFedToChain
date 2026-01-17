import { throttle, debounce, batch } from "../throttle";

describe("throttle", () => {
  jest.useFakeTimers();

  it("should throttle function calls", () => {
    const fn = jest.fn();
    const throttledFn = throttle(fn, 1000);

    throttledFn();
    expect(fn).toHaveBeenCalledTimes(1);

    throttledFn();
    throttledFn();
    expect(fn).toHaveBeenCalledTimes(1); // Should not call again immediately

    jest.advanceTimersByTime(1000);
    throttledFn();
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("should handle arguments", () => {
    const fn = jest.fn();
    const throttledFn = throttle(fn, 1000);

    throttledFn("arg1");
    expect(fn).toHaveBeenCalledWith("arg1");
  });
});

describe("debounce", () => {
  jest.useFakeTimers();

  it("should debounce function calls", () => {
    const fn = jest.fn();
    const debouncedFn = debounce(fn, 1000);

    debouncedFn();
    expect(fn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(500);
    debouncedFn(); // Reset timer
    expect(fn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(1000);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("should cancel debounced call", () => {
    const fn = jest.fn();
    const debouncedFn = debounce(fn, 1000);

    debouncedFn();
    debouncedFn.cancel();

    jest.advanceTimersByTime(1000);
    expect(fn).not.toHaveBeenCalled();
  });

  it("should handle multiple calls safely", () => {
    const fn = jest.fn();
    const debouncedFn = debounce(fn, 1000);

    debouncedFn.cancel(); // Cancel before call should be safe
    expect(fn).not.toHaveBeenCalled();
  });
});

describe("batch", () => {
  jest.useFakeTimers();

  it("should batch function calls", () => {
    const fn = jest.fn();
    const batchedFn = batch(fn, 1000);

    batchedFn("a");
    batchedFn("b");
    batchedFn("c");

    expect(fn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(1000);
    expect(fn).toHaveBeenCalledTimes(1);
    expect(fn).toHaveBeenCalledWith(["a", "b", "c"]);
  });

  it("should start new batch after execution", () => {
    const fn = jest.fn();
    const batchedFn = batch(fn, 1000);

    batchedFn("a");
    jest.advanceTimersByTime(1000);
    expect(fn).toHaveBeenCalledWith(["a"]);

    batchedFn("b");
    jest.advanceTimersByTime(1000);
    expect(fn).toHaveBeenCalledWith(["b"]);
  });
});
