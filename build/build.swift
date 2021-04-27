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
    var buildName: String = ""
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
                let contents = try! Files.contentsOfDirectory(atPath: productUrl.path)
                
                var xcodeprojs = contents.filter { $0.hasSuffix(".xcodeproj") }
                xcodeprojs = xcodeprojs.filter { $0 != "Pods.xcodeproj" }
                var xcworkspaces = contents.filter { $0.hasSuffix(".xcworkspace") }
                
                if contents.count == 0 || xcodeprojs.count == 0 {
                    log.shared.red.line("[!] 配置文件 productPath 字段有误，请前往\(configPath + "/buildConfig")查看")
                    run(bash: "open -R \(configPath)")
                    return
                }
                if xcodeprojs.count > 1 {
                    log.shared.red.line("[!] 配置文件 productPath 下有多个项目时，要填写具体项目路径，请前往\(configPath + "/buildConfig")查看")
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
                log.shared.red.line("[!] 配置文件 productPath 字段有误，请前往\(configPath + "/buildConfig")查看")
                run(bash: "open -R \(configPath)")
                return
            }
        }
        
        if configModel.productName == nil || configModel.productScheme == nil || configModel.isHasPod == nil {
            log.shared.red.line("[!] 配置文件 productPath 字段有误，请前往\(configPath + "/buildConfig")查看")
            run(bash: "open -R \(configPath)")
            return
        }
        
        checkoutPath = configModel.productPath + "/\(Date().toString)"
        creatExortConfig()
        
        if exprot {
            exportArchive()
        } else {
            startBuild()
        }
    }
    
    func startBuild() {
        do {
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild clean")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild archive -\(configModel.isHasPod! ? "workspace" : "project") \(configModel.productName!).\(configModel.isHasPod! ? "xcworkspace" : "xcodeproj") -scheme \(configModel.productScheme!) -configuration \(configModel.productConfiguration) -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild -exportArchive -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive -exportPath \(checkoutPath) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            try runAndPrint(bash: "cd \(workingSpace); open -R \(checkoutPath)")
        } catch let error as CommandError {
            log.shared.red.line(error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
        }
    }
    
    func exportArchive() {
        var archiveUrl = URL(fileURLWithPath: archivePath)
        archiveUrl.deleteLastPathComponent()
        do {
            try runAndPrint(bash: "xcodebuild -exportArchive -archivePath \(archivePath) -exportPath \(archiveUrl.path) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            try runAndPrint(bash: "cd \(workingSpace); open -R \(archiveUrl.path)")
        } catch let error as CommandError {
            log.shared.red.line(error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
        }
    }
    
    func analysisConfig(_ config: String,_ exprot: Bool) {
        var configArr = config.components(separatedBy: "\n").compactMap { (item) -> String? in
            if item.contains("#") {
                return item.components(separatedBy: "#").first
            }
            return item
        }
        var configStr = configArr.joined(separator: "\n")
        configArr = configStr.components(separatedBy: "'").enumerated().map { (idx, value) -> String in
            if idx % 2 == 1 {
                return value.replacingOccurrences(of: " ", with: "*")
            }
            return value
        }
        configStr = configArr.joined(separator: "'")
        configArr = configStr.components(separatedBy: "\"").enumerated().map { (idx, value) -> String in
            if idx % 2 == 1 {
                return value.replacingOccurrences(of: " ", with: "*")
            }
            return value
        }
        configStr = configArr.joined(separator: "\"")
        configStr = configStr.replacingOccurrences(of: "'", with: "")
        configStr = configStr.replacingOccurrences(of: "\"", with: "")
        configArr = configStr.components(separatedBy: " ").compactMap { (item) -> String? in
            if item.count == 0 {
                return nil
            }
            return item
        }
        configStr = configArr.joined(separator: " ")
        configArr = configStr.components(separatedBy: "\n").compactMap { (item) -> String? in
            if item.count == 0 {
                return nil
            }
            if item == " " {
                return nil
            }
            return item.trimmingCharacters(in: .whitespaces)
        }
        configStr = configArr.joined(separator: "\n")
        configArr = configStr.components(separatedBy: "end")
        configArr = configArr.filter { $0.contains("product \(buildName) do") }
        if configArr.count != 1 {
            log.shared.red.line("[!] 配置文件有误，请前往\(configPath + "/buildConfig")查看")
            run(bash: "open -R \(configPath)")
            return
        }
        configStr = configArr.first!.replacingOccurrences(of: " ", with: "")
        configStr = configStr.replacingOccurrences(of: "[", with: "")
        configStr = configStr.replacingOccurrences(of: "]", with: "")
        configStr = configStr.replacingOccurrences(of: "),\n(", with: "),(")
        configStr = configStr.replacingOccurrences(of: "*", with: " ")
        configArr = configStr.components(separatedBy: "\n")
        configArr = configArr.filter { $0.contains("=") }
        
        var keys = [String]()
        var values = [Any]()
        
        for item in configArr {
            keys.append(item.components(separatedBy: "=").first!)
            values.append(item.components(separatedBy: "=").last!)
        }
        
        keys = keys.compactMap { (item) -> String? in
            let new = item.trimmingCharacters(in: .whitespaces)
            if new.count == 0 {
                return nil
            }
            return new
        }
        values = values.compactMap { (item) -> Any? in
            if let strItem = item as? String {
                let new = strItem.trimmingCharacters(in: .whitespaces)
                if new.count == 0 {
                    return nil
                }
                if new.hasPrefix("(") {
                    let newArr = new.components(separatedBy: "),").compactMap { (item) -> String? in
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
                        newObjArr.append(Dictionary(uniqueKeysWithValues: zip(objKeys, objValues)))
                    }
                    return newObjArr
                }
                return new
            }
            return nil
        }
        
        let jsonData = Dictionary(uniqueKeysWithValues: zip(keys, values)).jsonData()
        guard let model = try? JSONDecoder().decode(Model.self, from: jsonData) else {
            log.shared.red.line("[!] 配置文件有误，请前往\(configPath + "/buildConfig")查看")
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
            # 如果有多个项目，请写多个 product 'xxx' do ... end

            product 'xxx' do
                # productPath\t\t\t\t 对应项目的路径
                # productScheme\t\t\t\t 对应项目的Scheme
                # productConfiguration\t\t 对应项目的 configuration  分别为 Release 和  Debug
                # teamID\t\t\t\t\t 对应的账号 teamID
                # provisioningProfiles\t\t 如果要手动选择证书和配置文件的话，请填写此项

                productPath = 'xxx'\t  # 必传项
                #productScheme = 'xxx'\t  # productScheme默认为项目名, 如果您的productScheme和项目名不一致，请移除注释, 自行配置
                productConfiguration = 'Release'\t  # 默认为 Release
                teamID = 'xxx'\t  # 必传项

                # 如果有多个target e.g. [(BundleId: 'bundleid1', profileName: 'name1'), (BundleId: 'bundleid2', profileName: 'name2')]
                #provisioningProfiles = [(BundleId: 'xxx', profileName: 'xxx')]\t
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
                    <string>development</string>
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
                    <string>development</string>
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
                log.shared.red.word("您是想用：")
                log.shared.green.word("\(command)")
                log.shared.red.line("?")
                help()
            }
        case "export":
            if Files.fileExists(atPath: configPath + "/buildConfig") {
                guard let config = try? String(contentsOfFile: configPath + "/buildConfig", encoding: .utf8) else {
                    log.shared.red.line("[!] 请选运行 init ")
                    return
                }
                
                if arguments.count == 4, arguments[2] == "-p" {
                    archivePath = arguments[3]
                    analysisConfig(config, true)
                    return
                }
                
                if arguments.count == 4, arguments[2] == "-m" {
                    buildName = arguments[3]
                    analysisConfig(config, false)
                } else {
                    log.shared.red.word("您是想用：")
                    log.shared.green.word("\(command)")
                    log.shared.red.line("?")
                    help()
                }
            } else {
                log.shared.red.line("[!] 请选运行 init ")
            }
        case "--help":
            help()
        default:
            log.shared.red.word("[!] Unknown command（找不到命令）: `\(command)` 尝试使用 ")
            log.shared.word("$ ")
            log.shared.green.line("build --help")
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
        log.shared.line("\t  build, 自动化打包工具, 导出路径为当前路径")
        log.shared.line("")
        log.shared.underline.line("Commands:")
        log.shared.line("")
        log.shared.green.word("\t+ init")
        log.shared.line("\t\t用于创建一个 BuildConfig 文件")
        log.shared.green.line("\t+ export [-m, -p]")
        log.shared.line("\t\t\t自动 Archive 并导出 .ipa 文件, -m, (productName) 要打包")
        log.shared.line("\t\t\t的项目名, -p, (archivePath) 要导出的 .xcarchive 文件")
        log.shared.line("")
        log.shared.underline.line("Options:")
        log.shared.line("")
        log.shared.blue.word("\t--help")
        log.shared.line("\t\t显示帮助文档")
        log.shared.line("")
    }
}
