import Foundation

for i in 1...9 {
    for j in 1...i {
        var result = "\(j * i)"
        let hexStr = String(j * i, radix: 16)
        if hexStr.count == 1 {
            let asciiValue = hexStr.first!.asciiValue!
            if asciiValue < 97 {
                result += " "
            }
        }
        result = j != 1 ? result : "\(j * i)"
        print("\(j) x \(i) = \(result)", terminator: "   ")
    }
    print("")
}

var result = [[String]]()
for i in 1...9 {
    var tmp = [String]()
    for j in 1...9 {
        let num = Int("\(j)\(i)")!
        print("\(num) * \(num) = \(num * num)", terminator: "   ")
        tmp.append("\(num) * \(num) = \(num * num)")
    }
    print("")
    result.append(tmp)
}

//  横向二维数组转纵向二维数组
var first = [String]()
let finlaResult = result.reduce(into: [[String]]()) { partialResult, items in
    var newResult = [[String]]()
    if first.count != 0 {
        newResult = zip(first, items).map({ [$0, $1] })
    }
    first = items
    if newResult.count > 0 {
        if partialResult.count == 0 {
            partialResult = newResult
        } else {
            partialResult = zip(partialResult, newResult).map({ $0+$1 }).map({ var tmp: [String : ()] = [:]; return $0.filter({ tmp.updateValue((), forKey: $0) == nil }) })
        }
    }
}
print(finlaResult[2].max(by: { $0.count < $1.count })!)


