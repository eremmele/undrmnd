import SwiftUI
import UIKit

// MARK: - Territory map (ported from `TerritoryMapScreen` in `undrmnd-screens.tsx`)

/// Tap targets for nodes on the sketch map; coordinates match the 260×300 canvas, then the stack is scaled.
private struct MapDot: Identifiable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let hitRadius: CGFloat
    let pillar: Pillar
    let accessLabel: String
}

private struct TerritoryMapViteGraphic: View {
    let onSelectPillar: (Pillar) -> Void

    private static let baseDots: [MapDot] = [
        MapDot(id: "lw-40", x: 130, y: 40, hitRadius: 20, pillar: .livingWorld, accessLabel: "Living World topic"),
        MapDot(id: "lw-90", x: 130, y: 90, hitRadius: 18, pillar: .livingWorld, accessLabel: "Living World topic"),
        MapDot(id: "lw-140", x: 130, y: 140, hitRadius: 18, pillar: .livingWorld, accessLabel: "Living World topic"),
        MapDot(id: "lw-80-180", x: 80, y: 180, hitRadius: 18, pillar: .livingWorld, accessLabel: "Living World topic"),
        MapDot(id: "hwk-180", x: 130, y: 180, hitRadius: 16, pillar: .howWeKnow, accessLabel: "How we know topic"),
        MapDot(id: "mb-180", x: 180, y: 180, hitRadius: 16, pillar: .mindAndBrain, accessLabel: "Mind and brain topic"),
        MapDot(id: "here", x: 80, y: 210, hitRadius: 22, pillar: .livingWorld, accessLabel: "You are here, Living World"),
        MapDot(id: "mb-60", x: 200, y: 60, hitRadius: 16, pillar: .mindAndBrain, accessLabel: "Mind and brain topic"),
        MapDot(id: "mb-100", x: 200, y: 100, hitRadius: 16, pillar: .mindAndBrain, accessLabel: "Mind and brain topic"),
        MapDot(id: "mb-140", x: 200, y: 140, hitRadius: 16, pillar: .mindAndBrain, accessLabel: "Mind and brain topic"),
        MapDot(id: "cs-50", x: 50, y: 260, hitRadius: 14, pillar: .cosmos, accessLabel: "Cosmos topic"),
        MapDot(id: "hwk-270", x: 80, y: 270, hitRadius: 14, pillar: .howWeKnow, accessLabel: "How we know topic"),
        MapDot(id: "cs-110", x: 110, y: 265, hitRadius: 14, pillar: .cosmos, accessLabel: "Cosmos topic")
    ]

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

                // Cluster A
                strokeLine(130, 40, 130, 90, color: UndrmndPrototypeTheme.secondary, width: 1.5)
                strokeLine(130, 90, 130, 140, color: UndrmndPrototypeTheme.secondary, width: 1.5)
                strokeLine(130, 140, 80, 180, color: UndrmndPrototypeTheme.primary, width: 1.5)
                strokeLine(130, 140, 130, 180, color: UndrmndPrototypeTheme.divider, width: 1)
                strokeLine(130, 140, 180, 180, color: UndrmndPrototypeTheme.divider, width: 1)
                strokeLine(80, 180, 80, 210, color: UndrmndPrototypeTheme.primary, width: 1.5)

                // Cluster B
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

            Text("Living World")
                .font(AppFont.mapLabel(approxSize: 10, mapWeight: .medium))
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .position(x: 130, y: 28)

            Text("You are here")
                .font(AppFont.mapLabel(approxSize: 8, mapWeight: .medium))
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .position(x: 80, y: 228)

            Text("Mind & Brain")
                .font(AppFont.mapLabel(approxSize: 9, mapWeight: .regular))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 200, y: 48)

            Text("2 / 5")
                .font(AppFont.mapLabel(approxSize: 8, mapWeight: .regular))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 200, y: 158)

            Text("Communities")
                .font(AppFont.mapLabel(approxSize: 7, mapWeight: .regular))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 130, y: 196)

            Text("Coping")
                .font(AppFont.mapLabel(approxSize: 7, mapWeight: .regular))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 180, y: 196)

            Text("Adjacent paths…")
                .font(AppFont.mapLabel(approxSize: 8, mapWeight: .regular))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .position(x: 80, y: 290)

            ForEach(Self.baseDots) { dot in
                Button {
                    onSelectPillar(dot.pillar)
                } label: {
                    Color.clear
                        .frame(width: dot.hitRadius * 2, height: dot.hitRadius * 2)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(x: dot.x, y: dot.y)
                .accessibilityLabel(Text(dot.accessLabel))
            }
        }
        .frame(width: 260, height: 300)
        .scaleEffect(1.35)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Territory map sketch; tap a dot for a topic.")
    }
}

struct TerritoryMapPlaceholderView: View {
    var onSelectPillar: (Pillar) -> Void = { _ in }
    /// When non-nil, shows a **Done** button (e.g. when the map is presented in a sheet).
    var onMapDismiss: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack {
                    Spacer(minLength: 0)
                    TerritoryMapViteGraphic(onSelectPillar: onSelectPillar)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: max(360, geo.size.height * 0.72))
                    Spacer(minLength: 0)
                }
                VStack(spacing: 4) {
                    Text("Your accumulated understanding")
                        .font(AppFont.captionEmphasis)
                        .foregroundStyle(UndrmndPrototypeTheme.primary.opacity(0.88))
                    Text("2 topics · 1 completed branch · 1 in progress")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(16)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(UndrmndPrototypeTheme.divider)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Your Map")
        .toolbar {
            if let onMapDismiss {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onMapDismiss) {
                        Text("Done")
                            .undrmndShellCtaTextStyle()
                    }
                }
            }
        }
    }
}

