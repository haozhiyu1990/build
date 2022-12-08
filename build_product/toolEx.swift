//
//  toolEx.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

import Foundation
import SwiftyJSON

extension Dictionary {
    func jsonData() throws -> Data {
        try JSON(self).rawData()
    }
}

extension Date {
    var toString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
}
