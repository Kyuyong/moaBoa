import SwiftUI

// MARK: - 섹션 카드

struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(.primary)
            content()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// MARK: - 경로 선택 행

struct PathPickerRow: View {
    let label: String
    @Binding var path: String
    let onPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Image(systemName: pathIcon)
                    .foregroundColor(pathExists ? .accentColor : .orange)
                    .frame(width: 16)
                Text(path.isEmpty ? "경로 미설정" : path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(path.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("변경") { onPick() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }

    private var pathExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    private var pathIcon: String {
        if path.isEmpty { return "folder.badge.questionmark" }
        return pathExists ? "folder.fill" : "folder.badge.minus"
    }
}

// MARK: - 폴더 구조 미리보기

struct FolderPreviewView: View {
    let items: [(indent: Int, name: String, isLast: Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]
                HStack(spacing: 0) {
                    ForEach(0..<item.indent, id: \.self) { _ in
                        Text("  ")
                            .font(.system(.caption, design: .monospaced))
                    }
                    Text(item.isLast ? "└── " : "├── ")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(" \(item.name)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - 날짜 포맷터

extension Date {
    var defaultProjectDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

// MARK: - 폴더 선택 헬퍼

func pickFolder(title: String = "폴더 선택", completion: @escaping (String) -> Void) {
    let panel = NSOpenPanel()
    panel.title = title
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
        completion(url.path)
    }
}