// MARK: - Nearby (local meetup / event links)

private struct PublicEventRow: Identifiable {
    let id = UUID()
    let title: String
    let whenWhere: String
    let source: String
    let url: URL
}

struct NearbyEventsView: View {
    private let events: [PublicEventRow] = [
        PublicEventRow(
            title: "Astronomy on Tap: public talks at a local pub",
            whenWhere: "Next Tuesday · 7:00 PM · River District",
            source: "Meetup",
            url: URL(string: "https://www.meetup.com/find/?source=EVENTS&location=astronomy")!
        ),
        PublicEventRow(
            title: "Field sketching: winter buds & ID tips",
            whenWhere: "Saturday · 10:00 AM · City botanical garden",
            source: "Eventbrite",
            url: URL(string: "https://www.eventbrite.com/d/online/nature/")!
        ),
        PublicEventRow(
            title: "Civic data night: map the noise with open tools",
            whenWhere: "First Thursday · 6:30 PM · Public library",
            source: "Meetup",
            url: URL(string: "https://www.meetup.com/find/?source=EVENTS&location=civic%20data")!
        ),
        PublicEventRow(
            title: "“Ask a scientist”: middle school Q&A (volunteer hosts)",
            whenWhere: "Virtual · RSVP for link",
            source: "Eventbrite",
            url: URL(string: "https://www.eventbrite.com/d/online/science/")!
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Based on your goals, here are a few events in your local community.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(events) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(e.title)
                            .font(AppFont.headline)
                        Text(e.whenWhere)
                            .font(AppFont.subheadline)
                        Text(e.source)
                            .font(AppFont.caption2)
                            .foregroundStyle(sourceListColor(e.source))
                        Link(destination: e.url) {
                            HStack(spacing: 5) {
                                Text("RSVP")
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .font(.system(.subheadline))
                            .foregroundStyle(UndrmndPrototypeTheme.accent)
                        }
                        .accessibilityLabel("RSVP, opens in browser")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                }
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Nearby")
    }

    private func sourceListColor(_ source: String) -> Color {
        if source == "Meetup" {
            return UndrmndPrototypeTheme.secondary
        }
        return UndrmndPrototypeTheme.muted
    }
}

// MARK: - Profile

struct ProfilePlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile")
                    .font(AppFont.title2)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)

                Text("Minimal account details only, in line with the project’s privacy rules.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Profile")
    }
}

// MARK: - Search

struct SearchPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    /// Tapping a term opens the matching in-app “content page” (pillar session or goal flow).
    var onNavigate: (HomeRoute) -> Void

    @State private var searchQuery: String = ""
    @FocusState private var isSearchFieldFocused: Bool

    private let presets: [(String, HomeRoute)] = [
        ("Cosmos", .threeCard(.cosmos)),
        ("Living World", .threeCard(.livingWorld)),
        ("Mind & Brain", .threeCard(.mindAndBrain)),
        ("How We Know", .threeCard(.howWeKnow)),
        ("Set a goal and find a path", .goalClarifier)
    ]

    private var filteredPresets: [(String, HomeRoute)] {
        let t = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return presets }
        return presets.filter { $0.0.localizedCaseInsensitiveContains(t) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Search paths, topics, communities")
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                            TextField("Type to filter, or open a result below", text: $searchQuery)
                                .textFieldStyle(.plain)
                                .font(AppFont.body)
                                .focused($isSearchFieldFocused)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                                .keyboardType(.default)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(UndrmndPrototypeTheme.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                    }

                    Text("Jump to a topic or flow")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)

                    if filteredPresets.isEmpty, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No matches for that search.")
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }

                    ForEach(filteredPresets, id: \.0) { label, route in
                        Button {
                            onNavigate(route)
                            dismiss()
                        } label: {
                            HStack {
                                Text(label)
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFont.caption)
                                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open \(label)")
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
            .navigationTitleBrand("Search")
            .onAppear {
                // After the sheet has presented; otherwise focus can fail during transition.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isSearchFieldFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .undrmndShellCtaTextStyle()
                    }
                }
            }
        }
        .appShellNavigationToolbar()
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
                        .font(AppFont.mapLabel(approxSize: 10, mapWeight: .medium))
                        .tracking(0.08)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text(path.title)
                        .font(AppFont.title3)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT YOU EXPLORED")
                        .font(AppFont.mapLabel(approxSize: 10, mapWeight: .medium))
                        .tracking(0.05)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    ForEach(Array(path.exploredNuggetTitles.prefix(3).enumerated()), id: \.offset) { _, title in
                        Text("· \(title)")
                            .font(AppFont.caption)
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
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text("“\(path.carryQuote)”")
                        .font(AppFont.caption)
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
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    TextField("Optional. For you, not for us", text: $reflection, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .font(AppFont.caption)
                }

                if !trailheadChosen {
                    if !trailheadExpanded {
                        Button {
                            trailheadExpanded = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(AppFont.caption)
                                Text("Set a time to return")
                                    .font(AppFont.caption)
                            }
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose when you might return")
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When would you like to continue?")
                                .font(AppFont.captionEmphasis)
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
                            .font(AppFont.caption)
                        Text("Noted for your own reference. The app will not nudge you with reminders.")
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR MAP IS GROWING")
                        .font(AppFont.mapLabel(approxSize: 10, mapWeight: .medium))
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text(path.closingTerritoryBlurb)
                        .font(AppFont.caption)
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
                        .font(AppFont.subheadlineEmphasis)
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
                        .font(AppFont.caption2Medium)
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
