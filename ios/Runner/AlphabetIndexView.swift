import SwiftUI
import UIKit

public struct AlphabetIndexView: View {
    public static let defaultLetters: [String] = ["#"] + Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

    public let letters: [String]
    public var onLetterChanged: (String) -> Void
    public var onLetterSelected: ((String) -> Void)?

    @State private var currentLetter: String?
    @State private var isDragging: Bool = false

    public init(
        letters: [String] = AlphabetIndexView.defaultLetters,
        onLetterChanged: @escaping (String) -> Void,
        onLetterSelected: ((String) -> Void)? = nil
    ) {
        self.letters = letters
        self.onLetterChanged = onLetterChanged
        self.onLetterSelected = onLetterSelected
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                // The vertical stack of letters
                VStack(spacing: 0) {
                    ForEach(letters, id: \.self) { letter in
                        letterCell(letter, in: geo.size)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Letter bubble overlay when dragging
                if let letter = currentLetter, isDragging {
                    LetterBubble(letter: letter)
                        .transition(.scale.combined(with: .opacity))
                        .offset(x: -80)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChange(at: value.location, in: geo.size)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
        .frame(width: 28)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alphabet index")
        .accessibilityHint("Swipe up or down to navigate letters")
        .accessibilityActions {
            Button("Next letter") { navigateToNextLetter() }
            Button("Previous letter") { navigateToPreviousLetter() }
        }
    }

    private func handleDragChange(at location: CGPoint, in size: CGSize) {
        let letter = letter(at: location, in: size)
        guard currentLetter != letter else { return }

        currentLetter = letter
        isDragging = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onLetterChanged(letter)
    }

    private func handleDragEnd() {
        if let letter = currentLetter {
            onLetterSelected?(letter)
        }
        isDragging = false
        currentLetter = nil
    }

    private func navigateToNextLetter() {
        guard let current = currentLetter ?? letters.first else { return }
        if let idx = letters.firstIndex(of: current) {
            let nextIndex = min(idx + 1, letters.count - 1)
            let letter = letters[nextIndex]
            currentLetter = letter
            onLetterChanged(letter)
        }
    }

    private func navigateToPreviousLetter() {
        guard let current = currentLetter ?? letters.first else { return }
        if let idx = letters.firstIndex(of: current) {
            let nextIndex = max(idx - 1, 0)
            let letter = letters[nextIndex]
            currentLetter = letter
            onLetterChanged(letter)
        }
    }

    private func letter(at location: CGPoint, in size: CGSize) -> String {
        let height = max(size.height, 1)
        let step = height / CGFloat(letters.count)
        var index = Int(floor(location.y / step))
        index = max(0, min(letters.count - 1, index))
        return letters[index]
    }

    private func letterFont(for size: CGSize) -> Font {
        let rowHeight = size.height / CGFloat(max(letters.count, 1))
        let pointSize = max(10, min(16, rowHeight * 0.8))
        return .system(size: pointSize, weight: .semibold, design: .rounded)
    }

    @ViewBuilder
    private func letterCell(_ letter: String, in size: CGSize) -> some View {
        let rowHeight = size.height / CGFloat(max(letters.count, 1))
        let isCurrent = (currentLetter == letter) && isDragging
        let bubbleDiameter = max(20, min(28, rowHeight * 0.9))

        Text(letter)
            .font(letterFont(for: size))
            .foregroundStyle(isCurrent ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .background(
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: bubbleDiameter, height: bubbleDiameter)
                    .opacity(isCurrent ? 1 : 0)
            )
            .contentShape(Rectangle())
            .accessibilityLabel("Jump to letter \(letter)")
    }
}

private struct LetterBubble: View {
    let letter: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
            Text(letter)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(width: 80, height: 80)
    }
}

#Preview("AlphabetIndexView") {
    VStack {
        Spacer()
        HStack(alignment: .center) {
            Spacer()
            AlphabetIndexView { letter in
                print("Changed ->", letter)
            } onLetterSelected: { letter in
                print("Selected ->", letter)
            }
            .frame(height: 400)
            .background(Color(UIColor.systemGroupedBackground))
        }
        Spacer()
    }
    .padding()
}
