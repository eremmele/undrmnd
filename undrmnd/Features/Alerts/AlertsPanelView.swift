import Foundation
import SwiftUI

// MARK: - Model (on-device only; no remote push)

struct AppAlertItem: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var body: String
    var date: Date
    var isRead: Bool
}

// MARK: - Store

@MainActor
final class AlertsStore: ObservableObject {
    @Published private(set) var items: [AppAlertItem] = []

    private let readIdsKey = "app_alert_read_ids_v1"

    var unreadCount: Int { items.filter { !$0.isRead }.count }

    init() {
        refreshFromBuiltInList()
    }

    private static func builtInAlerts(at now: Date) -> [AppAlertItem] {
        let cal = Calendar.current
        return [
            AppAlertItem(
                id: UUID(uuidString: "C0000001-0000-4000-8000-000000000001")!,
                title: "Welcome to the room",
                body: "undrmnd is session-based: when you’re done, you can leave without a streak or score nudging you back.",
                date: cal.date(byAdding: .day, value: -1, to: now) ?? now,
                isRead: false
            ),
            AppAlertItem(
                id: UUID(uuidString: "C0000001-0000-4000-8000-000000000002")!,
                title: "Paths you open are remembered on this device",
                body: "“Resume a path” and the path map use local memory only in this build — nothing leaves your phone without you choosing it.",
                date: cal.date(byAdding: .hour, value: -6, to: now) ?? now,
                isRead: false
            ),
            AppAlertItem(
                id: UUID(uuidString: "C0000001-0000-4000-8000-000000000003")!,
                title: "Contribute replies stay local for now",
                body: "Thread replies are a calm default until shared threads are wired. Nothing is sent to a server in this build.",
                date: now,
                isRead: false
            )
        ]
    }

    private func refreshFromBuiltInList() {
        var list = Self.builtInAlerts(at: Date())
        applyReadState(to: &list)
        items = list
    }

    private var readIdSet: Set<UUID> {
        let d = UserDefaults.standard.data(forKey: readIdsKey) ?? Data()
        return (try? JSONDecoder().decode([UUID].self, from: d)).map { Set($0) } ?? []
    }

    private func applyReadState(to list: inout [AppAlertItem]) {
        let s = readIdSet
        for i in list.indices {
            list[i].isRead = s.contains(list[i].id)
        }
    }

    private func persistReadState() {
        let ids = items.filter(\.isRead).map(\.id)
        if let d = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(d, forKey: readIdsKey)
        }
    }

    func markRead(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var row = items[i]
        guard !row.isRead else { return }
        row.isRead = true
        items[i] = row
        persistReadState()
    }

    func markAllRead() {
        items = items.map { var c = $0; c.isRead = true; return c }
        persistReadState()
    }
}

// MARK: - Panel

struct AlertsPanelView: View {
    @EnvironmentObject private var alerts: AlertsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if alerts.items.isEmpty {
                    VStack(spacing: 12) {
                        Text("You’re all caught up")
                            .font(AppFont.headline)
                        Text("When there’s something worth your attention, it will show up here. No badges from us — only what you open.")
                            .font(AppFont.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(alerts.items) { item in
                                alertRow(item)
                                if item.id != alerts.items.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(UndrmndPrototypeTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .background(UndrmndPrototypeTheme.paper)
            .navigationTitleBrand("Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body))
                }
                if alerts.unreadCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Mark all read") { alerts.markAllRead() }
                            .font(AppFont.subheadline)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func alertRow(_ item: AppAlertItem) -> some View {
        Button {
            if !item.isRead { alerts.markRead(item.id) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(item.isRead ? UndrmndPrototypeTheme.divider : UndrmndPrototypeTheme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(AppFont.subheadlineEmphasis)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .multilineTextAlignment(.leading)
                    Text(item.body)
                        .font(AppFont.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.date, style: .date)
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.body). \(item.isRead ? "Read" : "Unread")")
    }
}

#Preview {
    AlertsPanelView()
        .environmentObject(AlertsStore())
}
