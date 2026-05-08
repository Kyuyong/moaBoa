import Foundation
import Combine

class AppSettings: ObservableObject {

    // MARK: - Final Cut Pro
    @Published var fcpSavePath: String {
        didSet { UserDefaults.standard.set(fcpSavePath, forKey: "fcpSavePath") }
    }
    @Published var fcpUploadFolderPath: String {
        didSet { UserDefaults.standard.set(fcpUploadFolderPath, forKey: "fcpUploadFolderPath") }
    }
    @Published var fcpActionCamPath: String {
        didSet { UserDefaults.standard.set(fcpActionCamPath, forKey: "fcpActionCamPath") }
    }
    @Published var fcpCanonPath: String {
        didSet { UserDefaults.standard.set(fcpCanonPath, forKey: "fcpCanonPath") }
    }

    // MARK: - Lightroom
    @Published var lrSavePath: String {
        didSet { UserDefaults.standard.set(lrSavePath, forKey: "lrSavePath") }
    }
    @Published var lrUploadFolderPath: String {
        didSet { UserDefaults.standard.set(lrUploadFolderPath, forKey: "lrUploadFolderPath") }
    }
    @Published var lrCanonPath: String {
        didSet { UserDefaults.standard.set(lrCanonPath, forKey: "lrCanonPath") }
    }

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        fcpSavePath = UserDefaults.standard.string(forKey: "fcpSavePath") ?? "\(home)/Movies"
        fcpUploadFolderPath = UserDefaults.standard.string(forKey: "fcpUploadFolderPath") ?? "\(home)/Downloads"
        fcpActionCamPath = UserDefaults.standard.string(forKey: "fcpActionCamPath") ?? "/Volumes/ActionCam"
        fcpCanonPath = UserDefaults.standard.string(forKey: "fcpCanonPath") ?? "/Volumes/EOS_DIGITAL/DCIM/100CANON"

        lrSavePath = UserDefaults.standard.string(forKey: "lrSavePath") ?? "\(home)/Pictures"
        lrUploadFolderPath = UserDefaults.standard.string(forKey: "lrUploadFolderPath") ?? "\(home)/Downloads"
        lrCanonPath = UserDefaults.standard.string(forKey: "lrCanonPath") ?? "/Volumes/EOS_DIGITAL/DCIM/100CANON"
    }
}

// MARK: - RunController
// 헤더 플레이 버튼과 각 탭의 실행 로직을 연결하는 공유 컨트롤러
class RunController: ObservableObject {
    @Published var executionState: ExecutionState = .idle
    @Published var movedFiles: [String] = []
    @Published var canRun: Bool = false

    var runAction: (() -> Void)?

    func run() {
        runAction?()
    }

    func reset() {
        executionState = .idle
        movedFiles = []
    }

    var isLoading: Bool {
        if case .loading = executionState { return true }
        return false
    }

    var showsFeedback: Bool {
        switch executionState {
        case .idle, .loading: return false
        default: return true
        }
    }
}
