import SwiftUI

enum AppTab: String, CaseIterable {
    case finalCut = "Final Cut Pro"
    case lightroom = "Lightroom"

    var icon: String {
        switch self {
        case .finalCut: return "film.stack"
        case .lightroom: return "camera.aperture"
        }
    }

    var accentColor: Color {
        switch self {
        case .finalCut: return .blue
        case .lightroom: return .purple
        }
    }
}

struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var runController = RunController()
    @State private var selectedTab: AppTab = .finalCut

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabBar
            Divider()

            // 피드백 영역: 성공/경고/실패 시 탭 바 아래에 슬라이드
            if runController.showsFeedback {
                feedbackStrip
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
            }

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 680, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .environmentObject(settings)
        .environmentObject(runController)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: runController.showsFeedback)
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.title2)
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            VStack(alignment: .leading, spacing: 1) {
                Text("Moaboa")
                    .font(.title3)
                    .fontWeight(.bold)
                HStack(spacing: 5) {
                    Text("모아보아 · 파일 정리 자동화")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("v1.2")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Spacer()
            playButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - 플레이 버튼 (항상 고정)

    private var playButton: some View {
        Button {
            runController.run()
        } label: {
            ZStack {
                if runController.isLoading {
                    ProgressView()
                        .scaleEffect(0.65)
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .disabled(runController.isLoading || !runController.canRun)
        .help(runController.canRun ? "실행" : "프로젝트명을 입력하세요")
    }

    // MARK: - 피드백 스트립

    private var feedbackStrip: some View {
        FeedbackOverlay(
            state: runController.executionState,
            files: runController.movedFiles
        ) {
            withAnimation { runController.reset() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - 탭 바

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: tab.icon)
                        .font(.callout)
                    Text(tab.rawValue)
                        .font(.callout)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .foregroundColor(isSelected ? tab.accentColor : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Rectangle()
                    .fill(isSelected ? tab.accentColor : Color.clear)
                    .frame(height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 탭 컨텐츠

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .finalCut:
            FinalCutView()
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .id(AppTab.finalCut)
        case .lightroom:
            LightroomView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(AppTab.lightroom)
        }
    }
}

#Preview {
    ContentView()
}
