/**
 * localStorage wrapper with error handling and fallback support
 * Provides safe access to browser localStorage with automatic fallback to in-memory storage
 */

// In-memory fallback storage for environments without localStorage
const memoryStorage = new Map<string, string>();

/**
 * Check if localStorage is available
 */
function isLocalStorageAvailable(): boolean {
  try {
    const test = "__localStorage_test__";
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch {
    return false;
  }
}

/**
 * Get item from storage
 *
 * @param key - Storage key
 * @returns Stored value or null if not found
 */
export function getItem(key: string): string | null {
  try {
    if (isLocalStorageAvailable()) {
      return localStorage.getItem(key);
    }
    return memoryStorage.get(key) ?? null;
  } catch (error) {
    console.warn(`Failed to get item from storage: ${key}`, error);
    return memoryStorage.get(key) ?? null;
  }
}

/**
 * Set item in storage
 *
 * @param key - Storage key
 * @param value - Value to store
 * @returns True if successful, false otherwise
 */
export function setItem(key: string, value: string): boolean {
  try {
    if (isLocalStorageAvailable()) {
      localStorage.setItem(key, value);
      // Also store in memory as backup
      memoryStorage.set(key, value);
      return true;
    }
    memoryStorage.set(key, value);
    return true;
  } catch (error) {
    console.warn(`Failed to set item in storage: ${key}`, error);
    // Fallback to memory storage
    memoryStorage.set(key, value);
    return false;
  }
}

/**
 * Remove item from storage
 *
 * @param key - Storage key
 * @returns True if successful, false otherwise
 */
export function removeItem(key: string): boolean {
  try {
    if (isLocalStorageAvailable()) {
      localStorage.removeItem(key);
    }
    memoryStorage.delete(key);
    return true;
  } catch (error) {
    console.warn(`Failed to remove item from storage: ${key}`, error);
    memoryStorage.delete(key);
    return false;
  }
}

/**
 * Clear all items from storage
 *
 * @returns True if successful, false otherwise
 */
export function clear(): boolean {
  try {
    if (isLocalStorageAvailable()) {
      localStorage.clear();
    }
    memoryStorage.clear();
    return true;
  } catch (error) {
    console.warn("Failed to clear storage", error);
    memoryStorage.clear();
    return false;
  }
}

/**
 * Get JSON object from storage
 *
 * @param key - Storage key
 * @param defaultValue - Default value if parsing fails
 * @returns Parsed object or default value
 */
export function getJSON<T>(key: string, defaultValue: T): T {
  try {
    const item = getItem(key);
    if (!item) return defaultValue;
    return JSON.parse(item) as T;
  } catch (error) {
    console.warn(`Failed to parse JSON from storage: ${key}`, error);
    return defaultValue;
  }
}

/**
 * Set JSON object in storage
 *
 * @param key - Storage key
 * @param value - Object to store
 * @returns True if successful, false otherwise
 */
export function setJSON<T>(key: string, value: T): boolean {
  try {
    const json = JSON.stringify(value);
    return setItem(key, json);
  } catch (error) {
    console.warn(`Failed to stringify JSON for storage: ${key}`, error);
    return false;
  }
}

/**
 * Get all keys in storage
 *
 * @returns Array of storage keys
 */
export function getAllKeys(): string[] {
  try {
    if (isLocalStorageAvailable()) {
      return Object.keys(localStorage);
    }
    return Array.from(memoryStorage.keys());
  } catch (error) {
    console.warn("Failed to get storage keys", error);
    return Array.from(memoryStorage.keys());
  }
}

/**
 * Check if key exists in storage
 *
 * @param key - Storage key
 * @returns True if key exists, false otherwise
 */
export function has(key: string): boolean {
  return getItem(key) !== null;
}

/**
 * Get storage size in bytes (approximate)
 *
 * @returns Approximate storage size in bytes
 */
export function getStorageSize(): number {
  try {
    let total = 0;
    if (isLocalStorageAvailable()) {
      for (const key in localStorage) {
        if (Object.prototype.hasOwnProperty.call(localStorage, key)) {
          const value = localStorage.getItem(key);
          total += key.length + (value?.length || 0);
        }
      }
    } else {
      for (const [key, value] of memoryStorage) {
        total += key.length + value.length;
      }
    }
    return total * 2; // Approximate bytes (UTF-16 encoding)
  } catch (error) {
    console.warn("Failed to calculate storage size", error);
    return 0;
  }
}
