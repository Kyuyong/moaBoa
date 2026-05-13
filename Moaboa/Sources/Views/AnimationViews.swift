import SwiftUI

// MARK: - 실행 상태

struct CopyProgressState {
    let current: Int
    let total: Int
    let fileName: String
    let sourceIcon: String
}

enum ExecutionState {
    case idle
    case loading
    case copying(CopyProgressState)
    case success
    case warning(String)
    case failure(String)
}

// MARK: - 복사 진행 애니메이션 (Mac Finder 스타일)

struct CopyProgressView: View {
    let progress: CopyProgressState
    @State private var phase: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let iconY: CGFloat = h * 0.42
                let labelY: CGFloat = iconY + 22
                let leftX: CGFloat = 32
                let rightX: CGFloat = w - 32
                let docStart: CGFloat = leftX + 26
                let docEnd: CGFloat = rightX - 26
                let docX = docStart + CGFloat(phase) * (docEnd - docStart)
                let docY = iconY - sin(CGFloat(phase) * .pi) * 20
                let fade = min(1.0, phase / 0.12) * min(1.0, (1.0 - phase) / 0.12)

                // 소스 아이콘
                Image(systemName: progress.sourceIcon)
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
                    .position(x: leftX, y: iconY)
                Text("소스")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: leftX, y: labelY)

                // 대상 폴더 아이콘
                Image(systemName: "folder.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
                    .position(x: rightX, y: iconY)
                Text("대상")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: rightX, y: labelY)

                // 날아가는 파일 아이콘
                Image(systemName: "doc.fill")
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                    .shadow(color: .blue.opacity(0.35), radius: 5)
                    .position(x: docX, y: docY)
                    .opacity(fade)
            }
            .frame(height: 76)

            VStack(spacing: 6) {
                ProgressView(value: Double(progress.current), total: Double(max(progress.total, 1)))
                    .progressViewStyle(.linear)
                    .tint(.blue)
                HStack(spacing: 6) {
                    Image(systemName: "doc")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(progress.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text("\(progress.current) / \(progress.total)개")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
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
                Text("복사된 파일 (\(files.count)개)")
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

        case .copying(let p):
            CopyProgressView(progress: p)
                .padding(.vertical, 8)

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
