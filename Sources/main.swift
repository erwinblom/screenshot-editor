import AppKit
import Carbon
import CoreText
import UniformTypeIdentifiers

enum Style {
    static let ink = NSColor(srgbRed: 10/255, green: 10/255, blue: 10/255, alpha: 1)
    static let red = NSColor(srgbRed: 225/255, green: 6/255, blue: 0, alpha: 1)
    static let paper = NSColor.white
    static let muted = NSColor(srgbRed: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    static let artworkEdge: CGFloat = 4
    static let artworkLift: CGFloat = 8
    static let brandPadding: CGFloat = 12
    static let portraitLift: CGFloat = 180
    static let edge: CGFloat = 2
    static let lift: CGFloat = 3
    static let smallLift: CGFloat = 2
    static let controlFont = NSFont(name: "Arial-BoldMT", size: 16)!
    static let space: CGFloat = 24
    static let ui = NSFont(name: "Arial", size: 16)!
    static let small = NSFont(name: "Arial", size: 12)!
    static var brandName = NSFont.boldSystemFont(ofSize: 16).fontName
    static func brand(_ size: CGFloat) -> NSFont { NSFont(name: brandName, size: size)! }
}

enum AppError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case let .message(text) = self { return text }
        return nil
    }
}

func loadFont() throws {
    Style.brandName = NSFont.boldSystemFont(ofSize: 16).fontName
}

enum ExportFormat: String, CaseIterable {
    case square = "1x1", landscape = "16x9", portrait = "9x16"
    var size: NSSize {
        switch self {
        case .square: return NSSize(width: 1080, height: 1080)
        case .landscape: return NSSize(width: 1920, height: 1080)
        case .portrait: return NSSize(width: 1080, height: 1920)
        }
    }
    var ratioLabel: String { rawValue.replacingOccurrences(of: "x", with: ":") }
    var useLabel: String {
        switch self {
        case .square: return "Vierkant · feeds"
        case .landscape: return "Breed · feeds"
        case .portrait: return "Staand · Stories"
        }
    }
    var pixels: String { "\(Int(size.width)) × \(Int(size.height))" }
}

enum Background: String, CaseIterable {
    case white = "wit", black = "zwart", red = "rood"
    var title: String { rawValue.capitalized }
    var color: NSColor {
        switch self {
        case .white: return .white
        case .black: return Style.ink
        case .red: return Style.red
        }
    }
    var foreground: NSColor { self == .white ? Style.ink : .white }
    var accent: NSColor { self == .red ? Style.ink : Style.red }
}

struct Composition {
    let bitmap: NSBitmapImageRep
    let imageRect: NSRect
    let captionRect: NSRect
    let framing: Framing
    var png: Data { bitmap.representation(using: .png, properties: [:])! }
    var image: NSImage {
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        return image
    }
}

struct Framing: Codable {
    var zoom: Double = 1
    var x: Double = 0
    var y: Double = 0
    mutating func clamp() {
        zoom = zoom.isFinite ? min(4, max(1, zoom)) : 1
        let limit: Double = zoom == 1 ? 0 : 2
        x = x.isFinite ? min(limit, max(-limit, x)) : 0
        y = y.isFinite ? min(limit, max(-limit, y)) : 0
    }
}

struct OwnStyle: Codable {
    var name = ""
    var website = ""
    var logoPNG: Data? = nil
    var logo: NSImage? { logoPNG.flatMap { NSImage(data: $0) } }
}

final class Composer {
    let logo: NSImage
    let logos: [Background: NSImage]
    init() throws {
        let path = Bundle.main.url(forResource: "fmt-target-logo", withExtension: "svg")
            ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/fmt-target-logo.svg")
        guard let image = NSImage(contentsOf: path) else { throw AppError.message("Het originele FMT-logo ontbreekt.") }
        logo = image
        let svg = try String(contentsOf: path, encoding: .utf8)
        let light = svg.replacingOccurrences(of: "#0A0A0A", with: "#FFFFFF")
        let onRed = light.replacingOccurrences(of: "#E10600", with: "#0A0A0A")
        guard let whiteLogo = NSImage(data: Data(light.utf8)), let redLogo = NSImage(data: Data(onRed.utf8)) else {
            throw AppError.message("De FMT-logokleuren konden niet worden geladen.")
        }
        logos = [.white: image, .black: whiteLogo, .red: redLogo]
    }

