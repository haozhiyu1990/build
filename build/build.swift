//
//  build.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

import Foundation

class build {
    var arguments: [String]
    var workingSpace: String
    var configPath: String = ""
    var checkoutPath: String = ""
    var productPath: String = ""
    var archivePath: String = ""
    var configModel: Model!

    class func arguments(_ arguments: [String]) {
        let builder = build(arguments: arguments)
        builder.work()
    }
    
    init(arguments: [String]) {
        self.arguments = arguments
        var pointer: [Int8] = []
        getcwd(&pointer, 2048)
        workingSpace = String(cString: &pointer)
    }
    
    func work() {
        printLog()
        
        checkaArguments()
    }
    
    func checkConfigModel() {
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
                    run(bash: "open -n \(configPath)")
                    return
                }
                if xcodeprojs.count > 1 {
                    log.shared.red.line("[!] 配置文件 productPath 下有多个项目时，要填写具体项目路径，请前往\(configPath + "/buildConfig")查看")
                    run(bash: "open -n \(configPath)")
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
                run(bash: "open -n \(configPath)")
                return
            }
        }
        
        if configModel.productName == nil || configModel.productScheme == nil || configModel.isHasPod == nil {
            log.shared.red.line("[!] 配置文件 productPath 字段有误，请前往\(configPath + "/buildConfig")查看")
            run(bash: "open -n \(configPath)")
            return
        }
        
        startBuild()
    }
    
    func startBuild() {
        do {
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild clean")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild archive -\(configModel.isHasPod! ? "workspace" : "project") \(configModel.productName!).\(configModel.isHasPod! ? "xcworkspace" : "xcodeproj") -scheme \(configModel.productScheme!) -configuration \(configModel.productConfiguration) -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive")
            try runAndPrint(bash: "cd \(configModel.productPath); xcodebuild -exportArchive -archivePath \(checkoutPath)/\(configModel.productName!).xcarchive -exportPath \(checkoutPath) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            try runAndPrint(bash: "cd \(workingSpace); open -n \(checkoutPath)")
        } catch let error as CommandError {
            log.shared.red.line(error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
        }
    }
    
    func startArchive() {
        var archiveUrl = URL(fileURLWithPath: archivePath)
        archiveUrl.deleteLastPathComponent()
        do {
            try runAndPrint(bash: "xcodebuild -exportArchive -archivePath \(archivePath) -exportPath \(archiveUrl.path) -exportOptionsPlist \(configPath)/ExportOptions.plist")
            try runAndPrint(bash: "cd \(workingSpace); open -n \(archiveUrl.path)")
        } catch let error as CommandError {
            log.shared.red.line(error.description)
        } catch {
            log.shared.red.line(error.localizedDescription)
        }
    }
    
    func analysisConfig(_ config: String) {
        var arr = config.components(separatedBy: "\n")
        arr = arr.compactMap { (item) -> String? in
            if item.contains("//") {
                return item.components(separatedBy: "//").first
            }
            return item
        }
        arr = arr.filter { $0.contains("=") }
        
        var keys = [String]()
        var values = [String]()
        
        for item in arr {
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
        values = values.compactMap { (item) -> String? in
            let new = item.trimmingCharacters(in: .whitespaces)
            if new.count == 0 {
                return nil
            }
            return new
        }
        
        let jsonData = Dictionary(uniqueKeysWithValues: zip(keys, values)).jsonData()
        guard let model = try? JSONDecoder().decode(Model.self, from: jsonData) else {
            log.shared.red.line("[!] 配置文件有误，请前往\(configPath + "/buildConfig")查看")
            run(bash: "open -n \(configPath)")
            return
        }
        checkoutPath = configPath + "/\(Date().toString)"
        configModel = model
        checkConfigModel()
    }
    
    func checkaArguments() {
        if arguments.count < 2 {
            help()
        } else {
            implementCommand(arguments[1])
        }
    }
    
    func creatConfig() {
        guard let stream = try? open(forWriting: configPath + "/buildConfig", overwrite: true) else { return }
        stream.write("""
            // productPath\t\t 对应项目的路径
            // productScheme\t\t 对应项目的Scheme
            // productConfiguration\t 对应项目的 configuration  分别为 Release 和  Debug

            productPath = \(productPath.count > 0 ? productPath : "xxx")
            //productScheme = xxx\t // productScheme默认为项目名, 如果您的productScheme和项目名不一致，请移除注释, 自行配置
            productConfiguration = Release  // 默认为 Release
            """)
        stream.close()
        
        guard let plist = try? open(forWriting: configPath + "/ExportOptions.plist", overwrite: true) else { return }
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
                <string>P8HFWU8B38</string>
                <key>thinning</key>
                <string>&lt;none&gt;</string>
            </dict>
            </plist>

            """)
        plist.close()
    }
    
    func implementCommand(_ command: String) {
        configPath = workingSpace + "/auto-build-product"
        
        if Files.fileExists(atPath: command) {
            productPath = command

            creatConfig()
            guard let config = try? String(contentsOfFile: configPath + "/buildConfig", encoding: .utf8) else {
                log.shared.red.line("[!] 请选运行 init ")
                return
            }
            analysisConfig(config)
            return
        }
        
        switch command {
        case "init":
            if arguments.count > 2 {
                productPath = arguments[2]
            }
            
            if Files.fileExists(atPath: configPath + "/buildConfig"), arguments.count == 2 {
                return
            }
            
            creatConfig()
            
        case "checkout":
            if Files.fileExists(atPath: configPath + "/buildConfig") {
                guard let config = try? String(contentsOfFile: configPath + "/buildConfig", encoding: .utf8) else {
                    log.shared.red.line("[!] 请选运行 init ")
                    return
                }
                
                if arguments.count > 2 {
                    archivePath = arguments[2]
                    startArchive()
                    return
                }
                analysisConfig(config)
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
        log.shared.line("\t  build, 用于自动化打包工具, 导出路径为当前路径")
        log.shared.line("")
        log.shared.word("\t$")
        log.shared.green.line(" build (productPaht)")
        log.shared.line("")
        log.shared.line("\t  快速打包方法, 直接拖入要打包的项目文件路径, 导出路径为当前路径")
        log.shared.line("")
        log.shared.underline.line("Commands:")
        log.shared.line("")
        log.shared.green.word("\t+ init (productPath)")
        log.shared.line("\t\t用于创建一个 BuildConfig 文件, 括号里为")
        log.shared.line("\t\t\t\t\t可选参数, 若不传, 请自行在 BuildConfig")
        log.shared.line("\t\t\t\t\t文件里配置")
        log.shared.line("")
        log.shared.green.word("\t+ checkout (xcarchivePath)")
        log.shared.line("\t自动导出 .ipa 文件, 括号里是 archive")
        log.shared.line("\t\t\t\t\t生成的 .xcarchive 文件，若不传，则重新")
        log.shared.line("\t\t\t\t\tarchive 一个，并导出 .ipa 文件")
        log.shared.line("")
        log.shared.underline.line("Options:")
        log.shared.line("")
        log.shared.blue.word("\t--help")
        log.shared.line("\t\t\t\t显示帮助文档")
        log.shared.line("")
    }
}
