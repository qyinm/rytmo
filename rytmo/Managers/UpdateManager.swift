import Combine
import Sparkle

// Make it an ObservableObject according to the MVVM pattern.
@MainActor
final class UpdateManager: ObservableObject {
    private var controller: SPUStandardUpdaterController?
    private var hasStartedUpdater = false
    
    init() {}

    func startUpdaterIfNeeded() {
        guard !hasStartedUpdater else { return }

        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        controller.updater.automaticallyChecksForUpdates = true
        self.controller = controller
        hasStartedUpdater = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.controller?.updater.checkForUpdatesInBackground()
        }
    }
    
    // Function to call when 'Check for Updates' is pressed in the menubar
    func checkForUpdates() {
        startUpdaterIfNeeded()
        controller?.updater.checkForUpdates()
    }
}
