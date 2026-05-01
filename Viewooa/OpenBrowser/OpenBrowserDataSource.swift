import Foundation

enum OpenBrowserDataSource {
    static func loadEntries(in directory: URL, sortOption: OpenBrowserSortOption, ascending: Bool) throws -> [OpenBrowserEntry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .localizedNameKey, .contentModificationDateKey, .fileSizeKey, .typeIdentifierKey],
            options: [.skipsHiddenFiles]
        )

        let entries: [OpenBrowserEntry] = urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .localizedNameKey, .contentModificationDateKey, .fileSizeKey, .typeIdentifierKey])
            let isDirectory = values?.isDirectory == true
            guard isDirectory || SupportedImageTypes.isBrowsableImage(url) else { return nil }
            return OpenBrowserEntry(
                url: url,
                name: values?.localizedName ?? url.lastPathComponent,
                isDirectory: isDirectory,
                modificationDate: values?.contentModificationDate,
                fileSize: values?.fileSize ?? 0,
                typeIdentifier: values?.typeIdentifier
            )
        }

        return entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }

            let comparison: ComparisonResult
            switch sortOption {
            case .name:
                comparison = lhs.name.localizedStandardCompare(rhs.name)
            case .kind:
                comparison = lhs.kindTitle.localizedStandardCompare(rhs.kindTitle)
            case .dateModified:
                comparison = (lhs.modificationDate ?? .distantPast).compare(rhs.modificationDate ?? .distantPast)
            case .size:
                comparison = lhs.fileSize == rhs.fileSize ? .orderedSame : (lhs.fileSize < rhs.fileSize ? .orderedAscending : .orderedDescending)
            }

            if comparison == .orderedSame {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    static func validDirectory(_ url: URL) -> URL? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else { return nil }
        return url
    }
}
