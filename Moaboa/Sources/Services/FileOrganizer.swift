import Foundation

enum VideoSource {
    case actionCam
    case uploadFolder
}

enum PhotoSource {
    case canonCard
    case uploadFolder
}

struct OrganizeResult {
    let createdFolders: [String]
    let movedFiles: [String]
    let errors: [String]

    var success: Bool { errors.isEmpty }
    var fileCount: Int { movedFiles.count }
}

class FileOrganizer {
    private let fm = FileManager.default

    // MARK: - Final Cut Pro

    func organizeFCP(
        date: String,
        projectName: String,
        savePath: String,
        videoSource: VideoSource,
        actionCamPath: String,
        uploadFolderPath: String,
        onProgress: ((Int, Int, String) -> Void)? = nil
    ) throws -> OrganizeResult {
        let projectRoot = (savePath as NSString).appendingPathComponent("\(date) \(projectName)")
        let libraryFolder = (projectRoot as NSString).appendingPathComponent("1. Library")
        let bundlePath = (libraryFolder as NSString).appendingPathComponent("\(projectName).fcpbundle")

        var createdFolders: [String] = []
        var movedFiles: [String] = []
        var errors: [String] = []

        // 폴더 생성
        for folder in fcpFolders(root: projectRoot, projectName: projectName) {
            do {
                try fm.createDirectory(atPath: folder, withIntermediateDirectories: true)
                createdFolders.append(folder)
            } catch {
                errors.append("폴더 생성 실패: \(folder)")
            }
        }

        // FCP 라이브러리 번들 내부 구조 생성
        createLibraryBundle(bundlePath: bundlePath)

        // 소스 경로 결정
        let sourcePath: String
        switch videoSource {
        case .actionCam:
            sourcePath = actionCamPath
        case .uploadFolder:
            sourcePath = uploadFolderPath
        }

        // 영상 파일을 2. RAW 폴더로 이동
        let rawFolder = (projectRoot as NSString).appendingPathComponent("2. RAW")
        let videoExtensions: Set<String> = ["mp4", "mov", "avi", "mts", "m2ts",
                                            "MP4", "MOV", "AVI", "MTS", "M2TS"]

        if fm.fileExists(atPath: sourcePath) {
            let files = (try? fm.contentsOfDirectory(atPath: sourcePath)) ?? []
            var videoFiles = files.filter { videoExtensions.contains(($0 as NSString).pathExtension) }

            // 업로드 폴더인 경우 프로젝트 날짜와 파일 생성일이 일치하는 파일만 포함
            if videoSource == .uploadFolder, let projectDate = parseDate(date) {
                videoFiles = videoFiles.filter { file in
                    let src = (sourcePath as NSString).appendingPathComponent(file)
                    guard let attrs = try? fm.attributesOfItem(atPath: src),
                          let creationDate = attrs[.creationDate] as? Date else { return false }
                    return Calendar.current.isDate(creationDate, inSameDayAs: projectDate)
                }
            }

            if videoFiles.isEmpty && errors.isEmpty {
                errors.append("소스 폴더에 영상 파일이 없습니다.")
            }

            for (idx, file) in videoFiles.enumerated() {
                let src = (sourcePath as NSString).appendingPathComponent(file)
                let dst = (rawFolder as NSString).appendingPathComponent(file)
                onProgress?(idx + 1, videoFiles.count, file)
                do {
                    try fm.copyItem(atPath: src, toPath: dst)
                    movedFiles.append(file)
                } catch {
                    errors.append("파일 복사 실패: \(file)")
                }
            }
        } else if errors.isEmpty {
            errors.append("소스 경로를 찾을 수 없습니다: \(sourcePath)")
        }

        return OrganizeResult(createdFolders: createdFolders, movedFiles: movedFiles, errors: errors)
    }