    func compose(_ inputSource: NSImage?, caption: String, format: ExportFormat = .square, background: Background = .white, framing: Framing = Framing(), header: String = "", footerURL: String = "", mainText: String? = nil, exportLogo: NSImage? = nil) throws -> Composition {
        let quote = mainText?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let quote {
            guard !quote.isEmpty else { throw AppError.message("Vul je citaat of slogan in onder de preview.") }
            guard quote.count <= 500 else { throw AppError.message("Houd je citaat of slogan binnen 500 tekens.") }
        }
        guard inputSource != nil || quote != nil else { throw AppError.message("Open een beeld of kies Citaat / slogan.") }
        let source = inputSource ?? NSImage(size: NSSize(width: 1, height: 1))
        let headerText = header.trimmingCharacters(in: .whitespacesAndNewlines)
        guard headerText.count <= 60, !headerText.contains("\n"), !headerText.contains("\r") else { throw AppError.message("Gebruik linksboven één regel van maximaal 60 tekens.") }
        let urlText = footerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard urlText.count <= 100, !urlText.contains(where: { $0.isWhitespace }) else { throw AppError.message("Gebruik een URL zonder spaties, maximaal 100 tekens.") }
        let size = format.size
        let marginX = (size.width * 0.04).rounded()
        let marginY = (size.height * 0.04).rounded()
        let headerHeight = headerText.isEmpty && exportLogo == nil ? 0 : (size.height * 0.08).rounded()
        let gap = (min(size.width, size.height) * 0.025).rounded()
        let contentWidth = size.width - 2 * marginX
        let text = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count <= 100 else { throw AppError.message("Houd de tekst kort: maximaal 100 tekens.") }
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = .byCharWrapping
        para.minimumLineHeight = 44
        para.maximumLineHeight = 44
        let attributes: [NSAttributedString.Key: Any] = [.font: Style.brand(36), .foregroundColor: background.foreground, .paragraphStyle: para]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let measured = attributed.boundingRect(with: NSSize(width: contentWidth, height: 1000), options: [.usesLineFragmentOrigin, .usesFontLeading])
        guard measured.height <= 94 else { throw AppError.message("Dit onderschrift past niet in twee regels. Maak het korter; het lettertype blijft vast.") }
        let urlNaturalWidth = NSAttributedString(string: urlText, attributes: [.font: Style.brand(24)]).size().width
        let urlFontSize = min(24, 24 * contentWidth / max(1, urlNaturalWidth))
        let urlLabel = NSAttributedString(string: urlText, attributes: [.font: Style.brand(urlFontSize), .foregroundColor: background.foreground])
        let urlRowHeight = urlText.isEmpty ? 0 : ceil(urlLabel.size().height) + 12
        let footerHeight = marginY + urlRowHeight + (text.isEmpty ? (urlText.isEmpty ? 0 : gap) : ceil(measured.height) + gap)
        let available = NSRect(x: marginX, y: footerHeight + Style.artworkLift, width: contentWidth - Style.artworkLift, height: size.height - marginY - headerHeight - gap - footerHeight - Style.artworkLift)
        var quoteLabel: NSAttributedString?
        var quoteHeight: CGFloat = 0
        if let quote {
            let textWidth = available.width - 48
            let textHeight = available.height - 48
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 8
            for pointSize in stride(from: CGFloat(112), through: CGFloat(36), by: -2) {
                let label = NSAttributedString(string: quote, attributes: [.font: Style.brand(pointSize), .foregroundColor: background.foreground, .paragraphStyle: paragraph])
                let measured = label.boundingRect(with: NSSize(width: textWidth, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading])
                if ceil(measured.height) <= textHeight {
                    quoteLabel = label; quoteHeight = ceil(measured.height); break
                }
            }
            guard quoteLabel != nil else { throw AppError.message("Deze tekst past niet leesbaar. Maak hem korter of gebruik minder lege regels.") }
        }
        guard source.size.width > 0, source.size.height > 0 else { throw AppError.message("Dit beeld is leeg.") }
        let ratio = min(available.width / source.size.width, available.height / source.size.height)
        let imageRect = NSRect(x: available.midX - source.size.width * ratio / 2, y: available.midY - source.size.height * ratio / 2, width: source.size.width * ratio, height: source.size.height * ratio)
        guard let pixels = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw AppError.message("Het beeld kon niet worden opgebouwd.")
        }
        let context = NSGraphicsContext(cgContext: pixels, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        background.color.setFill()
        NSRect(origin: .zero, size: size).fill()
        let logoSize = min(64, headerHeight * 0.75)
        let headerCenterY = size.height - marginY - headerHeight / 2
        if let exportLogo {
            let ratio = min(logoSize / exportLogo.size.width, logoSize / exportLogo.size.height)
            let markSize = NSSize(width: exportLogo.size.width * ratio, height: exportLogo.size.height * ratio)
            exportLogo.draw(in: NSRect(x: size.width - marginX - markSize.width, y: headerCenterY - markSize.height / 2, width: markSize.width, height: markSize.height), from: .zero, operation: .sourceOver, fraction: 1)
        }
        let maxBrandWidth = contentWidth - (exportLogo == nil ? 0 : logoSize + gap) - 2 * Style.brandPadding
        let naturalWidth = NSAttributedString(string: headerText, attributes: [.font: Style.brand(38)]).size().width
        let fontSize = min(38, 38 * maxBrandWidth / max(1, naturalWidth))
        let brand = NSAttributedString(string: headerText, attributes: [.font: Style.brand(fontSize), .foregroundColor: background.color])
        let brandBox = NSRect(x: marginX, y: headerCenterY - brand.size().height / 2 - Style.brandPadding,
                              width: brand.size().width + 2 * Style.brandPadding, height: brand.size().height + 2 * Style.brandPadding)
        if !headerText.isEmpty { background.foreground.setFill(); brandBox.fill() }
        brand.draw(at: NSPoint(x: brandBox.minX + Style.brandPadding, y: brandBox.minY + Style.brandPadding))
        if !urlText.isEmpty {
            urlLabel.draw(at: NSPoint(x: size.width - marginX - urlLabel.size().width, y: marginY))
        }
        let captionRect = NSRect(x: marginX, y: marginY + urlRowHeight, width: contentWidth, height: ceil(measured.height))
        if !text.isEmpty {
            attributed.draw(with: captionRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        }
        var crop = framing
        crop.clamp()
        if let quoteLabel {
            quoteLabel.draw(with: NSRect(x: available.minX + 24, y: available.midY - quoteHeight / 2, width: available.width - 48, height: quoteHeight), options: [.usesLineFragmentOrigin, .usesFontLeading])
        } else {
        let enlargedSize = NSSize(width: imageRect.width * crop.zoom, height: imageRect.height * crop.zoom)
        let limitX = crop.zoom == 1 ? 0 : abs(enlargedSize.width - available.width) / (2 * available.width)
        let limitY = crop.zoom == 1 ? 0 : abs(enlargedSize.height - available.height) / (2 * available.height)
        crop.x = min(limitX, max(-limitX, crop.x))
        crop.y = min(limitY, max(-limitY, crop.y))
        let verticalLift = format == .portrait ? min(Style.portraitLift, max(0, (available.height - enlargedSize.height) / 2)) : 0
        let enlarged = NSRect(x: available.midX - enlargedSize.width / 2 + available.width * crop.x,
                              y: available.midY + verticalLift - enlargedSize.height / 2 + available.height * crop.y,
                              width: enlargedSize.width, height: enlargedSize.height)
        let visibleImage = enlarged.intersection(available)
        (background == .black ? Style.paper : Style.ink).setFill()
        visibleImage.offsetBy(dx: Style.artworkLift, dy: -Style.artworkLift).fill()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: available).addClip()
        source.draw(in: enlarged, from: NSRect(origin: .zero, size: source.size), operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        background.foreground.setStroke()
        let frame = NSBezierPath(rect: visibleImage.insetBy(dx: Style.artworkEdge / 2, dy: Style.artworkEdge / 2))
        frame.lineWidth = Style.artworkEdge
        frame.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()
        guard let rendered = pixels.makeImage() else { throw AppError.message("Het PNG-beeld kon niet worden opgebouwd.") }
        let bitmap = NSBitmapImageRep(cgImage: rendered)
        bitmap.size = size
        return Composition(bitmap: bitmap, imageRect: available, captionRect: captionRect, framing: crop)
    }


}

final class FlatButton: NSButton {
    var primary = false
    var fillColor: NSColor?
    var textColor: NSColor?
    override func draw(_ dirtyRect: NSRect) {
        let lift = isEnabled ? (bounds.height <= 36 ? Style.smallLift : Style.lift) : 0
        let pressed = isHighlighted && isEnabled
        let face = NSRect(x: pressed ? lift : 0,
                          y: isFlipped ? (pressed ? lift : 0) : (pressed ? 0 : lift),
                          width: bounds.width - lift, height: bounds.height - lift)
        if isEnabled {
            Style.ink.setFill()
            NSRect(x: lift, y: isFlipped ? lift : 0, width: face.width, height: face.height).fill()
        }
        (fillColor ?? (primary ? Style.red : Style.paper)).setFill()
        face.fill()
        (isEnabled ? Style.ink : Style.muted).setStroke()
        let outline = NSBezierPath(rect: face.insetBy(dx: Style.edge / 2, dy: Style.edge / 2))
        outline.lineWidth = Style.edge
        outline.stroke()
        let attrs: [NSAttributedString.Key: Any] = [.font: Style.controlFont, .foregroundColor: isEnabled ? (textColor ?? (primary ? NSColor.white : Style.ink)) : Style.muted]
        let size = (title as NSString).size(withAttributes: attrs)
        (title as NSString).draw(at: NSPoint(x: face.midX-size.width/2, y: face.midY-size.height/2), withAttributes: attrs)
        if window?.firstResponder === self {
            (primary || fillColor == Style.red ? Style.paper : Style.red).setStroke()
            let focus = NSBezierPath(rect: face.insetBy(dx: 5, dy: 5)); focus.lineWidth = Style.edge; focus.stroke()
        }
    }
}

final class DropPreview: NSImageView {
    var receiveImage: ((NSImage) -> Void)?
    var moveImage: ((NSPoint) -> Void)?
    var sourceFrame = NSRect.zero
    private var lastPoint: NSPoint?
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        lastPoint = sourceFrame.contains(point) ? point : nil
    }
    override func mouseDragged(with event: NSEvent) {
        guard let previous = lastPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        moveImage?(NSPoint(x: (point.x - previous.x) / sourceFrame.width,
                           y: (point.y - previous.y) / sourceFrame.height * (isFlipped ? -1 : 1)))
        lastPoint = point
    }
    override func mouseUp(with event: NSEvent) { lastPoint = nil }
    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL, .png, .tiff])
        imageScaling = .scaleProportionallyUpOrDown
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let board = sender.draggingPasteboard
        if let image = NSImage(pasteboard: board) { receiveImage?(image); return true }
        if let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], let url = urls.first, let image = NSImage(contentsOf: url) { receiveImage?(image); return true }
        return false
    }
}

