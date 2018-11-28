//
//  Class.swift
//  Basic
//
//  Created by zack on 2018/11/27.
//
import Basic

final class Class {
    weak var parent: Class?
    var name: String
    var children: [Class]
    var frameworkName: String?

    private var set: Set<Class>
    
    init(name: String, frameworkName: String? = nil,
         parent: Class? = nil, children: [Class] = []) {
        self.name = name
        self.frameworkName = frameworkName
        self.parent = parent
        self.children = children
        self.set = Set(children)
    }
    
    func append(child: Class) {
        if set.contains(child) {
            return
        }
        
        set.insert(child)
        children.append(child)
    }
    
    func getChildrenCount() -> Int {
        var count = 0
        
        func getChildrenCount(_ ch: Class, count: inout Int) {
            count += 1
            for ch in ch.children {
                getChildrenCount(ch, count: &count)
            }
        }
        
        getChildrenCount(self, count: &count)
        
        return count - 1
    }
}

extension Class: Hashable {
    static func == (lhs: Class, rhs: Class) -> Bool {
        // Objectice-C没有命名空间，只要类名相等就代表两个类相等
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Class: CustomStringConvertible {
    func output(_ stream: OutputByteStream, level: Int) {
        
        for _ in stride(from: 0, to: level - 1, by: 1) {
            stream <<< "\t"
        }
        
        if level > 0 {
            stream <<< "|---"
        }
        
        if children.isEmpty {
            if let framework = frameworkName, !framework.isEmpty {
                stream <<< name <<< "(" <<< framework <<< ")" <<< "\n"
            } else {
                stream <<< name <<< "\n"
            }
        } else {
            if let framework = frameworkName, !framework.isEmpty {
                stream <<< name <<< "(" <<< (frameworkName ?? "") <<< ")" <<< ": \n"
            } else {
                stream <<< name <<< ": \n"
            }
            
            for child in children {
                child.output(stream, level: level + 1)
            }
        }
    }
    
    func outputByFramework(_ stream: OutputByteStream) {
        stream <<< "按framework输出: \n"
        var map = [String: [Class]]()
        
        func makeMap(map: inout [String: [Class]], clz: Class) {
            insertClass(clz, map: &map)
            for child in clz.children {
                makeMap(map: &map, clz: child)
            }
        }
        
        makeMap(map: &map, clz: self)
        
        let sortedKey = map.keys.sorted()
        for key in sortedKey {
            let clzs = map[key]!
            let sortedClzs = clzs.sorted { $0.name < $1.name }
            stream <<< key <<< "(\(sortedClzs.count)): \n"
            for clz in sortedClzs {
                stream <<< "\t" <<< clz.name <<< "\n"
            }
        }
    }
    
    private func insertClass(_ clz: Class, map: inout [String: [Class]]) {
        if let key = clz.frameworkName {
            let array = map[key]
            if array == nil {
                map[key] = Array()
                map[key]?.append(clz)
            } else {
                map[key]?.append(clz)
            }
        }
    }
    
    var description: String {
        let stream = BufferedOutputByteStream()
        output(stream, level: 0)
        return stream.bytes.asString!
    }
}
