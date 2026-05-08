import SwiftUI

// MARK: - 실행 상태

enum ExecutionState {
    case idle
    case loading
    case success
    case warning(String)
    case failure(String)
}

// MARK: - 체크마크 애니메이션

struct CheckmarkView: View {
    @State private var trimEnd: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 60, height: 60)
            Circle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: 60, height: 60)
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(trimEnd)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: trimEnd)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                trimEnd = 1
            }
        }
    }
}

// MARK: - 경고/실패 아이콘

struct AlertIconView: View {
    let isWarning: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill((isWarning ? Color.orange : Color.red).opacity(0.15))
                .frame(width: 60, height: 60)
            Circle()
                .stroke(isWarning ? Color.orange : Color.red, lineWidth: 2)
                .frame(width: 60, height: 60)
            Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "xmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isWarning ? .orange : .red)
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

// MARK: - 파일 목록 슬라이드

struct FileListView: View {
    let files: [String]
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.secondary)
                Text("이동된 파일 (\(files.count)개)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(files, id: \.self) { file in
                        HStack(spacing: 8) {
                            Image(systemName: fileIcon(for: file))
                                .foregroundColor(.accentColor)
                                .frame(width: 16)
                            Text(file)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        Divider().padding(.leading, 36)
                    }
                }
            }
            .frame(maxHeight: 160)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }

    private func fileIcon(for file: String) -> String {
        let ext = (file as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mts", "m2ts": return "film"
        case "cr2", "cr3", "raw", "nef", "arw": return "camera.aperture"
        case "jpg", "jpeg", "png": return "photo"
        case "mp3", "wav", "aif": return "music.note"
        default: return "doc"
        }
    }
}

// MARK: - 피드백 오버레이

struct FeedbackOverlay: View {
    let state: ExecutionState
    let files: [String]
    let onReset: () -> Void

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
                Text("실행 중...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

        case .success:
            VStack(spacing: 16) {
                CheckmarkView()
                Text("완료!")
                    .font(.headline)
                    .foregroundColor(.green)
                if !files.isEmpty {
                    FileListView(files: files)
                }
                resetButton
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

        case .warning(let msg):
            VStack(spacing: 12) {
                AlertIconView(isWarning: true)
                    .modifier(ShakeEffect(animatableData: shakeOffset))
                Text(msg)
                    .font(.callout)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                resetButton
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .onAppear { triggerShake() }

        case .failure(let msg):
            VStack(spacing: 12) {
                AlertIconView(isWarning: false)
                    .modifier(ShakeEffect(animatableData: shakeOffset))
                Text(msg)
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                resetButton
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .onAppear { triggerShake() }
        }
    }

    private var resetButton: some View {
        Button("다시 시작") {
            onReset()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func triggerShake() {
        withAnimation(.easeInOut(duration: 0.5)) {
            shakeOffset = 1
        }
    }
}
