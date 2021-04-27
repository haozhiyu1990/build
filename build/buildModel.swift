//
//  buildModel.swift
//  build
//
//  Created by 7080 on 2021/4/21.
//

import Foundation

struct Model: Codable {
    var productPath: String
    var teamID: String
    var productScheme: String?
    var productName: String?
    var productConfiguration: String
    var isHasPod: Bool?
    var provisioningProfiles: [Profile]?
}

struct Profile: Codable {
    var profileName: String
    var BundleId: String
}
