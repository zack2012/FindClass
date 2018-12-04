//
//  main.swift
//  findName
//
//  Created by zack on 2018/11/27.
//

import Foundation
import Basic
import Utility

// swift build -c=release -Xswiftc -static-stdlib

enum MainError: Error, CustomStringConvertible {
    case string(_ message: String)
    
    var description: String {
        switch self {
        case .string(let msg):
            return msg
        }
    }
}

let usage = """
[options] 类名 库所在的路径

例如：
findclass UIView /path/to/Pods
findclass -d=false UIView /path/to/Binary
"""

do {
    // 解析参数
    let argumentParser = ArgumentParser(usage: usage, overview: "查找一个类的所有子类")
    let clzArgument = argumentParser.add(positional: "className", kind: String.self, optional: false, usage: "输入类名，区分大小写")
    let pathArgument = argumentParser.add(positional: "path", kind: String.self, optional: false, usage: "库所在的路径")
    let isDirArgument = argumentParser.add(option: "--directory", shortName: "-d", kind: Bool.self, usage: "是否是Pods文件夹路径")
    let isPrintObjectiveCDict = argumentParser.add(option: "--ObjectiveCDict", shortName: "-ocd", kind: Bool.self, usage: "输出Objectice-C字典格式")
    let parsedResult = try argumentParser.parse(Array(CommandLine.arguments.dropFirst()))
    
    let path = parsedResult.get(pathArgument)!
    let clzName = parsedResult.get(clzArgument)!
    let isDir = parsedResult.get(isDirArgument) ?? true
    let isPrintObjectiveC = parsedResult.get(isPrintObjectiveCDict) ?? false
    
    let parser = InheritanceParser()
    if isDir {
        // 查找路径下的所有二进制库文件
        let fp = FindPath(path: path)
        let paths = try fp.getResults()
        
        stdoutStream <<< "路径查找完成, 开始解析库文件...\n"
        stdoutStream.flush()
        
        for item in paths {
            try parser.parse(path: item.path, frameworkName: item.frameworkName)
        }
    } else {
        try parser.parse(path: path)
    }
    
    if let clz = parser.query(classname: clzName) {
        clz.output(stdoutStream, level: 0)
        stdoutStream <<< "该类一共有\(clz.getChildrenCount())个子类" <<< "\n"
        clz.outputByFramework(stdoutStream)
        
        if isPrintObjectiveC {
            clz.outputObjecticeCDictionary(stdoutStream)
        }
        
        stdoutStream.flush()
    } else {
        throw MainError.string("没有查询到该类，可能路径输入的不对、类名输入错误或没有该类")
    }
    
} catch let error as PathValidationError {
    stderrStream <<< error.description <<< "\n"
} catch let error as MainError {
    stderrStream <<< error.description <<< "\n"
} catch let error as ArgumentParserError {
    stderrStream <<< error.description <<< "\n"
} catch {
    stderrStream <<< error.localizedDescription <<< "\n"
}

stderrStream.flush()
