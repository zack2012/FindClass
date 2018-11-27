//
//  InheritanceParser.swift
//  Basic
//
//  Created by zack on 2018/11/27.
//

import Foundation
import Basic

final class InheritanceParser {
    init() {}
    
    func parse(path: String, frameworkName: String = "") throws {
        self.frameworkName = frameworkName
        
        let result = try Process.popen(args: "otool", "-ov", path)
        let lines = try result.utf8Output().components(separatedBy: .newlines)
        
        for line in lines {
            switch state {
            case .idle:
                if line.hasPrefix("Contents of") && line.contains("(__DATA,__objc_classlist)") {
                    state = .parsingSelf
                }
            case .parsingSelf:
                if line.hasPrefix("Contents of") && !line.contains("(__DATA,__objc_classlist)") {
                    state = .idle
                    break
                }
                
                let range = NSRange(line.startIndex ..< line.endIndex, in: line)
                let r = InheritanceParser.regex.firstMatch(in: line, range: range)
                if r != nil, let classnameStart = line.range(of: "_OBJC_CLASS_$_") {
                    rawClassName = String(line[classnameStart.upperBound...])
                    state = .parsingSuper
                }
            case .parsingSuper:
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("superclass") {
                    let classnameStart = line.range(of: "_OBJC_CLASS_$_")!
                     rawParentName = String(line[classnameStart.upperBound...])
                    
                    makeClass()
                    
                    rawClassName = nil
                    rawParentName = nil
                    
                    state = .parsingSelf
                }
                break
            }
        }
    }
    
    func query(classname: String) -> Class? {
        return result[classname]
    }
    
    private func makeClass() {
        guard let classKey = rawClassName, let parentKey = rawParentName else {
            return
        }
        
        let clz = result[classKey]
        let parent = result[parentKey]

        switch (clz, parent) {
        case let (s?, p?):
            s.parent = p
            s.frameworkName = frameworkName
            p.append(child: s)
            break
        case let (nil, p?):
            // 父类已经存在，创建子类
            let newClass = Class(name: classKey, frameworkName: frameworkName, parent: parent)
            // 把子类添加进父类
            p.append(child: newClass)
            
            // 指向父类
            newClass.parent = p
            // 保存新的类
            result[classKey] = newClass
        case let (s?, nil):
            // 创建父类和子类
            let newParentClass = Class(name: parentKey)
            newParentClass.append(child: s)
            
            // 指向父类
            s.parent = newParentClass
            // 保存新的类
            result[parentKey] = newParentClass
            break
        case (nil, nil):
            // 创建父类和子类
            let newParentClass = Class(name: parentKey)
            let newClass = Class(name: classKey, frameworkName: frameworkName, parent: newParentClass)
            
            // 把子类添加进父类
            newParentClass.append(child: newClass)
            
            // 保存新的类
            result[classKey] = newClass
            result[parentKey] = newParentClass
        }
    }
    
    private var frameworkName: String = ""
    private var state: State = .idle
    private(set) var result: [String: Class] = [:]
    
    private var rawClassName: String?
    private var rawParentName: String?
    
    private static let regex = try! NSRegularExpression(pattern: "^[0-9]+")
    
    enum State {
        case idle
        case parsingSelf
        case parsingSuper
    }
}
