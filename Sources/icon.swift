import Foundation
let png = try Data(contentsOf: URL(fileURLWithPath: "Resources/FMT-tool-icon.png"))
try png.write(to: URL(fileURLWithPath: "Resources/FMT-icon.png"))
func bytes(_ value: UInt32) -> Data {
    var big = value.bigEndian
    return withUnsafeBytes(of: &big) { Data($0) }
}
var body = Data()
for tag in ["icp4", "icp5", "icp6", "ic07", "ic08", "ic09", "ic10"] {
    let data = try Data(contentsOf: URL(fileURLWithPath: "Resources/FMT-tool.iconset/\(tag).png"))
    body.append(Data(tag.utf8)); body.append(bytes(UInt32(data.count + 8))); body.append(data)
}
var icns = Data("icns".utf8)
icns.append(bytes(UInt32(body.count + 8))); icns.append(body)
try icns.write(to: URL(fileURLWithPath: "Resources/FMT.icns"))
