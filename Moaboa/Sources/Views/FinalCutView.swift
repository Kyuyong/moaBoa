import SwiftUI

struct FinalCutView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var runController: RunController

    @State private var dateString = Date().defaultProjectDate
    @State private var projectName = ""
    @State private var videoSource: VideoSource = .uploadFolder
    @State private var detectedVolumes: [String] = []

    private let organizer = FileOrganizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 날짜 & 프로젝트명
                SectionCard(title: "프로젝트 정보", systemImage: "info.circle") {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("날짜")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("YYYY-MM-DD", text: $dateString)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 130)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("프로젝트명")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("프로젝트 이름 입력", text: $projectName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                // 저장 경로
                SectionCard(title: "저장 경로", systemImage: "folder") {
                    PathPickerRow(label: "프로젝트 저장 위치", path: $settings.fcpSavePath) {
                        pickFolder(title: "저장 경로 선택") { path in
                            settings.fcpSavePath = path
                        }
                    }
                }

                // 영상 소스
                SectionCard(title: "영상 소스", systemImage: "video") {
                    VStack(spacing: 10) {
                        sourceOption(
                            source: .uploadFolder,
                            label: "업로드 폴더에서 가져오기",
                            icon: "folder.badge.plus"
                        )
                        if videoSource == .uploadFolder {
                            PathPickerRow(label: "업로드 폴더", path: $settings.fcpUploadFolderPath) {
                                pickFolder(title: "업로드 폴더 선택") { path in
                                    settings.fcpUploadFolderPath = path
                                }
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Divider()

                        sourceOption(
                            source: .actionCam,
                            label: "액션캠 직접 연결",
                            icon: "camera.fill"
                        )
                        if videoSource == .actionCam {
                            VStack(spacing: 8) {
                                PathPickerRow(label: "액션캠 경로", path: $settings.fcpActionCamPath) {
                                    pickFolder(title: "액션캠 경로 선택") { path in
                                        settings.fcpActionCamPath = path
                                    }
                                }
                                detectedVolumesView
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3), value: videoSource)
                }

                // 폴더 구조 미리보기
                SectionCard(title: "생성될 폴더 구조", systemImage: "square.stack.3d.down.right") {
                    previewView
                }
            }
            .padding(20)
        }
        .onAppear {
            dateString = Date().defaultProjectDate
            runController.runAction = runOrganize
            runController.canRun = !projectName.trimmingCharacters(in: .whitespaces).isEmpty
            // 볼륨 감지를 백그라운드에서 실행 (메인 스레드 블로킹 방지)
            DispatchQueue.global(qos: .background).async {
                let volumes = organizer.detectVolumes()
                DispatchQueue.main.async { detectedVolumes = volumes }
            }
        }
        .onChange(of: projectName) { newValue in
            runController.canRun = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - 소스 선택 라디오

    private func sourceOption(source: VideoSource, label: String, icon: String) -> some View {
        Button {
            withAnimation { videoSource = source }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: videoSource == source ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(videoSource == source ? .accentColor : .secondary)
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 감지된 볼륨

    private var detectedVolumesView: some View {
        Group {
            if !detectedVolumes.isEmpty {
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("감지된 볼륨: \(detectedVolumes.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - 폴더 구조 미리보기

    private var previewView: some View {
        let label = projectName.isEmpty ? "[프로젝트명]" : projectName
        let root = "\(dateString) \(label)"
        let bundleName = "\(label).fcpbundle"
        let events = ["1. Source", "2. Project", "3. Image", "4. Music"]

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill.badge.plus").foregroundColor(.yellow)
                Text(root)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                // 1. Library
                previewRow(prefix: "├── ", icon: "folder.fill", color: .yellow, name: "1. Library")
                // └── bundleName.fcpbundle
                previewRow(prefix: "│   └── ", icon: "square.stack.3d.up.fill", color: .blue, name: bundleName)
                // 이벤트들
                ForEach(events.indices, id: \.self) { ei in
                    let isLast = ei == events.count - 1
                    previewRow(
                        prefix: isLast ? "│       └── " : "│       ├── ",
                        icon: "film.stack", color: .purple,
                        name: events[ei]
                    )
                    previewRow(
                        prefix: isLast ? "│           └── " : "│       │   └── ",
                        icon: "folder", color: .secondary,
                        name: "Original Media"
                    )
                }
                // 2. RAW / 3. Export
                previewRow(prefix: "├── ", icon: "folder.fill", color: .yellow, name: "2. RAW")
                previewRow(prefix: "└── ", icon: "folder.fill", color: .yellow, name: "3. Export")
            }
            .padding(10)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func previewRow(prefix: String, icon: String, color: Color, name: String) -> some View {
        HStack(spacing: 0) {
            Text(prefix)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(" \(name)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(color == .secondary ? .secondary : .primary)
            Spacer()
        }
    }

    // MARK: - 실행 로직

    private func runOrganize() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        withAnimation { runController.executionState = .loading }

        let sourceIcon = videoSource == .actionCam ? "camera.fill" : "folder.badge.plus"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try organizer.organizeFCP(
                    date: dateString,
                    projectName: name,
                    savePath: settings.fcpSavePath,
                    videoSource: videoSource,
                    actionCamPath: settings.fcpActionCamPath,
                    uploadFolderPath: settings.fcpUploadFolderPath
                ) { current, total, fileName in
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            runController.executionState = .copying(CopyProgressState(
                                current: current,
                                total: total,
                                fileName: fileName,
                                sourceIcon: sourceIcon
                            ))
                        }
                    }
                }

                DispatchQueue.main.async {
                    withAnimation {
                        if !result.success {
                            let msg = result.errors.first ?? "알 수 없는 오류"
                            runController.executionState = msg.contains("파일이 없습니다")
                                ? .warning(msg)
                                : .failure(msg)
                        } else if result.fileCount == 0 {
                            runController.executionState = .warning("소스 폴더에 영상 파일이 없습니다.")
                        } else {
                            runController.movedFiles = result.movedFiles
                            runController.executionState = .success
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation {
                        runController.executionState = .failure(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    FinalCutView()
        .environmentObject(AppSettings())
        .environmentObject(RunController())
        .frame(width: 600, height: 700)
}
