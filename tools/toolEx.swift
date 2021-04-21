//
//  toolEx.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

import Foundation

struct JsonError: Error {
    let message: String
}

extension String {
    func objectFromJSONString<T>(_ target: T.Type, _ parseOptions: JKParseOptionFlags) throws -> T {
        if String(describing: target).hasPrefix("Array") {
            guard let obj = NSString(string: self).objectFromJSONString(withParseOptions: UInt(parseOptions)) else {
                throw JsonError(message: "配置文件有误")
            }
            
            guard let array = obj as? T else {
                throw JsonError(message: "指定的数组类型不对")
            }
            
            return array
            
        } else if String(describing: target).hasPrefix("Dictionary") {
            guard let obj = NSString(string: self).objectFromJSONString(withParseOptions: UInt(parseOptions)) else {
                throw JsonError(message: "配置文件有误")
            }
            
            guard let dic = obj as? T else {
                throw JsonError(message: "指定的数组类型不对")
            }
            
            return dic
        } else {
            throw JsonError(message: "配置文件有误")
        }
    }
}

extension Dictionary {
    func jsonData() -> Data {
        let dic = self as NSDictionary
        return dic.jsonData()
    }
}

extension Date {
    var toString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
}
