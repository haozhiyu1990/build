//
//  build.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

import Foundation

class build {
    var arguments: [String]
    var workingSpace: String = ""
    var configPath: String = ""
    var checkoutPath: String = ""
    var archivePath: String = ""
    var changedLogPath: String = ""
    var buildErrLogPath: String = ""
    var ipaPath: String = ""
    var buildName: String = ""
    var commitMsg: String = ""
    var commitMsgs: [String] = []
    var configModel: Model!

    class func arguments(_ arguments: [String]) {
        let builder = build(arguments: arguments)
        builder.work()
    }
    
    init(arguments: [String]) {
        self.arguments = arguments
//        var pointer: [Int8] = []
//        getcwd(&pointer, 2048)
//        workingSpace = String(cString: &pointer)
        workingSpace = run(bash: "cd ~; pwd").stdout
    }
    
    func work() {
        printLog()
        
        checkaArguments()
    }
    
    func checkConfigModel(_ exprot: Bool) {
        if Files.fileExists(atPath: configModel.productPath) {
            var productUrl = URL(fileURLWithPath: configModel.productPath)
            switch productUrl.pathExtension {
            case "xcodeproj":
                productUrl.deletePathExtension()
                configModel.productName = productUrl.pathComponents.last
                if configModel.productScheme == nil {
                    configModel.productScheme = configModel.productName
                }
                productUrl.deleteLastPathComponent()
                configModel.productPath = productUrl.path
                configModel.isHasPod = false
            case "xcworkspace":
                productUrl.deletePathExtension()
                configModel.productName = productUrl.pathComponents.last
                if configModel.productScheme == nil {
                    configModel.productScheme = configModel.productName
                }
                productUrl.deleteLastPathComponent()
                configModel.productPath = productUrl.path
                configModel.isHasPod = true
            case "":
                guard let contents = try? Files.contentsOfDirectory(atPath: productUrl.path) else {
                    log.shared.red.line("[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                    echoErrLog(err: "[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                    run(bash: "open -R \(configPath)")
                    return
                }
                
                var xcodeprojs = contents.filter { $0.hasSuffix(".xcodeproj") }
                xcodeprojs = xcodeprojs.filter { $0 != "Pods.xcodeproj" }
                var xcworkspaces = contents.filter { $0.hasSuffix(".xcworkspace") }
                
                if contents.count == 0 || xcodeprojs.count == 0 {
                    log.shared.red.line("[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                    echoErrLog(err: "[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                    run(bash: "open -R \(configPath)")
                    return
                }
                if xcodeprojs.count > 1 {
                    log.shared.red.line("[!] ???????????? productPath ???????????????????????????????????????????????????????????????\(configPath + "/buildConfig")??????")
                    echoErrLog(err: "[!] ???????????? productPath ???????????????????????????????????????????????????????????????\(configPath + "/buildConfig")??????")
                    run(bash: "open -R \(configPath)")
                    return
                }
                
                let xcodeprojName = xcodeprojs.first!.components(separatedBy: ".xcodeproj").first!
                xcworkspaces = xcworkspaces.filter { $0 == "\(xcodeprojName).xcworkspace" }
                
                configModel.productName = xcodeprojName
                if configModel.productScheme == nil {
                    configModel.productScheme = configModel.productName
                }
                
                if xcworkspaces.count == 1 {
                    configModel.isHasPod = true
                } else {
                    configModel.isHasPod = false
                }
                
                configModel.productPath = productUrl.path
            default:
                log.shared.red.line("[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                echoErrLog(err: "[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
                run(bash: "open -R \(configPath)")
                return
            }
        }
        
        if configModel.productName == nil || configModel.productScheme == nil || configModel.isHasPod == nil {
            log.shared.red.line("[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
            echoErrLog(err: "[!] ???????????? productPath ????????????????????????\(configPath + "/buildConfig")??????")
            run(bash: "open -R \(configPath)")
            return
        }
        
        if configModel.signingMethod == nil {
            configModel.signingMethod = "development"
        }
        
        if configModel.productConfiguration == nil {
            configModel.productConfiguration = "Release"
        }
        
        checkoutPath = configModel.productPath + "/autoBuild/\(Date().toString)"
        creatExortConfig()
        
        if exprot {
            if ipaPath.count > 0 {
                uploadFir()
                return
            }
            exportArchive()
        } else {
            startBuild()
        }
    }
    
    func saveChangLog(_ log: String) {
        guard let change = try? open(forWriting: changedLogPath, overwrite: true) else { return }
        change.write(log)
        change.close()
    }
    
    func readChangLog() -> String {
        guard let change = try? String(contentsOfFile: changedLogPath, encoding: .utf8) else {
            return ""
        }
        return change
    }
    
    func startBuild() {
        changedLogPath = configPath + "/\(configModel.productName!)_change.log"
        buildErrLogPath = configPath + "/\(configModel.productName!)_build_error.log"
        let changeLog = readChangLog()
        
        do {
            run(bash: "cd \(configModel.productPath); git fetch origin")
            let branchsStr = run(bash: "cd \(configModel.productPath); git branch").stdout
            let branchs = branchsStr.components(separatedBy: "\n").filter { $0.hasPrefix("*") }
            if var branch = branchs.first {
                branch = String(branch.suffix(from: branch.index(branch.startIndex, offsetBy: 2)))
                var commitMsgsStr = run(bash: "cd \(configModel.productPath); git log \(branch)..origin/\(branch)").stdout
                if changeLog.count > 0 {
                    if commitMsgsStr.count > 0 {
                        commitMsgsStr = commitMsgsStr + "\n"
                    }
                    commitMsgsStr = commitMsgsStr + changeLog
                }
                
                if commitMsgsStr.count > 0 {
                    saveChangLog(commitMsgsStr)
                    commitMsgs = commitMsgsStr.components(separatedBy: "commit ").compactMap { item -> String? in
                        if item.count == 0 || item.contains("\nMerge: ") {
                            return nil
                        }
                        return item
                    }
                    commitMsgs = commitMsgs.reversed().enumerated().compactMap { (index, item) -> String? in
                        let msgs = item.components(separatedBy: "\n\n")
                        if msgs.count > 1, msgs[1].trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                            return "\(index+1). "+msgs[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        return nil
                    }
                    commitMsg = commitMsgs.map({ $0.replacingOccurrences(of: "\n    ", with: "\n---- ")}).joined(separator: "\n")
                    commitMsgs = commitMsgs.map { $0.replacingOccurrences(of: "\n    ", with: "  \n> ")}
                    commitMsgs = commitMsgs.map { $0.replacingOccurrences(of: "\"", with: "'")}
                }
            }
            try runAndPrint(bash: "cd \(configModel.productPath); git pull")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild clean")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild archive -\(configModel.isHasPod! ? "workspace" : "project") \(configModel.productName!).\(configModel.isHasPod! ? "xcworkspace" : "xcodeproj") -scheme \(configModel.productScheme!) -configuration \(configModel.productConfiguration!) -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild -exportArchive -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive -exportPath \(checkoutPath) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            uploadFir()
        } catch let error as CommandError {
            log.shared.red.line(error.description)
            echoErrLog(err: error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
            echoErrLog(err: error.localizedDescription)
        }
    }
    
    func exportArchive() {
        var archiveUrl = URL(fileURLWithPath: archivePath)
        archiveUrl.deleteLastPathComponent()
        checkoutPath = archiveUrl.path
        
        do {
            try runAndPrint(bash: "xcodebuild -exportArchive -archivePath \(archivePath) -exportPath \(checkoutPath) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            uploadFir()
        } catch let error as CommandError {
            log.shared.red.line(error.description)
            echoErrLog(err: error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
            echoErrLog(err: error.localizedDescription)
        }
    }
    
    func uploadFir() {
        if ipaPath.count == 0 {
            if Files.fileExists(atPath: checkoutPath) {
                var ipaUrl = URL(fileURLWithPath: checkoutPath)
                let contents = try! Files.contentsOfDirectory(atPath: ipaUrl.path)
                let ipas = contents.filter { $0.hasSuffix(".ipa") }
                if ipas.count == 0 {
                    return
                }
                ipaUrl.appendPathComponent(ipas.first!)
                
                let uploadFirDataString = run(bash: "curl -F 'file=@\(ipaUrl.path)' -F '_api_key=\(configModel._api_key)' -F 'buildUpdateDescription=\(commitMsg)' https://www.pgyer.com/apiv2/app/upload").stdout
                guard let uploadFirData = uploadFirDataString.data(using: .utf8) else {
                    log.shared.red.line("???????????????????????????")
                    log.shared.red.line(uploadFirDataString)
                    echoErrLog(err: "???????????????????????????")
                    return
                }
                ipaUrl.deleteLastPathComponent()
                ipaUrl.deleteLastPathComponent()
                if Files.fileExists(atPath: ipaUrl.path) {
                    run(bash: "rm -r \(ipaUrl.path)")
                }
                if Files.fileExists(atPath: "\(configPath)/ExportOptions.plist") {
                    run(bash: "rm \(configPath)/ExportOptions.plist")
                }
                do {
                    let ipaModel = try JSONDecoder().decode(IpaModel.self, from: uploadFirData)
                    log.shared.green.line("?????????????????????")
                    if let dingtalkWebhook = configModel.dingtalkWebhook, dingtalkWebhook.count > 0 {
                        var text = ""
                        if commitMsgs.count > 0 {
                            text = """
                                ### ????????????<br/>
                                ![?????????](\(ipaModel.data.buildQRCodeURL))<br/>
                                #### \(ipaModel.data.buildName) iOS \(ipaModel.data.buildVersion)(build \(ipaModel.data.buildBuildVersion))????????????????????????????????????**????????????**???[????????????](https://www.pgyer.com/\(ipaModel.data.buildShortcutUrl))<br/>
                                #### ?????????????????????????????????<br/>
                                \(commitMsgs.joined(separator: "  \n"))
                                """
                        } else {
                            text = """
                                ### ????????????<br/>
                                ![?????????](\(ipaModel.data.buildQRCodeURL))<br/>
                                #### \(ipaModel.data.buildName) iOS \(ipaModel.data.buildVersion)(build \(ipaModel.data.buildBuildVersion))????????????????????????????????????**????????????**???[????????????](https://www.pgyer.com/\(ipaModel.data.buildShortcutUrl))
                                """
                        }
                        let result = run(bash: "curl '\(dingtalkWebhook)' -H 'Content-Type: application/json' -d '{\"msgtype\": \"markdown\", \"markdown\": {\"title\":\"[?????????]\", \"text\": \"\(text)\"}, \"at\": {\"isAtAll\": true}}'").stdout
                        guard let resultDate = result.data(using: .utf8) else {
                            log.shared.red.line("?????????????????????????????????")
                            log.shared.red.line(result)
                            echoErrLog(err: "?????????????????????????????????")
                            return
                        }
                        let dingdingModel = try JSONDecoder().decode(DingDingModel.self, from: resultDate)
                        if dingdingModel.errcode != 0 {
                            log.shared.red.line("?????????????????????????????????")
                            log.shared.red.line(dingdingModel.errmsg)
                            echoErrLog(err: "?????????????????????????????????")
                            return
                        }
                    }
                    if Files.fileExists(atPath: changedLogPath) {
                        run(bash: "rm \(changedLogPath)")
                    }
                    if Files.fileExists(atPath: buildErrLogPath) {
                        run(bash: "rm \(buildErrLogPath)")
                    }
                } catch let error as CommandError {
                    log.shared.red.line(error.description)
                    echoErrLog(err: error.description)
                } catch {
                    log.shared.red.line(error.localizedDescription)
                    echoErrLog(err: error.localizedDescription)
                }
            }
        } else {
            let uploadFirDataString = run(bash: "curl -F 'file=@\(ipaPath)' -F '_api_key=\(configModel._api_key)' -F 'buildUpdateDescription=\(commitMsg)' https://www.pgyer.com/apiv2/app/upload").stdout
            guard let uploadFirData = uploadFirDataString.data(using: .utf8) else {
                log.shared.red.line("???????????????????????????")
                log.shared.red.line(uploadFirDataString)
                echoErrLog(err: "???????????????????????????")
                return
            }
            do {
                let ipaModel = try JSONDecoder().decode(IpaModel.self, from: uploadFirData)
                log.shared.green.line("?????????????????????")
                if let dingtalkWebhook = configModel.dingtalkWebhook, dingtalkWebhook.count > 0 {
                    var text = ""
                    if commitMsgs.count > 0 {
                        text = """
                            ### ????????????<br/>
                            ![?????????](\(ipaModel.data.buildQRCodeURL))<br/>
                            #### \(ipaModel.data.buildName) iOS \(ipaModel.data.buildVersion)(build \(ipaModel.data.buildBuildVersion))????????????????????????????????????**????????????**???[????????????](https://www.pgyer.com/\(ipaModel.data.buildShortcutUrl))<br/>
                            #### ?????????????????????????????????<br/>
                            \(commitMsgs.joined(separator: "  \n"))
                            """
                    } else {
                        text = """
                            ### ????????????<br/>
                            ![?????????](\(ipaModel.data.buildQRCodeURL))<br/>
                            #### \(ipaModel.data.buildName) iOS \(ipaModel.data.buildVersion)(build \(ipaModel.data.buildBuildVersion))????????????????????????????????????**????????????**???[????????????](https://www.pgyer.com/\(ipaModel.data.buildShortcutUrl))
                            """
                    }
                    let result = run(bash: "curl '\(dingtalkWebhook)' -H 'Content-Type: application/json' -d '{\"msgtype\": \"markdown\", \"markdown\": {\"title\":\"[?????????]\", \"text\": \"\(text)\"}, \"at\": {\"isAtAll\": true}}'").stdout
                    guard let resultDate = result.data(using: .utf8) else {
                        log.shared.red.line("?????????????????????????????????")
                        log.shared.red.line(result)
                        echoErrLog(err: "?????????????????????????????????")
                        return
                    }
                    let dingdingModel = try JSONDecoder().decode(DingDingModel.self, from: resultDate)
                    if dingdingModel.errcode != 0 {
                        log.shared.red.line("?????????????????????????????????")
                        log.shared.red.line(dingdingModel.errmsg)
                        echoErrLog(err: "?????????????????????????????????")
                        return
                    }
                }
                if Files.fileExists(atPath: buildErrLogPath) {                
                    run(bash: "rm \(buildErrLogPath)")
                }
            } catch let error as CommandError {
                log.shared.red.line(error.description)
                echoErrLog(err: error.description)
            } catch {
                log.shared.red.line(error.localizedDescription)
                echoErrLog(err: error.localizedDescription)
            }
        }
    }
    
    func analysisConfig(_ config: String,_ exprot: Bool) {
        // ?????????
        var configArr = config.components(separatedBy: "\n").compactMap { (item) -> String? in
            if item.contains("#") {
                return item.components(separatedBy: "#").first
            }
            return item
        }
        var configStr = configArr.joined(separator: "\n")
        
        // ????????????(" ')??????????????? =
        configArr = configStr.components(separatedBy: "'").enumerated().map { (idx, value) -> String in
            if idx % 2 == 1 {
                let newValue = value.replacingOccurrences(of: "=", with: "???")
                return newValue.replacingOccurrences(of: " ", with: "*")
            }
            return value
        }
        configStr = configArr.joined(separator: "'")
        configArr = configStr.components(separatedBy: "\"").enumerated().map { (idx, value) -> String in
            if idx % 2 == 1 {
                let newValue = value.replacingOccurrences(of: "=", with: "???")
                return newValue.replacingOccurrences(of: " ", with: "*")
            }
            return value
        }
        configStr = configArr.joined(separator: "\"")
            
        // ?????? " '
        configStr = configStr.replacingOccurrences(of: "'", with: "")
        configStr = configStr.replacingOccurrences(of: "\"", with: "")
        
        // ???????????????????????? ????????????
        configArr = configStr.components(separatedBy: " ").filter { $0.count != 0 }
        configStr = configArr.joined(separator: " ")
        
        // ???????????????????????? ????????????
        configArr = configStr.components(separatedBy: "\n").compactMap { (item) -> String? in
            if item.count == 0 || item == " " {
                return nil
            }
            return item.trimmingCharacters(in: .whitespaces)
        }
        
        configStr = configArr.joined(separator: "\n")
        
        configArr = configStr.components(separatedBy: "\nend")
        configArr = configArr.filter { $0.contains("product \(buildName) do") }
        if configArr.count != 1 {
            log.shared.red.line("[!] ??????????????????????????????\(configPath + "/buildConfig")??????")
            echoErrLog(err: "[!] ??????????????????????????????\(configPath + "/buildConfig")??????")
            run(bash: "open -R \(configPath)")
            return
        }
        
        configStr = configArr.first!.replacingOccurrences(of: " ", with: "")
        configStr = configStr.replacingOccurrences(of: "[", with: "")
        configStr = configStr.replacingOccurrences(of: "]", with: "")
        configStr = configStr.replacingOccurrences(of: "),\n(", with: "),(")
        configArr = configStr.components(separatedBy: "\n")
        configArr = configArr.filter { $0.contains("=") }
        
        var keys = [String]()
        var values = [Any]()
        
        for item in configArr {
            keys.append(item.components(separatedBy: "=").first!)
            values.append(item.components(separatedBy: "=").last!)
        }
        
        keys = keys.compactMap { (item) -> String? in
            if item.count == 0 {
                return nil
            }
            let new = item.replacingOccurrences(of: "*", with: " ")
            return new.replacingOccurrences(of: "???", with: "=")
        }
        values = values.compactMap { (item) -> Any? in
            if let strItem = item as? String {
                if strItem.count == 0 {
                    return nil
                }
                if strItem.hasPrefix("(") {
                    let newArr = strItem.components(separatedBy: "),").compactMap { (item) -> String? in
                        if item.count == 0 {
                            return nil
                        }
                        let newItem = item.replacingOccurrences(of: "(", with: "")
                        return newItem.replacingOccurrences(of: ")", with: "")
                    }
                    
                    var newObjArr = [Any]()
                    for obj in newArr {
                        var objKeys = [String?]()
                        var objValues = [String?]()
                        
                        for subObj in obj.components(separatedBy: ",") {
                            objKeys.append(subObj.components(separatedBy: ":").first)
                            objValues.append(subObj.components(separatedBy: ":").last)
                        }
                        
                        let newKeys = objKeys.compactMap { key -> String? in
                            if let newKey = key?.replacingOccurrences(of: "*", with: " ") {
                                return newKey.replacingOccurrences(of: "???", with: "=")
                            }
                            return nil
                        }
                        let newValues = objValues.compactMap { value -> String? in
                            if let newValue = value?.replacingOccurrences(of: "*", with: " ") {
                                return newValue.replacingOccurrences(of: "???", with: "=")
                            }
                            return nil
                        }
                        newObjArr.append(Dictionary(uniqueKeysWithValues: zip(newKeys, newValues)))
                    }
                    return newObjArr
                }
                let new = strItem.replacingOccurrences(of: "*", with: " ")
                return new.replacingOccurrences(of: "???", with: "=")
            }
            return nil
        }
        
        let jsonData = Dictionary(uniqueKeysWithValues: zip(keys, values)).jsonData()
        guard let model = try? JSONDecoder().decode(Model.self, from: jsonData) else {
            log.shared.red.line("[!] ??????????????????????????????\(configPath + "/buildConfig")??????")
            echoErrLog(err: "[!] ??????????????????????????????\(configPath + "/buildConfig")??????")
            run(bash: "open -R \(configPath)")
            return
        }
        configModel = model
        checkConfigModel(exprot)
    }
    
    func checkaArguments() {
        if arguments.count < 2 {
            help()
        } else {
            implementCommand(arguments[1])
        }
    }
    
    func creatConfig() {
        if Files.fileExists(atPath: configPath + "/buildConfig") {
            return
        }
        
        guard let stream = try? open(forWriting: configPath + "/buildConfig", overwrite: true) else { return }
        stream.write("""
            #!/usr/bin/ruby -w
            # ???????????????????????????????????? product 'xxx' do ... end
                        
            product 'xxx' do
                # productPath\t\t\t\t ?????????????????????
                # productScheme\t\t\t\t ???????????????Scheme
                # productConfiguration\t\t ??????????????? configuration  ????????? Release ???  Debug
                # teamID\t\t\t\t\t ??????????????? teamID
                # signingMethod\t\t\t\t ????????????????????? ad-hoc development app-store
                # provisioningProfiles\t\t ??????????????????????????????????????????????????????????????????
                # _api_key\t\t\t\t\t ?????????api key
                # dingtalkWebhook\t\t\t ???????????????????????????Webhook??????
            
                productPath = 'xxx'\t  # ?????????
                #productScheme = 'xxx'\t  # productScheme??????????????????, ????????????productScheme???????????????????????????????????????, ????????????
                #productConfiguration = 'Debug'\t  # ????????? Release
                teamID = 'xxx'\t  # ?????????
                #signingMethod = 'ad-hoc'    # ?????????  development
                _api_key = 'xxx'\t  # ?????????
                # ???????????????????????????Webhook??????????????????????????????????????????
                #dingtalkWebhook = 'xxx'

                # ???????????????target e.g. [(BundleId: 'bundleid1', profileName: 'name1'), (BundleId: 'bundleid2', profileName: 'name2')]
                #provisioningProfiles = [(BundleId: 'xxx', profileName: 'xxx')]
            end
            """)
        stream.close()
    }
    
    func creatExortConfig() {
        guard let plist = try? open(forWriting: configPath + "/ExportOptions.plist", overwrite: true) else { return }
        if let profiles = configModel.provisioningProfiles {
            var profilesStr = ""
            for item in profiles {
                profilesStr += """
                            <key>\(item.BundleId)</key>
                            <string>\(item.profileName)</string>
                            
                            """
            }
            profilesStr = profilesStr.trimmingCharacters(in: .whitespacesAndNewlines)
            plist.write("""
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>destination</key>
                    <string>export</string>
                    <key>method</key>
                    <string>\(configModel.signingMethod!)</string>
                    <key>provisioningProfiles</key>
                    <dict>
                        \(profilesStr)
                    </dict>
                    <key>signingStyle</key>
                    <string>manual</string>
                    <key>stripSwiftSymbols</key>
                    <true/>
                    <key>teamID</key>
                    <string>\(configModel.teamID)</string>
                    <key>thinning</key>
                    <string>&lt;none&gt;</string>
                </dict>
                </plist>

                """)
        } else {
            plist.write("""
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>destination</key>
                    <string>export</string>
                    <key>method</key>
                    <string>\(configModel.signingMethod!)</string>
                    <key>signingStyle</key>
                    <string>automatic</string>
                    <key>stripSwiftSymbols</key>
                    <true/>
                    <key>teamID</key>
                    <string>\(configModel.teamID)</string>
                    <key>thinning</key>
                    <string>&lt;none&gt;</string>
                </dict>
                </plist>

                """)
        }
        
        plist.close()
    }
    
    func implementCommand(_ command: String) {
        configPath = workingSpace + "/.auto-build-product"
        
        switch command {
        case "init":
            if arguments.count == 2 {
                creatConfig()
            } else {
                log.shared.red.word("???????????????")
                log.shared.green.word("\(command)")
                log.shared.red.line("?")
                help()
            }
        case "export":
            if Files.fileExists(atPath: configPath + "/buildConfig") {
                guard let config = try? String(contentsOfFile: configPath + "/buildConfig", encoding: .utf8) else {
                    log.shared.red.line("[!] ???????????? init ")
                    help()
                    return
                }
                
                if arguments.count == 4, arguments[2] == "-p" {
                    archivePath = arguments[3]
                    buildName = URL(fileURLWithPath: archivePath).deletingPathExtension().pathComponents.last!
                    analysisConfig(config, true)
                    return
                }
                
                if arguments.count == 6, arguments[2] == "-u", arguments[4] == "-t" {
                    ipaPath = arguments[3]
                    buildName = arguments[5]
                    analysisConfig(config, true)
                    return
                }
                
                if arguments.count == 4, arguments[2] == "-m" {
                    buildName = arguments[3]
                    analysisConfig(config, false)
                } else {
                    log.shared.red.word("???????????????")
                    log.shared.green.word("\(command)")
                    log.shared.red.line("?")
                    help()
                }
            } else {
                log.shared.red.line("[!] ???????????? init ")
                help()
            }
        case "--help":
            help()
        default:
            log.shared.red.word("[!] Unknown command?????????????????????: `\(command)` ???????????? ")
            log.shared.word("$ ")
            log.shared.green.line("build --help")
            echoErrLog(err: "[!] Unknown command?????????????????????: `\(command)` ???????????? $ build --help")
        }
    }
    
    func printLog() {
//        log.shared.windowSize(24, 115)
        
        log.shared.green.line("")
        log.shared.green.line("")
        log.shared.green.line("")
        log.shared.green.line("                   __           _   __      __")
        log.shared.green.line("                  / /   __ __  (_) / /  _._/ /")
        log.shared.green.line("                 / _ \\ / // / / / / /_ / _  /")
        log.shared.green.line("                /_.__/ \\_,_/ /_/ /_._/ \\_,_/")
        log.shared.green.line("")
        log.shared.green.line("")
        log.shared.green.line("")
        log.shared.green.line("")
    }
    
    func help() {
        log.shared.underline.line("Usage:")
        log.shared.line("")
        log.shared.word("\t$")
        log.shared.green.line(" build COMMAND")
        log.shared.line("")
        log.shared.line("\t  build, ?????????????????????, ???????????????????????????")
        log.shared.line("")
        log.shared.underline.line("Commands:")
        log.shared.line("")
        log.shared.green.word("\t+ init")
        log.shared.line("\t?????????????????? BuildConfig ??????")
        log.shared.line("")
        log.shared.green.line("\t+ export [-m, -p, -u, -t]")
        log.shared.line("")
        log.shared.line("\t?????? Archive ????????? .ipa ??????")
        log.shared.yellow.line("\t?????? -u ?????????????????? -t ????????????")
        log.shared.word("\t-m (productName)\t")
        log.shared.line("?????????????????????,")
        log.shared.word("\t-p (archivePath)\t")
        log.shared.line("???????????? .xcarchive ?????????")
        log.shared.word("\t-u (ipaPath)\t\t")
        log.shared.line("???????????? .ipa ?????????, ")
        log.shared.word("\t-t (target)\t\t")
        log.shared.line("?????? .ipa ??????????????? target ???????????????Name")
        log.shared.line("")
        log.shared.underline.line("Options:")
        log.shared.line("")
        log.shared.blue.word("\t--help")
        log.shared.line("\t??????????????????")
        log.shared.line("")
        
        echoErrLog(err: "1????????????buildConfig???????????????\n2??????????????????????????????")
    }
    
    func echoErrLog(err: String) {
        guard let stream = try? open(forWriting: buildErrLogPath, overwrite: true) else { return }
        stream.write(err)
        stream.close()
    }
}
