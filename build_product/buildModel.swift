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
    var signingMethod: String?
    var productName: String?
    var productConfiguration: String?
    var isHasPod: Bool?
    var provisioningProfiles: [Profile]?
    var _api_key: String
    var dingtalkWebhook: String?
}

struct Profile: Codable {
    var profileName: String
    var BundleId: String
}

struct IpaModel: Codable {
    var data: IpaModelData
}

struct IpaModelData: Codable {
    var buildName: String
    var buildVersion: String
    var buildBuildVersion: String
    var buildShortcutUrl: String
    var buildQRCodeURL: String
}

struct DingDingModel: Codable {
    var errcode: Int
    var errmsg: String
}
