//
//  toolEx.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

import Foundation

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
