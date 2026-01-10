import { useState, useRef, useEffect } from "react";
import { useAudioPlayer } from "@/hooks/use-audio-player";
import { PLAYBACK_SPEEDS } from "@/stores/audio-player-store";

/**
 * Playback speed selector component
 * Dropdown menu for changing playback speed (1.0x, 1.25x, 1.5x, 2.0x)
 */
export function PlaybackSpeedSelector() {
  const { playbackSpeed, setSpeed } = useAudioPlayer();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    }

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
      return () => {
        document.removeEventListener("mousedown", handleClickOutside);
      };
    }
  }, [isOpen]);

  const handleSpeedChange = (speed: number) => {
    setSpeed(speed as (typeof PLAYBACK_SPEEDS)[number]);
    setIsOpen(false);
  };

  return (
    <div className="relative" ref={dropdownRef}>
      {/* Speed button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-1 px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 rounded-lg transition-colors text-sm font-medium text-zinc-300"
        aria-label="Playback speed"
      >
        {playbackSpeed}×
      </button>

      {/* Dropdown menu */}
      {isOpen && (
        <div className="absolute bottom-full mb-2 right-0 bg-zinc-800 border border-zinc-700 rounded-lg shadow-xl overflow-hidden z-50 min-w-[120px]">
          {PLAYBACK_SPEEDS.map((speed) => (
            <button
              key={speed}
              onClick={() => handleSpeedChange(speed)}
              className={`
                w-full px-4 py-2.5 text-left text-sm transition-colors
                ${
                  speed === playbackSpeed
                    ? "bg-zinc-700 text-zinc-100 font-medium"
                    : "text-zinc-300 hover:bg-zinc-750"
                }
              `}
            >
              {speed}× {speed === 1.0 && "(Normal)"}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
