//
//  log.swift
//  build
//
//  Created by 7080 on 2021/4/12.
//

//  https://en.wikipedia.org/wiki/ANSI_escape_code

import Foundation

class log {
    static let shared = log()

    private var parameters: [Int] = []
    
    private init() {}
    
    // MARK: - 文字颜色
    var black: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(30)
        return self
    }
    
    var red: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(31)
        return self
    }
    
    var green: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(32)
        return self
    }
    
    var yellow: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(33)
        return self
    }
    
    var blue: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(34)
        return self
    }
    
    var magenta: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(35)
        return self
    }
    
    var cyan: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(36)
        return self
    }
    
    var white: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(37)
        return self
    }
    
    var gray: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(90)
        return self
    }
    
    var brightRed: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(91)
        return self
    }
    
    var brightGreen: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(92)
        return self
    }
    
    var brightYellow: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(93)
        return self
    }
    
    var brightBlue: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(94)
        return self
    }
    
    var brightMagenta: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(95)
        return self
    }
    
    var brightCyan: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(96)
        return self
    }
    
    var brightWhite: log {
        parameters = parameters.filter { 30 > $0 || ($0 > 37 && $0 < 90) || $0 > 97 }
        parameters.append(97)
        return self
    }
    
    // MARK: - 文字背景色
    var bg_black: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(40)
        return self
    }
    
    var bg_red: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(41)
        return self
    }
    
    var bg_green: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(42)
        return self
    }
    
    var bg_yellow: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(43)
        return self
    }
        
    var bg_blue: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(44)
        return self
    }
    
    var bg_magenta: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(45)
        return self
    }
    
    var bg_cyan: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(46)
        return self
    }
    
    var bg_white: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(47)
        return self
    }
    
    var bg_gray: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(100)
        return self
    }
    
    var bg_brightRed: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(101)
        return self
    }
    
    var bg_brightGreen: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(102)
        return self
    }
    
    var bg_brightYellow: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(103)
        return self
    }
    
    var bg_brightBlue: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(104)
        return self
    }
    
    var bg_brightMagenta: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(105)
        return self
    }
   
    var bg_brightCyan: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(106)
        return self
    }
    
    var bg_brightWhite: log {
        parameters = parameters.filter { 40 > $0 || ($0 > 47 && $0 < 100) || $0 > 107 }
        parameters.append(107)
        return self
    }
    
    // MARK: - 字体样式
    // 粗体
    var bold: log {
        if !parameters.contains(1) {
            parameters.append(1)
        }
        return self
    }
    
    // 虚弱体
    var faint: log {
        if !parameters.contains(2) {
            parameters.append(2)
        }
        return self
    }
    
    // 斜体
    var italic: log {
        if !parameters.contains(3) {
            parameters.append(3)
        }
        return self
    }
    
    // 下划线
    var underline: log {
        if !parameters.contains(4) {
            parameters.append(4)
        }
        return self
    }
    
    // 闪烁
    var blink: log {
        if !parameters.contains(5) {
            parameters.append(5)
        }
        return self
    }
    
    // 反转
    var invert: log {
        if !parameters.contains(7) {
            parameters.append(7)
        }
        return self
    }
    
    // 设置窗口大小
    func windowSize(_ row: Int,_ column: Int) {
        print("\u{1B}[8;\(row);\(column)t")

    }
    
    // 看不到输入文字
    func hide() {
        parameters.removeAll()
        print("\u{1B}[8m")
    }
    
    // 清空格式
    func normal() {
        parameters.removeAll()
        print("\u{1B}[m\u{1B}[m", terminator: "")
    }
    
    // 有换行符
    func line(_ str: String) {
        if parameters.count > 0 {
            let parametersStr = parameters.map({ return "\($0)" }).joined(separator: ";")
            print("\u{1B}[\(parametersStr)m\(str)\u{1B}[m")
        } else {
            print("\u{1B}[m\(str)\u{1B}[m")
        }
        normal()
    }
    
    // 没有换行符
    func word(_ str: String) {
        if parameters.count > 0 {
            let parametersStr = parameters.map({ return "\($0)" }).joined(separator: ";")
            print("\u{1B}[\(parametersStr)m\(str)\u{1B}[m", terminator: "")
        } else {
            print("\u{1B}[m\(str)\u{1B}[m", terminator: "")
        }
        normal()
    }
}
