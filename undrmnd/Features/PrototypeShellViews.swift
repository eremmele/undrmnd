import SwiftUI
import UIKit

// MARK: - Territory map (ported from `TerritoryMapScreen` in `undrmnd-screens.tsx`)

private struct TerritoryMapViteGraphic: View {
    var body: some View {
        ZStack {
            Canvas { context, _ in
                func strokeLine(
                    _ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                    color: Color,
                    width: CGFloat = 1,
                    dash: [CGFloat] = []
                ) {
                    var p = Path()
                    p.move(to: CGPoint(x: x1, y: y1))
                    p.addLine(to: CGPoint(x: x2, y: y2))
                    context.stroke(
                        p,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: width, dash: dash)
                    )
                }

                // Climate Anxiety cluster
                strokeLine(130, 40, 130, 90, color: UndrmndPrototypeTheme.secondary, width: 1.5)
                strokeLine(130, 90, 130, 140, color: UndrmndPrototypeTheme.secondary, width: 1.5)
                strokeLine(130, 140, 80, 180, color: UndrmndPrototypeTheme.primary, width: 1.5)
                strokeLine(130, 140, 130, 180, color: UndrmndPrototypeTheme.divider, width: 1)
                strokeLine(130, 140, 180, 180, color: UndrmndPrototypeTheme.divider, width: 1)
                strokeLine(80, 180, 80, 210, color: UndrmndPrototypeTheme.primary, width: 1.5)

                // ADHD cluster
                strokeLine(200, 60, 200, 100, color: UndrmndPrototypeTheme.muted, width: 1, dash: [3, 3])
                strokeLine(200, 100, 200, 140, color: UndrmndPrototypeTheme.muted, width: 1, dash: [3, 3])

                // Cross-link
                strokeLine(130, 90, 200, 100, color: UndrmndPrototypeTheme.divider, width: 1, dash: [4, 4])

                func fillCircle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, color: Color) {
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.fill(Circle().path(in: rect), with: .color(color))
                }

                func strokeCircle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, color: Color, width: CGFloat = 1.5, dash: [CGFloat] = []) {
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.stroke(
                        Circle().path(in: rect),
                        with: .color(color),
                        style: StrokeStyle(lineWidth: width, dash: dash)
                    )
                }

                fillCircle(130, 40, 7, color: UndrmndPrototypeTheme.secondary)
                fillCircle(130, 90, 7, color: UndrmndPrototypeTheme.secondary)
                fillCircle(130, 140, 7, color: UndrmndPrototypeTheme.secondary)
                fillCircle(80, 180, 7, color: UndrmndPrototypeTheme.secondary)
                strokeCircle(130, 180, 6, color: UndrmndPrototypeTheme.divider, width: 1.5)
                strokeCircle(180, 180, 6, color: UndrmndPrototypeTheme.divider, width: 1.5)
                fillCircle(80, 210, 8, color: UndrmndPrototypeTheme.primary)

                fillCircle(200, 60, 5, color: UndrmndPrototypeTheme.muted)
                fillCircle(200, 100, 5, color: UndrmndPrototypeTheme.muted)
                strokeCircle(200, 140, 5, color: UndrmndPrototypeTheme.muted, width: 1)

                strokeCircle(50, 260, 4, color: UndrmndPrototypeTheme.divider, width: 1, dash: [2, 2])
                strokeCircle(80, 270, 4, color: UndrmndPrototypeTheme.divider, width: 1, dash: [2, 2])
                strokeCircle(110, 265, 4, color: UndrmndPrototypeTheme.divider, width: 1, dash: [2, 2])
            }

            Text("Climate Anxiety")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .position(x: 130, y: 28)

            Text("You are here")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .position(x: 80, y: 228)

            Text("ADHD")
                .font(.system(size: 9))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 200, y: 48)

            Text("2 / 5")
                .font(.system(size: 8))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 200, y: 158)

            Text("Communities")
                .font(.system(size: 7))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 130, y: 196)

            Text("Coping")
                .font(.system(size: 7))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 180, y: 196)

            Text("Adjacent paths…")
                .font(.system(size: 8))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 80, y: 290)
        }
        .frame(width: 260, height: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Territory map sketch with Climate Anxiety path and ADHD path in progress")
    }
}

struct TerritoryMapPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TerritoryMapViteGraphic()

                VStack(spacing: 4) {
                    Text("Your accumulated understanding")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    Text("2 topics · 1 completed branch · 1 in progress")
                        .font(.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Your Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Campfire

struct CampfirePlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer(minLength: 0)
                    Text("Climate Science")
                        .font(.system(size: 9))
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }

                Text("Is climate doomerism helpful?")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("14 contributions · via Climate Anxiety path")
                    .font(.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)

                Text("Thread bodies and replies will load from your backend later — this headline matches the Vite prototype.")
                    .font(.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Campfire")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Nearby

struct NearbyPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Communities and events near you will show up here with explicit consent — never silent tracking.")
                    .font(.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Nearby")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile

struct ProfilePlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)

                Text("Minimal account details only — aligned with the project’s privacy rules.")
                    .font(.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Search

struct SearchPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    private let recent = ["Climate anxiety", "ADHD", "Digital wellbeing"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search paths, topics, communities…")
                            .font(.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )

                    Text("Recent")
                        .font(.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)

                    ForEach(recent, id: \.self) { term in
                        Text(term)
                            .font(.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(UndrmndPrototypeTheme.divider)
                                    .frame(height: 1)
                            }
                    }
                }
                .padding(16)
            }
            .background(UndrmndPrototypeTheme.paper)
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Closing (from `ClosingScreen` in `undrmnd-screens.tsx`)

struct ClosingSessionSheet: View {
    let path: WalkPath
    var onDismiss: () -> Void

    @State private var reflection: String = ""
    @State private var trailheadExpanded: Bool = false
    @State private var trailheadChosen: Bool = false

    private let trailheadOptions = ["Tomorrow morning", "This weekend", "In a few days", "No plan"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Rectangle()
                    .fill(UndrmndPrototypeTheme.divider)
                    .frame(height: 1)

                VStack(spacing: 8) {
                    Text("SESSION COMPLETE")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.08)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text(path.title)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT YOU EXPLORED")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.05)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    ForEach(Array(path.exploredNuggetTitles.prefix(3).enumerated()), id: \.offset) { _, title in
                        Text("· \(title)")
                            .font(.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Something to carry with you")
                        .font(.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text("“\(path.carryQuote)”")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.muted, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("What will you remember from today?")
                        .font(.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    TextField("Optional — for you, not for us", text: $reflection, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .font(.caption)
                }

                if !trailheadChosen {
                    if !trailheadExpanded {
                        Button {
                            trailheadExpanded = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("Set a time to return")
                                    .font(.caption)
                            }
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose when you might return")
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When would you like to continue?")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                            FlowTrailheadTags(options: trailheadOptions) {
                                trailheadChosen = true
                                trailheadExpanded = false
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(UndrmndPrototypeTheme.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                        )
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                        Text("Noted for your own reference — no automatic reminders from the app.")
                            .font(.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR MAP IS GROWING")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text(path.closingTerritoryBlurb)
                        .font(.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                )

                Button {
                    onDismiss()
                } label: {
                    Text("Close session")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(UndrmndPrototypeTheme.paper)
                        .background(UndrmndPrototypeTheme.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close session and return")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(UndrmndPrototypeTheme.paper)
    }
}

private struct FlowTrailheadTags: View {
    let options: [String]
    var onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(options, id: \.self) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect()
                } label: {
                    Text(option)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .background(UndrmndPrototypeTheme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(UndrmndPrototypeTheme.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
