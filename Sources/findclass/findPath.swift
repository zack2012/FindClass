//
//  findPath.swift
//  Basic
//
//  Created by zack on 2018/11/27.
//

import Foundation
import Basic

final class FindPath {
    init(path: String) {
        self.path = path
        self.fileManager = FileManager.default
    }
    
    private let path: String
    private let fileManager: FileManager
    
    func getResults() throws -> [Item] {
        let root = try AbsolutePath(validating: path)
        let allPaths = try localFileSystem.getDirectoryContents(root).filter {
            let tempPath = root.appending(component: $0)
            // 只获取文件夹，注意Pods.xcodeproj也是文件夹，也需要过滤掉
            return tempPath.extension == nil && localFileSystem.isDirectory(tempPath)
        }.map { root.appending(component: $0).asString }
        
        let resourceKeys: [URLResourceKey] = [.creationDateKey]
        
        var r = [Item]()
        
        for path in allPaths {
            let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path).resolvingSymlinksInPath(),
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!

            for case let fileURL as URL in enumerator {
                let components = fileURL.pathComponents
                if components.count < 2 {
                    continue
                }

                if components[components.count - 2].hasSuffix(".framework") && components[components.count - 1] + ".framework" == components[components.count - 2] {
                    r .append(Item(path: fileURL.path, frameworkName: fileURL.lastPathComponent))
                }
            }
        }
     
        return r
    }
}

extension FindPath {
    struct Item: CustomStringConvertible {
        var path: String
        var frameworkName: String
        
        var description: String {
            return frameworkName + ": " + path
        }
    }
}