final class EditorView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        Style.paper.setFill(); bounds.fill()
        Style.ink.setFill(); NSRect(x: 24, y: 104, width: 872, height: 4).fill()
        Style.red.setFill(); NSRect(x: 24, y: 104, width: 96, height: 4).fill()
        let panel = NSRect(x: 592, y: 120, width: 304, height: 672)
        Style.ink.setFill(); panel.offsetBy(dx: 4, dy: 4).fill()
        Style.paper.setFill(); panel.fill()
        Style.ink.setFill(); NSRect(x: 608, y: 372, width: 272, height: 64).fill()
        Style.ink.setStroke()
        let edge = NSBezierPath(rect: panel.insetBy(dx: Style.edge / 2, dy: Style.edge / 2))
        edge.lineWidth = Style.edge; edge.stroke()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate, NSTextFieldDelegate {
    var window: NSWindow!
    let preview = DropPreview(frame: .zero)
    let caption = NSTextView()
    let contentChoice = NSPopUpButton(frame: .zero, pullsDown: false)
    let quoteEditor = NSTextView()
    let quoteScroll = NSScrollView()
    let quotePrompt = NSTextField(labelWithString: "Citaat of slogan · maximaal 500 tekens")
    var textMode: Bool { contentChoice.indexOfSelectedItem == 1 }
    var ownStyle = OwnStyle()
    let styleSummary = NSTextField(wrappingLabelWithString: "Geen naam, logo of website in je export.")
    var stylePanel: NSPanel?
    let styleName = NSTextField(string: "")
    let styleWebsite = NSTextField(string: "")
    let styleLogoPreview = NSImageView()
    let styleError = NSTextField(wrappingLabelWithString: "")
    var pendingLogo: Data?
    var selectedHeader: String { ownStyle.name }
    var selectedURL: String { ownStyle.website }
    let status = NSTextField(wrappingLabelWithString: "")
    let emptyLabel = NSTextField(wrappingLabelWithString: "Maak een screenshot of laad een afbeelding\n⌃⌥⌘S  /  ⌘O")
    var captureButton: FlatButton!
    var copyButton: FlatButton!
    var saveButton: FlatButton!
    var settingsButton: FlatButton!
    var statusItem: NSStatusItem!
    var hotKey: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    var composer: Composer!
    var source: NSImage?
    var composition: Composition?
    var captureProcess: Process?
    var capturing = false
    var appError: Error?
    var shortcutReady = false
    var format: ExportFormat = .square
    var framing = Framing()
    let zoomSlider = NSSlider(value: 1, minValue: 1, maxValue: 4, target: nil, action: nil)
    let zoomLabel = NSTextField(labelWithString: "Zoom 100%")
    var background: Background = .white
    var formatButtons: [FlatButton] = []
    var backgroundButtons: [FlatButton] = []
    let formatHint = NSTextField(labelWithString: "")
    let dimensions = NSTextField(labelWithString: "")
    let storage = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("FMT Screenshot Editor", isDirectory: true)

    func applicationDidFinishLaunching(_ notification: Notification) {
        do { try loadFont(); composer = try Composer() } catch {
            let alert = NSAlert(); alert.messageText = "FMT Screenshot Editor kan niet starten"; alert.informativeText = error.localizedDescription; alert.runModal(); NSApp.terminate(nil); return
        }
        if let icon = Bundle.main.url(forResource: "FMT", withExtension: "icns") {
            NSApp.applicationIconImage = NSImage(contentsOf: icon)
        }
        makeMenus()
        makeWindow()
        registerShortcut()
        restore()
        showEditor()
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Over FMT Screenshot Editor"
        alert.informativeText = "Ik ben geen programmeur en geen designer. Met AI maak ik tools en skills die ik zelf nodig heb. Ik deel ze om te laten zien wat er nu mogelijk is, je enthousiast te maken en je op gang te helpen. Gebruik dit als vertrekpunt: bouw erop voort en maak het passend bij jouw werk, smaak en wensen.\n\nErwin Blom · Code en technische uitleg: MIT. FMT-naam en logo: aparte merkvoorwaarden. Lees LEESMIJ.md om te beginnen en zelf verder te bouwen."
        alert.addButton(withTitle: "Sluiten")
        alert.runModal()
    }

    func makeMenus() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Over FMT Screenshot Editor", action: #selector(showAbout), keyEquivalent: "").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Stop FMT Screenshot Editor", action: #selector(quit), keyEquivalent: "q").target = self
        let fileItem = NSMenuItem(title: "Beeld", action: nil, keyEquivalent: ""); main.addItem(fileItem)
        let file = NSMenu(title: "Beeld"); fileItem.submenu = file
        file.addItem(withTitle: "Nieuwe screenshot", action: #selector(capture), keyEquivalent: "n").target = self
        file.addItem(withTitle: "Laad afbeelding…", action: #selector(openImage), keyEquivalent: "o").target = self
        file.addItem(withTitle: "Bewaar PNG…", action: #selector(save), keyEquivalent: "s").target = self
        let editItem = NSMenuItem(title: "Bewerken", action: nil, keyEquivalent: ""); main.addItem(editItem)
        let edit = NSMenu(title: "Bewerken"); editItem.submenu = edit
        edit.addItem(withTitle: "Ongedaan maken", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Knip", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Kopieer", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Plak", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Selecteer alles", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Plak screenshot", action: #selector(pasteImage), keyEquivalent: "").target = self
        NSApp.mainMenu = main
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menuLogo = composer.logo.copy() as! NSImage
        menuLogo.size = NSSize(width: 18, height: 18)
        menuLogo.isTemplate = true
        statusItem.button?.image = menuLogo
        statusItem.button?.toolTip = "FMT Screenshot Editor"
        statusItem.button?.setAccessibilityLabel("FMT Screenshot Editor")
        let tray = NSMenu()
        tray.addItem(withTitle: "Nieuwe screenshot  ⌃⌥⌘S", action: #selector(capture), keyEquivalent: "").target = self
        tray.addItem(withTitle: "Open FMT Screenshot Editor", action: #selector(showEditor), keyEquivalent: "").target = self
        tray.addItem(.separator())
        tray.addItem(withTitle: "Stop", action: #selector(quit), keyEquivalent: "").target = self
        statusItem.menu = tray
    }

    func label(_ text: String, font: NSFont = Style.ui) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text); field.font = font; field.textColor = Style.ink; return field
    }
    func place(_ view: NSView, _ rect: NSRect, in parent: NSView) { view.frame = rect; parent.addSubview(view) }
    func button(_ title: String, _ selector: Selector, primary: Bool = false) -> FlatButton {
        let button = FlatButton(title: title, target: self, action: selector)
        button.primary = primary; button.isBordered = false; button.setAccessibilityLabel(title); return button
    }

    func makeWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 920, height: 840), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "FMT Screenshot Editor"
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        let root = EditorView(frame: NSRect(x: 0, y: 0, width: 920, height: 840)); window.contentView = root
        place(label("FMT Screenshot Editor", font: Style.brand(36)), NSRect(x: 24, y: 24, width: 760, height: 48), in: root)
        place(label("SCREENSHOT  /  Vastleggen. Opmaken. Delen.", font: Style.small), NSRect(x: 24, y: 78, width: 650, height: 24), in: root)
        let brand = NSImageView(frame: NSRect(x: 840, y: 30, width: 44, height: 44))
        brand.image = composer.logo; brand.imageScaling = .scaleProportionallyUpOrDown
        root.addSubview(brand)
        preview.wantsLayer = true; preview.layer?.backgroundColor = Style.paper.cgColor
        preview.layer?.borderColor = Style.ink.cgColor; preview.layer?.borderWidth = 2
        place(label("Formaat"), NSRect(x: 24, y: 126, width: 112, height: 24), in: root)
        for (index, item) in ExportFormat.allCases.enumerated() {
            let control = button(item.ratioLabel, #selector(changeFormat(_:)))
            control.tag = index
            control.setAccessibilityLabel("Formaat \(item.ratioLabel)")
            place(control, NSRect(x: 144 + CGFloat(index) * 80, y: 120, width: 72, height: 36), in: root)
            formatButtons.append(control)
        }
        formatHint.font = Style.small; formatHint.textColor = Style.ink
        place(formatHint, NSRect(x: 408, y: 132, width: 168, height: 20), in: root)
        place(label("Achtergrond"), NSRect(x: 24, y: 170, width: 112, height: 24), in: root)
        for (index, item) in Background.allCases.enumerated() {
            let control = button(item.title, #selector(changeBackground(_:)))
            control.tag = index
            control.fillColor = item.color; control.textColor = item.foreground
            control.setAccessibilityLabel("Achtergrond \(item.title)")
            place(control, NSRect(x: 144 + CGFloat(index) * 80, y: 164, width: 72, height: 36), in: root)
            backgroundButtons.append(control)
        }
        zoomLabel.font = Style.small; zoomLabel.textColor = Style.ink
        place(zoomLabel, NSRect(x: 24, y: 220, width: 112, height: 24), in: root)
        zoomSlider.target = self; zoomSlider.action = #selector(changeZoom)
        zoomSlider.isContinuous = true; zoomSlider.setAccessibilityLabel("Zoom screenshot")
        place(zoomSlider, NSRect(x: 144, y: 214, width: 240, height: 30), in: root)
        place(button("Volledig passend", #selector(resetFraming)), NSRect(x: 408, y: 210, width: 168, height: 36), in: root)
        place(label("Inhoud"), NSRect(x: 24, y: 262, width: 112, height: 24), in: root)
        contentChoice.addItems(withTitles: ["Screenshot", "Citaat / slogan"])
        contentChoice.target = self; contentChoice.action = #selector(changeHeader)
        contentChoice.setAccessibilityLabel("Soort inhoud")
        place(contentChoice, NSRect(x: 144, y: 254, width: 240, height: 32), in: root)
        place(preview, NSRect(x: 72, y: 306, width: 354, height: 354), in: root)
        quotePrompt.font = Style.small
        place(quotePrompt, NSRect(x: 24, y: 666, width: 552, height: 24), in: root)
        quoteScroll.borderType = .lineBorder; quoteScroll.hasVerticalScroller = true
        quoteEditor.isRichText = false; quoteEditor.font = Style.ui; quoteEditor.textColor = Style.ink
        quoteEditor.textContainerInset = NSSize(width: 8, height: 8)
        quoteEditor.isVerticallyResizable = true; quoteEditor.autoresizingMask = [.width]
        quoteEditor.textContainer?.widthTracksTextView = true; quoteEditor.delegate = self; quoteEditor.allowsUndo = true
        quoteEditor.setAccessibilityLabel("Citaat of slogan")
        quoteScroll.documentView = quoteEditor
        place(quoteScroll, NSRect(x: 24, y: 692, width: 552, height: 92), in: root)
        quoteEditor.frame = NSRect(x: 0, y: 0, width: 530, height: 92)
        preview.moveImage = { [weak self] delta in
            guard let self, self.source != nil, !self.textMode else { return }
            self.framing.x += delta.x; self.framing.y += delta.y; self.framing.clamp()
            self.refresh(); self.persistFraming()
        }
        preview.setAccessibilityLabel("Screenshotpreview. Zoom en sleep het beeld om te verschuiven.")
        preview.receiveImage = { [weak self] image in self?.accept(image) }
        emptyLabel.alignment = .center; emptyLabel.font = Style.brand(24); emptyLabel.textColor = Style.ink
        place(emptyLabel, NSRect(x: 80, y: 336, width: 440, height: 96), in: root)
        let x: CGFloat = 608
        let controlsWidth: CGFloat = 272
        captureButton = button("Nieuwe screenshot", #selector(capture), primary: true)
        place(captureButton, NSRect(x: x, y: 136, width: controlsWidth, height: 48), in: root)
        captureButton.toolTip = "Selecteer een schermdeel met ⌃⌥⌘S"
        let openButton = button("Laad afbeelding…", #selector(openImage))
        openButton.toolTip = "Kies een afbeelding op je computer (⌘O)"
        place(openButton, NSRect(x: x, y: 192, width: controlsWidth, height: 28), in: root)
        place(button("Eigen stijl", #selector(showOwnStyle)), NSRect(x: x, y: 244, width: controlsWidth, height: 40), in: root)
        styleSummary.font = Style.small; styleSummary.textColor = Style.muted
        styleSummary.setAccessibilityLabel("Stijl van je export")
        place(styleSummary, NSRect(x: x, y: 294, width: controlsWidth, height: 40), in: root)
        let captionLabel = label("Onderschrift / naam (optioneel)"); captionLabel.textColor = Style.ink
        place(captionLabel, NSRect(x: x, y: 340, width: controlsWidth, height: 24), in: root)
        let scroll = NSScrollView(frame: NSRect(x: x + Style.edge, y: 372 + Style.edge, width: controlsWidth - 2 * Style.edge, height: 64 - 2 * Style.edge))
        scroll.borderType = .noBorder;  scroll.hasVerticalScroller = true
        caption.frame = NSRect(x: 0, y: 0, width: 254, height: 100)
        caption.isRichText = false; caption.font = Style.ui; caption.textColor = Style.ink
        caption.textContainerInset = NSSize(width: 8, height: 8); caption.isVerticallyResizable = true
        caption.autoresizingMask = [.width]; caption.textContainer?.widthTracksTextView = true
        caption.delegate = self; caption.allowsUndo = true
        caption.setAccessibilityLabel("Onderschrift (optioneel)")
        scroll.documentView = caption; root.addSubview(scroll)
        let fontLabel = label("Systeemletter vet · maximaal 2 regels", font: Style.small); fontLabel.textColor = Style.muted
        place(fontLabel, NSRect(x: x, y: 438, width: controlsWidth, height: 20), in: root)
        copyButton = button("Kopieer beeld", #selector(copyImage), primary: true)
        saveButton = button("Bewaar PNG…", #selector(save))
        place(copyButton, NSRect(x: x, y: 588, width: controlsWidth, height: 48), in: root)
        place(saveButton, NSRect(x: x, y: 648, width: controlsWidth, height: 48), in: root)
        status.font = Style.small; status.textColor = Style.ink
        status.setAccessibilityLabel("Status")
        place(status, NSRect(x: x, y: 744, width: controlsWidth, height: 48), in: root)
        settingsButton = button("Open schermtoestemming", #selector(openPrivacy))
        place(settingsButton, NSRect(x: 24, y: 802, width: 280, height: 28), in: root)
        settingsButton.isHidden = true
        dimensions.font = Style.small; dimensions.textColor = Style.ink
        place(dimensions, NSRect(x: 316, y: 804, width: 260, height: 22), in: root)
        window.center()
    }

    @objc func showOwnStyle() {
        if let panel = stylePanel { panel.makeKeyAndOrderFront(nil); return }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 520, height: 410), styleMask: [.titled], backing: .buffered, defer: false)
        panel.title = "Eigen stijl"
        panel.appearance = NSAppearance(named: .aqua)
        let root = NSView(frame: panel.contentView!.bounds); panel.contentView = root
        func row(_ title: String, _ field: NSTextField, y: CGFloat) {
            place(label(title), NSRect(x: 24, y: y + 34, width: 472, height: 24), in: root)
            place(field, NSRect(x: 24, y: y, width: 472, height: 30), in: root)
        }
        styleName.stringValue = ownStyle.name; styleName.placeholderString = "Optioneel · maximaal 60 tekens"
        styleName.setAccessibilityLabel("Naam in export")
        styleWebsite.stringValue = ownStyle.website; styleWebsite.placeholderString = "Optioneel · bijvoorbeeld voorbeeld.nl"
        styleWebsite.setAccessibilityLabel("Website in export")
        place(label("Eigen stijl", font: Style.brand(24)), NSRect(x: 24, y: 366, width: 472, height: 32), in: root)
        row("Naam in beeld", styleName, y: 290)
        row("Website", styleWebsite, y: 210)
        pendingLogo = ownStyle.logoPNG
        styleLogoPreview.image = ownStyle.logo; styleLogoPreview.imageScaling = .scaleProportionallyUpOrDown
        styleLogoPreview.setAccessibilityLabel("Eigen logo")
        place(styleLogoPreview, NSRect(x: 24, y: 120, width: 64, height: 64), in: root)
        place(button("Kies logo…", #selector(chooseOwnLogo)), NSRect(x: 104, y: 146, width: 184, height: 36), in: root)
        place(button("Geen logo", #selector(clearOwnLogo)), NSRect(x: 304, y: 146, width: 184, height: 36), in: root)
        place(label("Lege velden verschijnen niet in je export.", font: Style.small), NSRect(x: 24, y: 96, width: 472, height: 24), in: root)
        styleError.stringValue = ""; styleError.textColor = Style.red; styleError.font = Style.small
        styleError.setAccessibilityLabel("Stijlmelding")
        place(styleError, NSRect(x: 24, y: 60, width: 472, height: 36), in: root)
        place(button("Annuleren", #selector(cancelOwnStyle)), NSRect(x: 24, y: 16, width: 184, height: 36), in: root)
        let save = button("Bewaar stijl", #selector(saveOwnStyle), primary: true); save.keyEquivalent = "\r"
        place(save, NSRect(x: 304, y: 16, width: 184, height: 36), in: root)
        stylePanel = panel; window.beginSheet(panel)
        panel.makeFirstResponder(styleName)
    }
    @objc func chooseOwnLogo() {
        guard let panel = stylePanel else { return }
        let picker = NSOpenPanel(); picker.allowedContentTypes = [.image]; picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false; picker.prompt = "Kies logo"
        picker.beginSheetModal(for: panel) { [weak self] response in
            guard let self, response == .OK, let url = picker.url else { return }
            do {
                guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 10_000_000 else { throw AppError.message("Kies een logo van maximaal 10 MB.") }
                guard let image = NSImage(contentsOf: url), image.size.width > 0, image.size.height > 0 else { throw AppError.message("Dit bestand is geen bruikbaar logo.") }
                let scale = min(1, 1024 / max(image.size.width, image.size.height))
                let width = max(1, Int(image.size.width * scale)), height = max(1, Int(image.size.height * scale))
                guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { throw AppError.message("Het logo kon niet worden gelezen.") }
                NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
                image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
                NSGraphicsContext.restoreGraphicsState()
                guard let png = bitmap.representation(using: .png, properties: [:]) else { throw AppError.message("Het logo kon niet worden bewaard.") }
                self.pendingLogo = png; self.styleLogoPreview.image = NSImage(data: png); self.styleError.stringValue = ""
            } catch { self.styleError.stringValue = error.localizedDescription }
        }
    }
    @objc func clearOwnLogo() { pendingLogo = nil; styleLogoPreview.image = nil; styleError.stringValue = "" }
    @objc func cancelOwnStyle() {
        guard let panel = stylePanel else { return }
        window.endSheet(panel); panel.orderOut(nil); stylePanel = nil
    }
    @objc func saveOwnStyle() {
        let name = styleName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let website = styleWebsite.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count <= 60, !name.contains("\n"), !name.contains("\r") else { styleError.stringValue = "Gebruik een naam van maximaal 60 tekens op één regel."; return }
        guard website.count <= 100, !website.contains(where: { $0.isWhitespace }) else { styleError.stringValue = "Gebruik een website zonder spaties, maximaal 100 tekens."; return }
        let saved = OwnStyle(name: name, website: website, logoPNG: pendingLogo)
        do {
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try JSONEncoder().encode(saved).write(to: storage.appendingPathComponent("eigen-stijl.json"), options: .atomic)
            ownStyle = saved; cancelOwnStyle(); refresh()
        } catch { styleError.stringValue = "Bewaren mislukt. Je vorige stijl blijft behouden." }
    }

    func registerShortcut() {
        var specification = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let opaque = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { owner.capture() }
            return noErr
        }, 1, &specification, opaque, &eventHandler)
        let id = EventHotKeyID(signature: 0x464D5453, id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_ANSI_S), UInt32(controlKey | optionKey | cmdKey), id, GetApplicationEventTarget(), 0, &hotKey)
        shortcutReady = installed == noErr && registered == noErr
        if !shortcutReady { status.stringValue = "De sneltoets is al in gebruik. Gebruik Nieuwe screenshot of FMT in de menubalk." }
    }

    @objc func showEditor() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showEditor(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) {
        captureProcess?.terminate()
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
    @objc func openPrivacy() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    @objc func capture() {
        guard !capturing else { return }
        if !CGPreflightScreenCaptureAccess() && !CGRequestScreenCaptureAccess() {
            showEditor(); status.stringValue = "Sta FMT Screenshot Editor toe bij Schermopname in Systeeminstellingen. Open de app daarna opnieuw."
            settingsButton.isHidden = false
            return
        }
        settingsButton.isHidden = true
        capturing = true; captureButton.isEnabled = false
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fmt-capture-\(UUID().uuidString).png")
        NSApp.hide(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-s", "-x", "-t", "png", url.path]
            let errors = Pipe(); process.standardError = errors; process.standardOutput = FileHandle.nullDevice
            self.captureProcess = process
            process.terminationHandler = { [weak self] task in
                let errorData = errors.fileHandleForReading.readDataToEndOfFile()
                DispatchQueue.main.async {
                    defer { try? FileManager.default.removeItem(at: url) }
                    guard let self else { return }
                    self.capturing = false; self.captureProcess = nil; self.captureButton.isEnabled = true
                    self.showEditor()
                    if let image = NSImage(contentsOf: url) {
                        self.accept(image)
                    } else if !CGPreflightScreenCaptureAccess() {
                        self.status.stringValue = "Schermtoestemming ontbreekt. Geef de app toegang en probeer opnieuw."
                        self.settingsButton.isHidden = false
                    } else {
                        self.status.stringValue = errorData.isEmpty || task.terminationStatus == 1 ? "Selectie geannuleerd. Je vorige beeld blijft staan." : "Vastleggen is niet gelukt. Probeer opnieuw of open een bestaand beeld."
                    }
                }
            }
            do { try process.run() } catch {
                self.capturing = false; self.captureButton.isEnabled = true; self.captureProcess = nil
                self.showEditor(); self.status.stringValue = error.localizedDescription
            }
        }
    }

    @objc func openImage() {
        let panel = NSOpenPanel()
        panel.title = "Laad afbeelding"; panel.prompt = "Laad afbeelding"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window) { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            guard let image = NSImage(contentsOf: url) else { self?.status.stringValue = "Dit bestand kon niet als beeld worden geopend."; return }
            self?.accept(image)
        }
    }
    @objc func pasteImage() {
        guard let image = NSImage(pasteboard: .general) else { status.stringValue = "Er staat geen afbeelding op je klembord."; return }
        accept(image)
    }
    func accept(_ image: NSImage) {
        contentChoice.selectItem(at: 0)
        source = image
        framing = Framing()
        refresh()
        persist()
    }
    @objc func changeZoom() {
        framing.zoom = zoomSlider.doubleValue; framing.clamp()
        refresh(); persistFraming()
    }
    @objc func resetFraming() {
        guard !textMode else { return }
        framing = Framing(); refresh(); persistFraming()
    }
    func persistFraming() {
        do {
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            try JSONEncoder().encode(framing).write(to: storage.appendingPathComponent("laatste-kader.json"), options: .atomic)
        } catch { status.stringValue = "Zoom en positie konden niet worden onthouden. Bewaar een PNG." }
    }
    func textDidChange(_ notification: Notification) { refresh(); persist() }
    @objc func changeFormat(_ sender: NSButton) {
        guard ExportFormat.allCases.indices.contains(sender.tag) else { return }
        format = ExportFormat.allCases[sender.tag]
        refresh(); persist()
    }
    @objc func changeBackground(_ sender: NSButton) {
        guard Background.allCases.indices.contains(sender.tag) else { return }
        background = Background.allCases[sender.tag]
        refresh(); persist()
    }
    @objc func changeHeader() { refresh(); persist() }
    func controlTextDidChange(_ notification: Notification) { refresh(); persist() }
    func refresh() {
        quoteScroll.isHidden = !textMode; quotePrompt.isHidden = !textMode
        let parts = [ownStyle.name.isEmpty ? nil : ownStyle.name, ownStyle.logoPNG == nil ? nil : "Eigen logo", ownStyle.website.isEmpty ? nil : ownStyle.website].compactMap { $0 }
        styleSummary.stringValue = parts.isEmpty ? "Geen naam, logo of website in je export." : parts.joined(separator: " · ")
        for (index, control) in formatButtons.enumerated() {
            control.primary = ExportFormat.allCases[index] == format
            control.needsDisplay = true
            control.setAccessibilityValue(control.primary ? "Geselecteerd" : "")
        }
        for (index, control) in backgroundButtons.enumerated() {
            let item = Background.allCases[index]
            control.title = "\(item.title)\(item == background ? " ✓" : "")"
            control.setAccessibilityValue(item == background ? "Geselecteerd" : "")
            control.needsDisplay = true
        }
        formatHint.stringValue = format.useLabel
        dimensions.stringValue = "\(format.pixels) · PNG · lokaal"
        zoomSlider.doubleValue = framing.zoom
        zoomSlider.isEnabled = source != nil && !textMode
        zoomLabel.stringValue = "Zoom \(Int((framing.zoom * 100).rounded()))%"
        let scale = min(552 / format.size.width, 354 / format.size.height)
        let previewSize = NSSize(width: format.size.width * scale, height: format.size.height * scale)
        preview.frame = NSRect(x: 24 + (552 - previewSize.width) / 2, y: 306 + (354 - previewSize.height) / 2, width: previewSize.width, height: previewSize.height)
        captureButton.primary = source == nil
        captureButton.needsDisplay = true
        guard source != nil || textMode else { composition = nil; preview.image = nil; emptyLabel.isHidden = false; copyButton.isEnabled = false; saveButton.isEnabled = false; return }
        emptyLabel.isHidden = true
        do {
            composition = try composer.compose(source, caption: caption.string, format: format, background: background, framing: framing, header: selectedHeader, footerURL: selectedURL, mainText: textMode ? quoteEditor.string : nil, exportLogo: ownStyle.logo)
            if let crop = composition?.framing { framing = crop }
            if let rect = composition?.imageRect {
                preview.sourceFrame = NSRect(x: rect.minX * scale, y: (preview.isFlipped ? format.size.height - rect.maxY : rect.minY) * scale, width: rect.width * scale, height: rect.height * scale)
            }
            preview.image = composition?.image
            copyButton.isEnabled = true; saveButton.isEnabled = true
            status.stringValue = shortcutReady ? "Klaar om te delen.\nSluit dit venster: de sneltoets blijft werken." : "Klaar om te delen. Gebruik Nieuwe screenshot; de sneltoets is al in gebruik."
        } catch {
            composition = nil
            preview.image = nil
            copyButton.isEnabled = false; saveButton.isEnabled = false
            status.stringValue = error.localizedDescription
        }
    }
    @objc func copyImage() {
        guard let composition else { return }
        let item = NSPasteboardItem(); item.setData(composition.png, forType: .png)
        if let tiff = composition.image.tiffRepresentation { item.setData(tiff, forType: .tiff) }
        let board = NSPasteboard.general; board.clearContents()
        status.stringValue = board.writeObjects([item]) ? "Beeld gekopieerd. Plak het in je bericht of publicatie." : "Kopiëren is niet gelukt. Gebruik Bewaar PNG."
    }
    @objc func save() {
        guard let composition else { return }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.png]
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        panel.nameFieldStringValue = "fmt-screenshot-\(formatter.string(from: Date()))-\(format.rawValue)-\(background.rawValue).png"
        panel.beginSheetModal(for: window) { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            do {
                try composition.png.write(to: url, options: .atomic)
                guard try Data(contentsOf: url) == composition.png else { throw AppError.message("Het bewaarde beeld kon niet worden gecontroleerd.") }
                self?.status.stringValue = "PNG bewaard: \(url.lastPathComponent)"
            } catch { self?.status.stringValue = "Bewaren mislukt: \(error.localizedDescription)" }
        }
    }
    func persist() {
        persistFraming()
        do {
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            if let data = source?.tiffRepresentation { try data.write(to: storage.appendingPathComponent("laatste-screenshot.tiff"), options: .atomic) }
            let contentState = ["mode": textMode ? "text" : "screenshot", "text": quoteEditor.string]
            try JSONSerialization.data(withJSONObject: contentState).write(to: storage.appendingPathComponent("laatste-inhoud.json"), options: .atomic)
            try caption.string.write(to: storage.appendingPathComponent("laatste-tekst.txt"), atomically: true, encoding: .utf8)
            try format.rawValue.write(to: storage.appendingPathComponent("laatste-formaat.txt"), atomically: true, encoding: .utf8)
            try background.rawValue.write(to: storage.appendingPathComponent("laatste-achtergrond.txt"), atomically: true, encoding: .utf8)
        } catch { status.stringValue = "Je beeld werkt, maar kon niet voor heropenen worden onthouden. Bewaar een PNG.\n\(error.localizedDescription)" }
    }
    func restore() {
        if let data = try? Data(contentsOf: storage.appendingPathComponent("laatste-inhoud.json")),
           let state = (try? JSONSerialization.jsonObject(with: data)) as? [String: String] {
            contentChoice.selectItem(at: state["mode"] == "text" ? 1 : 0)
            quoteEditor.string = state["text"] ?? ""
        }
        if let data = try? Data(contentsOf: storage.appendingPathComponent("eigen-stijl.json")),
           let saved = try? JSONDecoder().decode(OwnStyle.self, from: data) { ownStyle = saved }
        if let data = try? Data(contentsOf: storage.appendingPathComponent("laatste-kader.json")), let saved = try? JSONDecoder().decode(Framing.self, from: data) { framing = saved; framing.clamp() }
        source = NSImage(contentsOf: storage.appendingPathComponent("laatste-screenshot.tiff"))
        caption.string = (try? String(contentsOf: storage.appendingPathComponent("laatste-tekst.txt"), encoding: .utf8)) ?? ""
        if let saved = try? String(contentsOf: storage.appendingPathComponent("laatste-formaat.txt"), encoding: .utf8), let choice = ExportFormat(rawValue: saved) { format = choice }
        if let saved = try? String(contentsOf: storage.appendingPathComponent("laatste-achtergrond.txt"), encoding: .utf8), let choice = Background(rawValue: saved) { background = choice }
        refresh()
    }
}

if CommandLine.arguments.count >= 4 && CommandLine.arguments[1] == "--render" {
    do {
        try loadFont()
        let args = CommandLine.arguments
        guard let image = args[2] == "--text" ? NSImage(size: NSSize(width: 1, height: 1)) : NSImage(contentsOfFile: args[2]) else { throw AppError.message("Geen geldig bronbeeld.") }
        let requested = args.count > 5 ? args[5] : ExportFormat.square.rawValue
        guard let format = ExportFormat(rawValue: requested) else { throw AppError.message("Onbekend formaat; gebruik 1x1, 16x9 of 9x16.") }
        guard let background = Background(rawValue: args.count > 6 ? args[6] : "wit") else { throw AppError.message("Onbekende achtergrond; gebruik wit, zwart of rood.") }
        let result = try Composer().compose(image, caption: args.count > 4 ? args[4] : "", format: format, background: background, header: args.count > 7 ? args[7] : "", footerURL: args.count > 8 ? args[8] : "", mainText: args[2] == "--text" ? (args.count > 9 ? args[9] : "") : nil, exportLogo: args.count > 10 ? NSImage(contentsOfFile: args[10]) : nil)
        try result.png.write(to: URL(fileURLWithPath: args[3]), options: .atomic)
        print("\(format.pixels); font=\(Style.brandName); image=\(result.imageRect); caption=\(result.captionRect); bytes=\(result.png.count)")
    } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else {
    let application = NSApplication.shared
    application.setActivationPolicy(.regular)
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
