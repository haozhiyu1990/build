//
//  configure.swift
//  configure
//
//  Created by 7080 on 2023/3/6.
//

import Foundation
import SwiftShell

class configure {
    class func config() {
        do {
            try runAndPrint(bash: "xcodebuild -scheme 'build' -configuration Release ARCHS=x86_64 TARGET_BUILD_DIR=./")
        } catch {
            print(error.localizedDescription)
        }
    }
}
