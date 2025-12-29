import Combine
import Sparkle

// Make it an ObservableObject according to the MVVM pattern.
final class UpdateManager: ObservableObject {
    private let controller: SPUStandardUpdaterController
    
    init() {
        // Initialize Sparkle's standard controller
        // Setting startingUpdater to true automatically runs the check logic when the app starts.
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Automatically check for updates every time the app runs
        controller.updater.automaticallyChecksForUpdates = true
        controller.updater.checkForUpdatesInBackground()
    }
    
    // Function to call when 'Check for Updates' is pressed in the menubar
    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
