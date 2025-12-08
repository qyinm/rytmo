import Combine
import Sparkle

// MVVM 패턴에 맞춰 ObservableObject로 만듭니다.
final class UpdateManager: ObservableObject {
    private let controller: SPUStandardUpdaterController
    
    init() {
        // Sparkle의 표준 컨트롤러 초기화
        // startingUpdater: true로 설정하면 앱 시작 시 자동으로 체크 로직이 돕니다.
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    // 메뉴바에서 "업데이트 확인"을 눌렀을 때 호출할 함수
    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
