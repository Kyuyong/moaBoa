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
        uploadFolderPath: String
    ) throws -> OrganizeResult {
        let projectRoot = (savePath as NSString).appendingPathComponent("\(date) \(projectName)")
        let bundlePath = (projectRoot as NSString).appendingPathComponent("\(projectName).fcpbundle")

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

        // FCP가 인식할 수 있는 Settings.plist 생성
        createLibrarySettings(bundlePath: bundlePath)

        // 소스 경로 결정
        let sourcePath: String
        switch videoSource {
        case .actionCam:
            sourcePath = actionCamPath
        case .uploadFolder:
            sourcePath = uploadFolderPath
        }

        // 영상 파일을 RAW 폴더로 이동
        let rawFolder = (projectRoot as NSString).appendingPathComponent("RAW")
        let videoExtensions: Set<String> = ["mp4", "mov", "avi", "mts", "m2ts",
                                            "MP4", "MOV", "AVI", "MTS", "M2TS"]

        if fm.fileExists(atPath: sourcePath) {
            let files = (try? fm.contentsOfDirectory(atPath: sourcePath)) ?? []
            let videoFiles = files.filter { videoExtensions.contains(($0 as NSString).pathExtension) }

            if videoFiles.isEmpty && errors.isEmpty {
                errors.append("소스 폴더에 영상 파일이 없습니다.")
            }

            for file in videoFiles {
                let src = (sourcePath as NSString).appendingPathComponent(file)
                let dst = (rawFolder as NSString).appendingPathComponent(file)
                do {
                    try fm.moveItem(atPath: src, toPath: dst)
                    movedFiles.append(file)
                } catch {
                    errors.append("파일 이동 실패: \(file)")
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
        let bundle = r.appendingPathComponent("\(projectName).fcpbundle") as NSString
        return [
            // FCP 이벤트 (각 이벤트 안에 Original Media 포함)
            bundle.appendingPathComponent("1. Source.fcpevent/Original Media"),
            bundle.appendingPathComponent("2. Project.fcpevent/Original Media"),
            bundle.appendingPathComponent("3. Image.fcpevent/Original Media"),
            bundle.appendingPathComponent("4. Music.fcpevent/Original Media"),
            // 프로젝트 레벨 폴더
            r.appendingPathComponent("RAW"),
            r.appendingPathComponent("Export"),
        ]
    }

    // FCP가 라이브러리를 인식하기 위한 최소 Settings.plist 생성
    private func createLibrarySettings(bundlePath: String) {
        let plistPath = (bundlePath as NSString).appendingPathComponent("Settings.plist")
        guard !fm.fileExists(atPath: plistPath) else { return }

        let plist: [String: Any] = [
            "FFLibraryFormatVersion": 1,
            "FFCreatedBy": "Moaboa"
        ]
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
        uploadFolderPath: String
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

        let rawDestFolder = (projectRoot as NSString).appendingPathComponent("RAW")
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

            for file in photoFiles {
                let src = (sourcePath as NSString).appendingPathComponent(file)
                let dst = (rawDestFolder as NSString).appendingPathComponent(file)
                do {
                    try fm.moveItem(atPath: src, toPath: dst)
                    movedFiles.append(file)
                } catch {
                    errors.append("파일 이동 실패: \(file)")
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
            p.appendingPathComponent("Catalog"),
            p.appendingPathComponent("RAW"),
        ]
    }

    // MARK: - Helpers

    func detectVolumes() -> [String] {
        let volumes = (try? fm.contentsOfDirectory(atPath: "/Volumes")) ?? []
        return volumes.filter { !$0.hasPrefix(".") }
    }

    func folderExists(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
