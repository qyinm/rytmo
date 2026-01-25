import SwiftUI
import SwiftData

struct NotchExpandedView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var vm: NotchViewModel
    @EnvironmentObject var settings: PomodoroSettings
    
    @State private var showingSettings: Bool = false
    @State private var selectedTab: Int = 0
    @State private var dismissedError: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isLoggedIn {
                if showingSettings {
                    settingsContent
                } else {
                    mainContent
                }
            } else {
                loginContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 20)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black)
                .frame(height: 1)
        }
    }
    
    private var activeError: String? {
        let errors = [
            musicPlayer.errorMessage,
            authManager.errorMessage
        ].compactMap { $0 }
        
        guard let firstError = errors.first else { return nil }
        if firstError == dismissedError { return nil }
        return firstError
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if let error = activeError {
                ErrorBannerView(message: error) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dismissedError = error
                    }
                }
                .padding(.bottom, 8)
            }
            
            headerView
                .frame(height: 32)
                .padding(.top, 0)
                .padding(.bottom, 8)
            
            switch selectedTab {
            case 0:
                homeTabView
            case 1:
                musicTabView
            case 2:
                CalendarTabView()
            default:
                homeTabView
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var homeTabView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                CompactTimerView()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 240)

                CompactTodoView()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 240)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var musicTabView: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Playlists")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                NotchPlaylistListView()
            }
            .padding(16)
            .frame(width: 200, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            
            MenuBarMusicView()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var headerView: some View {
        HStack {
            // Tab Switcher
            HStack(spacing: 16) {
                Button(action: { selectedTab = 0 }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14))
                        .foregroundColor(selectedTab == 0 ? .white : .secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { selectedTab = 1 }) {
                    Image(systemName: "music.note")
                        .font(.system(size: 14))
                        .foregroundColor(selectedTab == 1 ? .white : .secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { selectedTab = 2 }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(selectedTab == 2 ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        showingSettings = true
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    authManager.signOut()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Compact Timer View (Square Layout)
    struct CompactTimerView: View {
        @EnvironmentObject var timerManager: PomodoroTimerManager
        @EnvironmentObject var settings: PomodoroSettings

        var body: some View {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                        .frame(width: 65, height: 65)

                    Circle()
                        .trim(from: 0, to: timerManager.session.progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: timerManager.session.progress)

                    Image(systemName: stateIcon)
                        .font(.system(size: 16))
                        .foregroundColor(progressColor)
                }
                .padding(.top, 4)

                VStack(spacing: 0) {
                    Text(timerManager.session.formattedTime)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Text(timerManager.session.state.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 3) {
                    ForEach(0..<settings.sessionsBeforeLongBreak, id: \.self) { index in
                        Circle()
                            .fill(index < timerManager.session.sessionCount ? progressColor : Color.gray.opacity(0.3))
                            .frame(width: 3.5, height: 3.5)
                    }
                }

                HStack(spacing: 12) {
                    compactControlButton(icon: "arrow.counterclockwise", size: 22) {
                        withAnimation { timerManager.reset() }
                    }

                    compactPlayButton(size: 32)

                    compactControlButton(icon: "forward.fill", size: 22) {
                        withAnimation { timerManager.skip() }
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }

        private var progressColor: Color {
            switch timerManager.session.state {
            case .idle: return .gray
            case .focus: return .red
            case .shortBreak: return .green
            case .longBreak: return .blue
            }
        }

        private var stateIcon: String {
            switch timerManager.session.state {
            case .idle: return "moon.zzz.fill"
            case .focus: return "flame.fill"
            case .shortBreak: return "cup.and.saucer.fill"
            case .longBreak: return "bed.double.fill"
            }
        }

        private func compactControlButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: size, height: size)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }

        private func compactPlayButton(size: CGFloat) -> some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if timerManager.session.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                }
            }) {
                Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(
                        Circle()
                            .fill(Color.black)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    struct CompactTodoView: View {
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]
        
        @State private var newTaskTitle: String = ""
        @State private var isAddingTask: Bool = false
        @FocusState private var isInputFocused: Bool

        private var incompleteCount: Int {
            todos.filter { !$0.isCompleted }.count
        }

        var body: some View {
            VStack(spacing: 6) {
                HStack {
                    Text("Tasks")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isAddingTask = true
                            isInputFocused = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.black))
                    }
                    .buttonStyle(.plain)

                    if incompleteCount > 0 {
                        Text("\(incompleteCount)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.black))
                    } else if !todos.isEmpty {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.black))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                if isAddingTask {
                    quickAddInput
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if todos.isEmpty && !isAddingTask {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black.opacity(0.2))
                                Text("No tasks")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                            .onTapGesture {
                                withAnimation {
                                    isAddingTask = true
                                    isInputFocused = true
                                }
                            }
                        } else {
                            ForEach(Array(todos.prefix(5).enumerated()), id: \.element.id) { index, todo in
                                CompactTodoRow(todo: todo)
                                
                                if index < min(todos.count, 5) - 1 {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.04))
                                        .frame(height: 0.5)
                                        .padding(.leading, 36)
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }
        
        private var quickAddInput: some View {
            HStack(spacing: 8) {
                TextField("New task...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .focused($isInputFocused)
                    .onSubmit {
                        createTask()
                    }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isAddingTask = false
                        newTaskTitle = ""
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 10)
        }
        
        private func createTask() {
            let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                withAnimation {
                    isAddingTask = false
                    newTaskTitle = ""
                }
                return
            }
            
            let maxIndex = todos.map { $0.orderIndex }.max() ?? 0
            let newTodo = TodoItem(title: trimmed)
            newTodo.orderIndex = maxIndex + 1
            
            modelContext.insert(newTodo)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                newTaskTitle = ""
                isAddingTask = false
            }
        }

        struct CompactTodoRow: View {
            let todo: TodoItem

            var body: some View {
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            todo.isCompleted.toggle()
                            todo.completedAt = todo.isCompleted ? Date() : nil
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(todo.isCompleted ? Color.white.opacity(0.8) : Color.white.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 18, height: 18)

                            if todo.isCompleted {
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text(todo.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(todo.isCompleted ? .secondary : .white)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
        }
    }

    // MARK: - Compact Playlist List for Notch
    struct NotchPlaylistListView: View {
        @EnvironmentObject var musicPlayer: MusicPlayerManager
        @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
        
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    if playlists.isEmpty {
                        Text("No playlists")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    } else {
                        ForEach(playlists) { playlist in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    musicPlayer.selectedPlaylist = playlist
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: playlist.themeColorHex))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(playlist.name)
                                        .font(.system(size: 12, weight: musicPlayer.selectedPlaylist?.id == playlist.id ? .bold : .medium))
                                        .foregroundColor(musicPlayer.selectedPlaylist?.id == playlist.id ? .white : .secondary)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(musicPlayer.selectedPlaylist?.id == playlist.id ? Color.white.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxHeight: 160)
        }
    }

    private var settingsContent: some View {
        VStack(spacing: 0) {
            settingsHeader

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    settingsTimerSection
                    settingsAppSection
                    settingsAccountSection
                    settingsDashboardButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    private var settingsHeader: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showingSettings = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 16, weight: .bold))
        }
        .padding(.bottom, 8)
    }

    private var settingsTimerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Timer Duration")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                CompactSettingRow(
                    title: "Focus Time",
                    value: $settings.focusDuration,
                    range: 1...60,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Short Break",
                    value: $settings.shortBreakDuration,
                    range: 1...30,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Long Break",
                    value: $settings.longBreakDuration,
                    range: 5...60,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Sessions until Long Break",
                    value: $settings.sessionsBeforeLongBreak,
                    range: 2...10,
                    unit: "sessions"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var settingsAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "app.badge")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("App Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    Text("Notifications")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    Toggle("", isOn: $settings.notificationsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var settingsAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    Text("Log out")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var settingsDashboardButton: some View {
        Button(action: {
            // Open dashboard
        }) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14))

                Text("See more in Dashboard")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var loginContent: some View {
        VStack(spacing: 24) {
            Image("RytmoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .cornerRadius(12)

            VStack(spacing: 8) {
                Text("Welcome to Rytmo")
                    .font(.system(size: 20, weight: .bold))
                Text("Login to sync your focus sessions and tasks")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: {
                    Task { await authManager.signInWithGoogle() }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView().controlSize(.small).scaleEffect(0.8)
                        } else {
                            Image(systemName: "g.circle.fill")
                        }
                        Text("Continue with Google")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                Button(action: {
                    Task { await authManager.signInAnonymously() }
                }) {
                    Text("Start Anonymously")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
            }
        }
        .padding(.vertical, 40)
    }
}
