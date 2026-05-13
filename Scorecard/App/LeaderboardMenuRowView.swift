import AppKit

/// Custom `NSView` used as the `view` of a compact-mode leaderboard menu
/// item. Hosts a single non-selectable text field with monospaced-digit
/// attributed text and tab-stop column alignment. Drawing the row this way
/// keeps the text at `labelColor` opacity even though the parent menu item
/// is marked `isEnabled = false` (which is what suppresses the menu's hover
/// highlight and click-to-close).
final class LeaderboardMenuRowView: NSView {
    private static let rowHeight: CGFloat = 22
    private static let rowWidth: CGFloat = 280
    private static let leadingInset: CGFloat = 18
    private static let trailingInset: CGFloat = 12

    private let label: NSTextField

    init(entry: LeaderboardEntry, isStarred: Bool) {
        self.label = NSTextField(labelWithString: "")
        super.init(frame: NSRect(x: 0, y: 0, width: Self.rowWidth, height: Self.rowHeight))
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        label.usesSingleLineMode = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingInset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.trailingInset),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        label.attributedStringValue = Self.attributedString(for: entry, isStarred: isStarred)
    }

    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) unavailable")
    }

    private static func attributedString(for entry: LeaderboardEntry, isStarred: Bool) -> NSAttributedString {
        let star = isStarred ? "★" : " "
        let scoreString = LeaderboardEntry.formatToPar(entry.scoreToPar)
        let title = "\(entry.positionDisplay)\t\(star)\t\(entry.playerName)\t\(scoreString)\t\(entry.thruDisplay)"

        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .left, location: 32, options: [:]),    // star
            NSTextTab(textAlignment: .left, location: 48, options: [:]),    // name
            NSTextTab(textAlignment: .right, location: 210, options: [:]),  // score
            NSTextTab(textAlignment: .right, location: 250, options: [:]),  // thru
        ]
        paragraph.defaultTabInterval = 250
        paragraph.lineBreakMode = .byTruncatingTail

        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let result = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: NSColor.labelColor,
            ]
        )

        // Tint under-par scores with the accent colour so the leaders pop.
        if let s = entry.scoreToPar, s < 0,
           let scoreRange = title.range(of: "\t\(scoreString)\t") {
            let ns = NSRange(scoreRange, in: title)
            let adjusted = NSRange(location: ns.location + 1, length: scoreString.count)
            result.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: adjusted)
        }

        // Secondary tint on the "thru" column so it reads as a supporting detail.
        if let thruRange = title.range(of: "\t\(entry.thruDisplay)", options: .backwards) {
            let ns = NSRange(thruRange, in: title)
            let adjusted = NSRange(location: ns.location + 1, length: entry.thruDisplay.count)
            result.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: adjusted)
        }

        return result
    }
}
