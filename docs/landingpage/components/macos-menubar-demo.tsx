"use client"

import { useState } from "react"
import { RytmoIcon } from "@/components/rytmo-icon"
import { Music, SkipBack, SkipForward, Volume2, Play, Pause, RotateCcw, Settings, X, Activity, Timer, CheckSquare } from "lucide-react"
import Image from "next/image"


function Waveform() {
  return (
    <div className="flex items-center gap-[2px] h-4">
      {[...Array(6)].map((_, i) => (
        <div
          key={i}
          className="w-[2px] bg-red-500/80 rounded-full animate-waveform"
          style={{
            height: `${Math.random() * 100}%`,
            animationDelay: `${i * 0.1}s`,
            animationDuration: `${0.5 + Math.random()}s`
          }}
        ></div>
      ))}
    </div>
  )
}

export function MacOSMenubarDemo() {
  const [isPlaying, setIsPlaying] = useState(true)
  // Session color based on current session type (Work = Red, Short Break = Green, Long Break = Blue)
  const sessionColor = "#EF4444" // Red for work session

  return (
    <div className="relative w-full">
      {/* Floating Badge - "Live on macOS" */}
      <div className="absolute -top-8 md:-top-4 left-1/2 -translate-x-1/2 z-10">
        <div className="bg-[#000000] text-[#FFFFFF] px-4 md:px-6 py-1.5 md:py-2 rounded-full text-xs md:text-sm font-semibold shadow-lg">
          ✨ Live on macOS
        </div>
      </div>

      <div className="relative w-full mx-auto max-w-6xl rounded-lg md:rounded-xl overflow-hidden shadow-xl md:shadow-2xl">
        {/* Base macOS Screenshot */}
        <div className="relative w-full">
          <Image
            src="/rytmo-screenshot.svg"
            alt="Rytmo Pomodoro Timer running in macOS menubar with focus session, timer countdown, and YouTube playlist integration"
            width={1920}
            height={1080}
            className="w-full h-auto"
            priority
          />

          {/* Overlay: Rytmo in Menubar (positioned near wifi/clock area) */}
          <div className="absolute top-[0.3%] right-[21%] flex items-center gap-1 md:gap-1.5 px-1.5 md:px-2 py-0.5 md:py-1 rounded-md bg-white/40 cursor-pointer transition-all" style={{
            border: "2px solid #FF6B6B",
            boxShadow: "0 0 15px rgba(255, 107, 107, 0.5)",
            animation: "pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite"
          }}>
            <RytmoIcon className="w-2.5 h-2.5 md:w-3.5 md:h-3.5 text-gray-900" />
            <span className="text-[9px] md:text-[11px] font-mono font-medium text-gray-900">24:15</span>
          </div>

          {/* Overlay: Rytmo Popover - Below menubar icon */}
          <div className="absolute top-[8%] md:top-[3.5%] left-1/2 -translate-x-1/2 md:left-auto md:translate-x-0 md:right-[17.5%] bg-white/80 backdrop-blur-2xl rounded-[12px] md:rounded-[14px] shadow-xl md:shadow-2xl border border-white/40 overflow-hidden w-[85%] max-w-[340px] md:w-auto md:max-w-none scale-[0.5] md:scale-100 origin-top">
            <div className="flex flex-col w-full md:w-[360px] max-h-[45vh] md:max-h-[580px]">
              {/* Header */}
              <div className="px-3 md:px-4 py-2 md:py-3">
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-[14px] md:text-[18px] text-gray-900">Rytmo</span>
                  <div className="flex items-center gap-1 text-xs md:text-sm text-gray-500">
                    <span className="font-medium">6</span>
                    <span className="text-[10px] md:text-xs">sessions</span>
                  </div>
                </div>
              </div>

              <div className="h-px bg-gray-200/50"></div>

              {/* Timer Section */}
              <div className="px-3 md:px-4 py-3 md:py-4 space-y-3 md:space-y-4">
                {/* Session Type */}
                <div className="flex items-center justify-center gap-2 md:gap-3">
                  <Timer className="w-4 h-4 md:w-6 md:h-6 text-gray-900" />
                  <span className="text-sm md:text-base font-medium text-gray-900">Focus Session</span>
                </div>

                {/* Timer Display */}
                <div className="text-center">
                  <div className="text-[36px] md:text-[56px] font-light text-red-500 tracking-tight leading-none" style={{ fontVariantNumeric: "tabular-nums" }}>
                    24:15
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="space-y-1">
                  <div className="w-full h-1.5 md:h-2 bg-gray-200/50 rounded">
                    <div className="h-full bg-red-500 rounded transition-all duration-100" style={{ width: "60%" }}></div>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] md:text-xs text-gray-500">60%</span>
                  </div>
                </div>

                {/* Control Buttons */}
                <div className="flex items-center gap-2 md:gap-3">
                  <button
                    className="flex-1 flex items-center justify-center gap-1 md:gap-2 h-8 md:h-9 text-white rounded-lg transition-all hover:opacity-90"
                    style={{
                      backgroundColor: "#EF4444", // Red for work session
                      boxShadow: "0 2px 4px rgba(239, 68, 68, 0.3)",
                    }}
                    onClick={() => setIsPlaying(!isPlaying)}
                  >
                    {isPlaying ? <Pause className="w-3 h-3 md:w-3.5 md:h-3.5" /> : <Play className="w-3 h-3 md:w-3.5 md:h-3.5 ml-0.5" />}
                    <span className="text-xs md:text-sm font-medium">{isPlaying ? "Pause" : "Start"}</span>
                  </button>
                  <button className="flex items-center justify-center gap-1 md:gap-1.5 h-8 md:h-9 px-2 md:px-4 bg-gray-200/50 hover:bg-gray-200/70 text-gray-900 rounded-lg transition-colors">
                    <RotateCcw className="w-3 h-3 md:w-3.5 md:h-3.5" />
                    <span className="text-xs md:text-sm font-medium">Reset</span>
                  </button>
                  <button className="flex items-center justify-center w-8 h-8 md:w-9 md:h-9 bg-gray-200/50 hover:bg-gray-200/70 text-gray-900 rounded-lg transition-colors">
                    <SkipForward className="w-3 h-3 md:w-3.5 md:h-3.5" />
                  </button>
                </div>
              </div>

              <div className="h-px bg-gray-200/50"></div>

              {/* Now Playing (conditional) */}
              {isPlaying && (
                <>
                  <div className="px-3 md:px-4 py-2 md:py-3 space-y-1">
                      <div className="flex items-center justify-between gap-1.5 md:gap-2">
                        <div className="flex items-center gap-1.5 md:gap-2">
                          <Music className="w-3 h-3 md:w-4 md:h-4 text-gray-500" />
                          <span className="text-[10px] md:text-xs text-gray-500">Now Playing</span>
                        </div>
                        <Waveform />
                      </div>
                      <div className="text-[11px] md:text-[13px] font-medium text-gray-900 line-clamp-1 py-1">
                        Lo-fi Hip Hop Radio - Beats to Study
                      </div>
                  </div>
                  <div className="h-px bg-gray-200/50"></div>
                </>
              )}

              {/* Playlist Section */}
              <div className="flex-1 flex flex-col min-h-0">
                {/* Playlist Header */}
                <div className="px-3 md:px-4 py-1.5 md:py-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5 md:gap-2">
                      <Music className="w-3 h-3 md:w-3.5 md:h-3.5 text-gray-500" />
                      <span className="text-xs md:text-sm font-medium text-gray-900">Playlist</span>
                    </div>
                    <div className="flex items-center gap-1.5 md:gap-2">
                      <span className="text-[10px] md:text-xs text-gray-500">3 tracks</span>
                      <button className="w-4 h-4 md:w-5 md:h-5 flex items-center justify-center hover:opacity-70 transition-opacity text-gray-500">
                        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" className="md:w-5 md:h-5">
                          <circle cx="10" cy="10" r="8" fill="currentColor" />
                          <path d="M10 6V14M6 10H14" stroke="white" strokeWidth="2" strokeLinecap="round" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>

                {/* Music Controls */}
                <div className="px-3 md:px-4 py-1.5 md:py-2">
                  <div className="flex items-center gap-2 md:gap-4">
                    <button className="text-gray-700 hover:text-gray-900 transition-colors">
                      <SkipBack className="w-3 h-3 md:w-4 md:h-4" />
                    </button>
                    <button
                      className="w-8 h-8 md:w-10 md:h-10 rounded-full flex items-center justify-center text-white bg-gray-700 shadow-sm transition-all hover:opacity-90"
                    >
                      {isPlaying ? <Pause className="w-3 h-3 md:w-4 md:h-4" /> : <Play className="w-3 h-3 md:w-4 md:h-4 ml-0.5" />}
                    </button>
                    <button className="text-gray-700 hover:text-gray-900 transition-colors">
                      <SkipForward className="w-3 h-3 md:w-4 md:h-4" />
                    </button>
                    <div className="flex items-center gap-1 ml-auto">
                      <Volume2 className="w-2.5 h-2.5 md:w-3 md:h-3 text-gray-500" />
                      <span className="text-[9px] md:text-[11px] text-gray-500">70%</span>
                    </div>
                  </div>
                </div>

                {/* Track List - Scrollable */}
                <div className="flex-1 overflow-y-auto px-1 md:px-2">
                  {[
                    { title: "Jazzy Cafe - Morning Coffee", id: "abc123", isPlaying: true },
                    { title: "Ambient Study Session", id: "def456", isPlaying: false },
                    { title: "Chill Beats Vol. 3", id: "ghi789", isPlaying: false },
                  ].map((track, i) => (
                    <div
                      key={i}
                      className="flex items-center gap-2 md:gap-3 px-2 md:px-3 py-1.5 md:py-2 rounded cursor-pointer transition-colors hover:bg-gray-100/50"
                      style={
                        track.isPlaying
                          ? {
                              backgroundColor: `${sessionColor}1A`, // 10% opacity
                            }
                          : {}
                      }
                    >
                      {track.isPlaying ? (
                        <Activity className="w-4 h-4 md:w-6 md:h-6 flex-shrink-0" style={{ color: sessionColor }} />
                      ) : (
                        <Music className="w-4 h-4 md:w-6 md:h-6 flex-shrink-0 text-gray-400" />
                      )}
                      <div className="flex-1 min-w-0">
                        <div
                          className="text-[11px] md:text-[13px] truncate"
                          style={track.isPlaying ? { color: sessionColor } : { color: "rgb(17, 24, 39)" }}
                        >
                          {track.title}
                        </div>
                        <div className="text-[9px] md:text-[10px] text-gray-500">{track.id}</div>
                      </div>
                    </div>
                  ))}
                </div>
                
                <div className="h-px bg-gray-200/50"></div>

                {/* Todo List Section */}
                <div className="flex-1 flex flex-col min-h-0 bg-gray-50/50">
                  <div className="px-3 md:px-4 py-2 border-b border-gray-100 flex items-center justify-between">
                    <div className="flex items-center gap-1.5 md:gap-2">
                      <CheckSquare className="w-3 h-3 md:w-3.5 md:h-3.5 text-gray-500" />
                      <span className="text-xs md:text-sm font-medium text-gray-900">Today&apos;s Tasks</span>
                    </div>
                    <span className="text-[10px] md:text-xs text-gray-400">2/3</span>
                  </div>
                  <div className="p-2 space-y-1 overflow-y-auto max-h-[120px]">
                    {[
                      { title: "Design System Update", completed: true },
                      { title: "Code Review - Auth Layer", completed: true },
                      { title: "Landing Page v1.0.3", completed: false }
                    ].map((todo, i) => (
                      <div key={i} className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-white transition-colors group">
                        <div className={`w-3.5 h-3.5 rounded-sm border flex items-center justify-center transition-colors ${todo.completed ? 'bg-green-500 border-green-500' : 'border-gray-300 bg-white'}`}>
                          {todo.completed && <div className="w-1.5 h-1.5 bg-white rounded-full"></div>}
                        </div>
                        <span className={`text-[11px] md:text-[12px] truncate ${todo.completed ? 'text-gray-400 line-through' : 'text-gray-700'}`}>
                          {todo.title}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="h-px bg-gray-200/50"></div>

              {/* Footer */}
              <div className="px-3 md:px-4 py-2 md:py-3">
                <div className="flex items-center justify-between">
                  <button className="flex items-center gap-1 md:gap-1.5 text-[10px] md:text-xs text-gray-600 hover:text-gray-900 transition-colors">
                    <Settings className="w-3 h-3 md:w-3.5 md:h-3.5" />
                    <span>Settings</span>
                  </button>
                  <button className="flex items-center gap-1 md:gap-1.5 text-[10px] md:text-xs text-gray-600 hover:text-gray-900 transition-colors">
                    <X className="w-3 h-3 md:w-3.5 md:h-3.5" />
                    <span>Quit</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