    // fcpbundle 내부의 FCP 이벤트 구조 + 프로젝트 폴더
    private func fcpFolders(root: String, projectName: String) -> [String] {
        let r = root as NSString
        let bundle = (r.appendingPathComponent("1. Library") as NSString)
                        .appendingPathComponent("\(projectName).fcpbundle") as NSString
        return [
            // FCP 이벤트 (.fcpevent 확장자 포함, Original Media 서브폴더)
            bundle.appendingPathComponent("1. Source/Original Media"),
            bundle.appendingPathComponent("2. Project/Original Media"),
            bundle.appendingPathComponent("3. Image/Original Media"),
            bundle.appendingPathComponent("4. Music/Original Media"),
            // 프로젝트 레벨 폴더
            r.appendingPathComponent("2. RAW"),
            r.appendingPathComponent("3. Export"),
        ]
    }

    // FCP 라이브러리 번들 초기화 — 디렉토리 구조만 생성, DB는 FCP가 직접 초기화
    private func createLibraryBundle(bundlePath: String) {
        createLibrarySettings(bundlePath: bundlePath)
    }

    // FCP가 번들을 인식하기 위한 최소 Settings.plist
    private func createLibrarySettings(bundlePath: String) {
        let plistPath = (bundlePath as NSString).appendingPathComponent("Settings.plist")
        guard !fm.fileExists(atPath: plistPath) else { return }
        let plist: [String: Any] = ["FFLibraryFormatVersion": 1]
        if let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            fm.createFile(atPath: plistPath, contents: data)
        }
    }

    // MARK: - Lightroom

    func organizeLightroom(
        date: String,
        projectName: String,
        savePath: String,
        photoSource: PhotoSource,
        canonPath: String,
        uploadFolderPath: String,
        onProgress: ((Int, Int, String) -> Void)? = nil
    ) throws -> OrganizeResult {
        let projectRoot = (savePath as NSString).appendingPathComponent("\(date) \(projectName)")
        let folders = lrFolders(root: projectRoot)

        var createdFolders: [String] = []
        var movedFiles: [String] = []
        var errors: [String] = []

        for folder in folders {
            do {
                try fm.createDirectory(atPath: folder, withIntermediateDirectories: true)
                createdFolders.append(folder)
            } catch {
                errors.append("폴더 생성 실패: \(folder)")
            }
        }

        let sourcePath: String
        switch photoSource {
        case .canonCard:
            sourcePath = canonPath
        case .uploadFolder:
            sourcePath = uploadFolderPath
        }

        let rawDestFolder = (projectRoot as NSString).appendingPathComponent("2. RAW")
        let photoExtensions = ["raw", "cr2", "cr3", "nef", "arw", "orf", "RAF",
                               "RAW", "CR2", "CR3", "NEF", "ARW", "ORF",
                               "jpg", "jpeg", "JPG", "JPEG"]

        if fm.fileExists(atPath: sourcePath) {
            let files = (try? fm.contentsOfDirectory(atPath: sourcePath)) ?? []
            let photoFiles = files.filter { file in
                photoExtensions.contains((file as NSString).pathExtension)
            }

            if photoFiles.isEmpty && errors.isEmpty {
                errors.append("소스 폴더에 사진 파일이 없습니다.")
            }

            for (idx, file) in photoFiles.enumerated() {
                let src = (sourcePath as NSString).appendingPathComponent(file)
                let dst = (rawDestFolder as NSString).appendingPathComponent(file)
                onProgress?(idx + 1, photoFiles.count, file)
                do {
                    try fm.copyItem(atPath: src, toPath: dst)
                    movedFiles.append(file)
                } catch {
                    errors.append("파일 복사 실패: \(file)")
                }
            }
        } else if errors.isEmpty {
            errors.append("소스 경로를 찾을 수 없습니다: \(sourcePath)")
        }

        return OrganizeResult(createdFolders: createdFolders, movedFiles: movedFiles, errors: errors)
    }

    private func lrFolders(root: String) -> [String] {
        let p = root as NSString
        return [
            p.appendingPathComponent("1. Catalog"),
            p.appendingPathComponent("2. RAW"),
        ]
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }

    func detectVolumes() -> [String] {
        let volumes = (try? fm.contentsOfDirectory(atPath: "/Volumes")) ?? []
        return volumes.filter { !$0.hasPrefix(".") }
    }

    func folderExists(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
