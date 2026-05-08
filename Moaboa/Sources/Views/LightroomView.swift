import SwiftUI

struct LightroomView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var runController: RunController

    @State private var dateString = Date().defaultProjectDate
    @State private var projectName = ""
    @State private var photoSource: PhotoSource = .uploadFolder

    private let organizer = FileOrganizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 프로젝트 정보
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
                            TextField("촬영 이름 입력", text: $projectName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                // 저장 경로
                SectionCard(title: "저장 경로", systemImage: "folder") {
                    PathPickerRow(label: "프로젝트 저장 위치", path: $settings.lrSavePath) {
                        pickFolder(title: "저장 경로 선택") { path in
                            settings.lrSavePath = path
                        }
                    }
                }

                // 사진 소스
                SectionCard(title: "사진 소스", systemImage: "camera") {
                    VStack(spacing: 10) {
                        sourceOption(
                            source: .uploadFolder,
                            label: "업로드 폴더에서 가져오기",
                            icon: "folder.badge.plus"
                        )
                        if photoSource == .uploadFolder {
                            PathPickerRow(label: "업로드 폴더", path: $settings.lrUploadFolderPath) {
                                pickFolder(title: "업로드 폴더 선택") { path in
                                    settings.lrUploadFolderPath = path
                                }
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Divider()

                        sourceOption(
                            source: .canonCard,
                            label: "캐논 SD카드 직접 연결",
                            icon: "sdcard.fill"
                        )
                        if photoSource == .canonCard {
                            VStack(spacing: 8) {
                                PathPickerRow(label: "캐논 카드 경로", path: $settings.lrCanonPath) {
                                    pickFolder(title: "SD카드 경로 선택") { path in
                                        settings.lrCanonPath = path
                                    }
                                }
                                canonStatusView
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.3), value: photoSource)
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
        }
        .onChange(of: projectName) { newValue in
            runController.canRun = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - 소스 선택 라디오

    private func sourceOption(source: PhotoSource, label: String, icon: String) -> some View {
        Button {
            withAnimation { photoSource = source }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: photoSource == source ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(photoSource == source ? .accentColor : .secondary)
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

    // MARK: - 캐논 카드 상태

    private var canonStatusView: some View {
        let exists = FileManager.default.fileExists(atPath: settings.lrCanonPath)
        return HStack(spacing: 6) {
            Circle()
                .fill(exists ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(exists ? "카드 감지됨" : "카드 미연결")
                .font(.caption)
                .foregroundColor(exists ? .green : .orange)
            Spacer()
        }
    }

    // MARK: - 폴더 구조 미리보기

    private var previewView: some View {
        let root = projectName.isEmpty
            ? "\(dateString) [프로젝트명]"
            : "\(dateString) \(projectName)"
        let items: [(indent: Int, name: String, isLast: Bool)] = [
            (0, "Catalog", false),
            (0, "RAW", true),
        ]
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "folder.fill.badge.plus")
                    .foregroundColor(.yellow)
                Text(root)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
            }
            FolderPreviewView(items: items)
        }
    }

    // MARK: - 실행 로직

    private func runOrganize() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        withAnimation { runController.executionState = .loading }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try organizer.organizeLightroom(
                    date: dateString,
                    projectName: name,
                    savePath: settings.lrSavePath,
                    photoSource: photoSource,
                    canonPath: settings.lrCanonPath,
                    uploadFolderPath: settings.lrUploadFolderPath
                )

                DispatchQueue.main.async {
                    withAnimation {
                        if !result.success {
                            let msg = result.errors.first ?? "알 수 없는 오류"
                            runController.executionState = msg.contains("파일이 없습니다")
                                ? .warning(msg)
                                : .failure(msg)
                        } else if result.fileCount == 0 {
                            runController.executionState = .warning("소스 폴더에 사진 파일이 없습니다.")
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
    LightroomView()
        .environmentObject(AppSettings())
        .environmentObject(RunController())
        .frame(width: 600, height: 700)
}
