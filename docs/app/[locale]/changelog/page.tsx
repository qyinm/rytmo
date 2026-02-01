import { useTranslations } from 'next-intl';
import { Header } from "@/components/header"
import { Badge } from "@/components/ui/badge"

export default function Changelog() {
  const t = useTranslations('Header'); // Reuse header translations or create new ones if needed

  const changes = [
    {
      version: "v1.0.4",
      date: "2026-01-16",
      title: "Notch UI & Calendar Integration",
      items: [
        "Dynamic Island-style Notch UI with tab-based navigation (Home, Music, Calendar).",
        "Google Calendar integration with unified multi-source calendar system.",
        "New compact calendar grid with events and todos in Notch view.",
        "Focus session tracking and stats dashboard.",
        "Redesigned Todo UI with inline add, rich text notes, and smart date parsing.",
        "Completed todos now only appear on their completion date.",
        "Waveform visualization and thumbnail display in Notch area.",
        "Performance optimizations for calendar and date formatting."
      ]
    },
    {
      version: "v1.0.3",
      date: "2026-01-11",
      title: "Task Management & Visuals",
      items: [
        "Introducing Sleek To-do List feature.",
        "Redesigned Minimal Menubar UI.",
        "Added Dynamic Waveform Visualization.",
        "New Menubar Timer accessibility.",
        "Audio Output Device Selection.",
        "Enhanced Playback Controls & Layout stability.",
        "Bug fixes for memory leaks and app initialization."
      ]
    },
    {
      version: "v1.0.2",
      date: "2025-12-16",
      title: "Experience & UI Improvements",
      items: [
        "Added notifications for Focus and Break times.",
        "Redesigned Settings UI for better usability.",
        "Added Feedback & Bug Report feature.",
        "Implemented Music Volume Control and Seek Bar.",
        "Added Shuffle and Repeat playback modes.",
        "Break time now displays a coffee icon ☕️.",
        "Improved track list scrolling and layout."
      ]
    },
    {
      version: "v1.0.1",
      date: "2025-12-09", 
      title: "YouTube Sync & Performance",
      items: [
        "Added YouTube Playlist Synchronization.",
        "Implemented Image Caching for faster loading.",
        "Enabled background playback when dashboard is closed.",
        "Added ability to create playlists within the app.",
        "Fixed issues with playlist resizing and stability."
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-[#FFFFFF] text-[#111111] relative overflow-hidden font-sans selection:bg-black selection:text-white">
      {/* Reusing ChromeOrb for consistent background ambiance, maybe styled differently or just consistent */}
      
      <Header />

      <main className="relative z-10 pt-32 md:pt-48 px-6 min-h-screen">
        <div className="max-w-3xl mx-auto">
          <div className="mb-16 text-center text-black">
            <Badge variant="outline" className="mb-6 border-black/10 text-black/60 px-4 py-1.5 text-sm backdrop-blur-md bg-white/50">
              What's New
            </Badge>
            <h1 className="font-serif text-5xl md:text-7xl font-bold tracking-tight mb-6">Changelog</h1>
            <p className="font-sans text-xl text-black/60 max-w-xl mx-auto">
              Follow our journey as we improve Rytmo with new features and enhancements.
            </p>
          </div>

          <div className="space-y-16 pb-32">
            {changes.map((change, idx) => (
              <div key={idx} className="relative">
                
                <div className="md:grid md:grid-cols-[1fr_2px_4fr] gap-8 md:gap-12 group">
                   {/* Date & Version */}
                   <div className="hidden md:flex flex-col items-end pt-2">
                      <span className="font-mono text-sm text-black/40 mb-1">{change.date}</span>
                      <span className="font-bold text-xl">{change.version}</span>
                   </div>

                   {/* Desktop Timeline Node */}
                   <div className="hidden md:flex flex-col items-center relative">
                      <div className="w-px h-full bg-black/10 group-last:bg-transparent absolute top-0"></div>
                      <div className="w-3 h-3 rounded-full bg-black border-4 border-white shadow-sm relative z-10 mt-3"></div>
                   </div>

                   {/* Content */}
                   <div className="bg-white/60 backdrop-blur-xl rounded-3xl p-8 border border-white/50 shadow-sm hover:shadow-md transition-all">
                      {/* Mobile Header */}
                      <div className="flex items-center gap-3 mb-4 md:hidden">
                        <Badge variant="secondary" className="bg-black text-white px-2 py-0.5 text-xs font-mono">{change.version}</Badge>
                        <span className="text-sm text-black/50 font-mono">{change.date}</span>
                      </div>

                      <h3 className="font-sans text-2xl font-bold mb-4">{change.title}</h3>
                      <ul className="space-y-3">
                        {change.items.map((item, i) => (
                          <li key={i} className="font-sans flex items-start gap-3 text-black/70 leading-relaxed">
                            <span className="mt-2 w-1.5 h-1.5 rounded-full bg-black/30 shrink-0"></span>
                            {item}
                          </li>
                        ))}
                      </ul>
                   </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>

      <footer className="py-12 px-6 bg-black text-white/40 border-t border-white/10 relative z-10">
        <div className="max-w-7xl mx-auto text-center">
            <p className="font-sans text-sm">© 2026 dievas. All rights reserved.</p>
        </div>
      </footer>
    </div>
  )
}
