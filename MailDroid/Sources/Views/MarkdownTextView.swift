import SwiftUI

/// A reusable view that renders common markdown elements as native SwiftUI views.
///
/// Supported elements include headers, bold, italic, bullet lists, numbered lists,
/// fenced code blocks, inline code, links, and regular paragraphs.
struct MarkdownTextView: View {
    let markdown: String
    var baseFontSize: CGFloat = 14

    private var blocks: [MarkdownBlock] {
        MarkdownBlockParser.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .header(let level, let text):
            headerView(level: level, text: text)
        case .paragraph(let text):
            inlineMarkdownText(text)
                .font(.system(size: baseFontSize))
                .lineSpacing(4)
        case .bulletList(let items):
            bulletListView(items: items)
        case .numberedList(let items):
            numberedListView(items: items)
        case .codeBlock(let code):
            codeBlockView(code: code)
        }
    }

    private func headerView(level: Int, text: String) -> some View {
        let fontSize: CGFloat
        let weight: Font.Weight
        switch level {
        case 1:
            fontSize = baseFontSize + 8
            weight = .bold
        case 2:
            fontSize = baseFontSize + 4
            weight = .bold
        default:
            fontSize = baseFontSize + 2
            weight = .semibold
        }
        return inlineMarkdownText(text)
            .font(.system(size: fontSize, weight: weight))
            .padding(.top, level == 1 ? 4 : 2)
    }

    private func bulletListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\u{2022}")
                        .font(.system(size: baseFontSize))
                    inlineMarkdownText(item)
                        .font(.system(size: baseFontSize))
                        .lineSpacing(3)
                }
            }
        }
        .padding(.leading, 8)
    }

    private func numberedListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(index + 1).")
                        .font(.system(size: baseFontSize))
                        .monospacedDigit()
                    inlineMarkdownText(item)
                        .font(.system(size: baseFontSize))
                        .lineSpacing(3)
                }
            }
        }
        .padding(.leading, 8)
    }

    private func codeBlockView(code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(size: baseFontSize - 1, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func inlineMarkdownText(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(text)
    }
}

// MARK: - Markdown Block Types

/// Represents a parsed block-level markdown element.
enum MarkdownBlock {
    case header(level: Int, text: String)
    case paragraph(text: String)
    case bulletList(items: [String])
    case numberedList(items: [String])
    case codeBlock(code: String)
}

// MARK: - Markdown Block Parser

/// Parses a markdown string into an array of block-level elements.
enum MarkdownBlockParser {

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line: skip.
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Fenced code block.
            if trimmed.hasPrefix("```") {
                let codeLines = collectCodeBlock(lines: lines, startIndex: &index)
                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n")))
                continue
            }

            // Header.
            if let header = parseHeader(trimmed) {
                blocks.append(header)
                index += 1
                continue
            }

            // Bullet list.
            if isBulletListItem(trimmed) {
                let items = collectBulletList(lines: lines, startIndex: &index)
                blocks.append(.bulletList(items: items))
                continue
            }

            // Numbered list.
            if isNumberedListItem(trimmed) {
                let items = collectNumberedList(lines: lines, startIndex: &index)
                blocks.append(.numberedList(items: items))
                continue
            }

            // Paragraph: collect consecutive non-empty, non-special lines.
            let paragraphLines = collectParagraph(lines: lines, startIndex: &index)
            let text = paragraphLines.joined(separator: "\n")
            blocks.append(.paragraph(text: text))
        }

        return blocks
    }

    // MARK: - Header

    private static func parseHeader(_ line: String) -> MarkdownBlock? {
        let patterns: [(prefix: String, level: Int)] = [
            ("### ", 3),
            ("## ", 2),
            ("# ", 1),
        ]
        for pattern in patterns {
            if line.hasPrefix(pattern.prefix) {
                let text = String(line.dropFirst(pattern.prefix.count))
                return .header(level: pattern.level, text: text)
            }
        }
        return nil
    }

    // MARK: - Bullet List

    private static func isBulletListItem(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ")
    }

    private static func collectBulletList(lines: [String], startIndex: inout Int) -> [String] {
        var items: [String] = []
        while startIndex < lines.count {
            let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
            if isBulletListItem(trimmed) {
                items.append(String(trimmed.dropFirst(2)))
                startIndex += 1
            } else if trimmed.isEmpty {
                // A blank line ends the list.
                startIndex += 1
                break
            } else {
                break
            }
        }
        return items
    }

    // MARK: - Numbered List

    private static func isNumberedListItem(_ line: String) -> Bool {
        guard let dotIndex = line.firstIndex(of: ".") else { return false }
        let prefix = line[line.startIndex..<dotIndex]
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else { return false }
        let afterDot = line.index(after: dotIndex)
        return afterDot < line.endIndex && line[afterDot] == " "
    }

    private static func collectNumberedList(lines: [String], startIndex: inout Int) -> [String] {
        var items: [String] = []
        while startIndex < lines.count {
            let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
            if isNumberedListItem(trimmed) {
                if let dotIndex = trimmed.firstIndex(of: ".") {
                    let textStart = trimmed.index(dotIndex, offsetBy: 2)
                    if textStart <= trimmed.endIndex {
                        items.append(String(trimmed[textStart...]))
                    }
                }
                startIndex += 1
            } else if trimmed.isEmpty {
                startIndex += 1
                break
            } else {
                break
            }
        }
        return items
    }

    // MARK: - Code Block

    private static func collectCodeBlock(lines: [String], startIndex: inout Int) -> [String] {
        // Skip the opening ``` line.
        startIndex += 1
        var codeLines: [String] = []
        while startIndex < lines.count {
            let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                startIndex += 1
                break
            }
            codeLines.append(lines[startIndex])
            startIndex += 1
        }
        return codeLines
    }

    // MARK: - Paragraph

    private static func collectParagraph(lines: [String], startIndex: inout Int) -> [String] {
        var paragraphLines: [String] = []
        while startIndex < lines.count {
            let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty
                || trimmed.hasPrefix("```")
                || parseHeader(trimmed) != nil
                || isBulletListItem(trimmed)
                || isNumberedListItem(trimmed)
            {
                break
            }
            paragraphLines.append(lines[startIndex])
            startIndex += 1
        }
        return paragraphLines
    }
}
