import Foundation
// Preserve the approved uniform icon, including its Retina representations.
let resources = URL(fileURLWithPath: "Resources", isDirectory: true)
for (source, destination) in [("FMT-tool-icon.png", "FMT-icon.png"), ("FMT-tool.icns", "FMT.icns")] {
    let data = try Data(contentsOf: resources.appendingPathComponent(source))
    try data.write(to: resources.appendingPathComponent(destination))
}
