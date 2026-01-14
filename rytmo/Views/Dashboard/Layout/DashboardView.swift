import SwiftUI
import SwiftData
import FirebaseAuth
import YouTubePlayerKit

enum DashboardSelection: Hashable {
    case home
    case calendar
    case calendarSettings
    case tasks
    case allPlaylists
    case playlist(Playlist)
    case settings
}

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
    
    @State private var selection: DashboardSelection? = .home
    @State private var isPlaylistExpanded: Bool = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        HStack(spacing: 0) {
            if columnVisibility == .detailOnly {
                SideRailView(selection: $selection)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            UserProfileImage(size: 32)
                            
                            if let user = authManager.currentUser {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.isAnonymous ? "Guest" : (user.email ?? "User"))
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                }
                            } else {
                                Text("Guest")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Menu")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 4)
                            
                            Button {
                                selection = .home
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selection == .home ? "house.fill" : "house")
                                        .font(.system(size: 14))
                                    Text("Home")
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selection == .home ? Color.primary.opacity(0.1) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                selection = .calendar
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selection == .calendar ? "calendar.circle.fill" : "calendar")
                                        .font(.system(size: 14))
                                    Text("Calendar")
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selection == .calendar ? Color.primary.opacity(0.1) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                selection = .tasks
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selection == .tasks ? "checklist.checked" : "checklist")
                                        .font(.system(size: 14))
                                    Text("Tasks")
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selection == .tasks ? Color.primary.opacity(0.1) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            DisclosureGroup(isExpanded: $isPlaylistExpanded) {
                                VStack(spacing: 2) {
                                    ForEach(playlists.prefix(5)) { playlist in
                                        Button {
                                            selection = .playlist(playlist)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "music.note.list")
                                                    .font(.system(size: 14))
                                                Text(playlist.name)
                                                    .font(.system(size: 14))
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selection == .playlist(playlist) ? Color.primary.opacity(0.1) : Color.clear)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    if playlists.count > 5 {
                                        Button {
                                            selection = .allPlaylists
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.system(size: 14))
                                                Text("More...")
                                                    .font(.system(size: 14))
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selection == .allPlaylists ? Color.primary.opacity(0.1) : Color.clear)
                                            )
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.leading, 8) 
                            } label: {
                                Button {
                                    selection = .allPlaylists
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 14))
                                        Text("Playlists")
                                            .font(.system(size: 14))
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selection == .allPlaylists ? Color.primary.opacity(0.1) : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .foregroundStyle(.primary)
                            .accentColor(.primary)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Button {
                            selection = .settings
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: selection == .settings ? "gearshape.fill" : "gearshape")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                Text("Settings")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == .settings ? Color.accentColor : Color.clear)
                        )
                    .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                    }
                }
                
            } detail: {
                VStack(spacing: 0) {
                    switch selection {
                    case .home, .none:
                        HomeView()
                    case .calendar:
                        DashboardCalendarView()
                    case .tasks:
                        DashboardTodoView()
                    case .allPlaylists:
                        PlaylistView(onSelect: { playlist in
                            selection = .playlist(playlist)
                        })
                    case .playlist(let playlist):
                        PlaylistDetailView(playlist: playlist, onBack: {
                            selection = .allPlaylists
                        })
                        .id(playlist.id)
                        
                    case .settings:
                        DashboardSettingsView()
                            .environmentObject(authManager)
                    case .calendarSettings:
                        CalendarSettingsView()
                    }
                    
                    MusicPlayerBar()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("switchToCalendarSettings"))) { _ in
            selection = .settings
            UserDefaults.standard.set(2, forKey: "lastSettingsTab")
        }
    }
}
