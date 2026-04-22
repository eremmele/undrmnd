import SwiftUI

private struct IdentifiedSafari: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PublicProfileID: Identifiable, Hashable {
    let username: String
    var id: String { username }
}

/// v2 path experience: fetches a `PathMap` and moves through card → branch → endpoint nodes.
struct PathView: View {
    let slug: String

    @Environment(\.dismiss) private var dismiss

    @State private var pathMap: PathMap?
    @State private var loadError: String?
    @State private var currentId: UUID?
    @State private var pathFromRoot: [UUID] = []
    @State private var visited: Set<UUID> = []
    @State private var contentCache: [UUID: ContentItem] = [:]
    @State private var safariItem: IdentifiedSafari?
    @State private var advanceAfterSafariDismiss = false
    @State private var isMapOpen = false
    @State private var publicProfile: PublicProfileID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let err = loadError {
                Text(err)
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .padding(20)
            } else if let m = pathMap, let nodeId = currentId, let node = m.node(nodeId) {
                breadcrumbBar(map: m)
                ScrollView {
                    nodeBody(map: m, node: node)
                        .padding(20)
                }
            } else {
                ProgressView("Loading path…")
                    .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle(pathMap?.path?.title ?? "Path")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .tint(UndrmndPrototypeTheme.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isMapOpen = true
                } label: {
                    Image(systemName: "map")
                }
                .tint(UndrmndPrototypeTheme.secondary)
                .accessibilityLabel("Open path map")
            }
        }
        .task { await load() }
        .sheet(
            item: $safariItem,
            onDismiss: {
                if advanceAfterSafariDismiss, let m = pathMap {
                    goNext(map: m)
                }
                advanceAfterSafariDismiss = false
            }
        ) { s in
            SafariView(url: s.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isMapOpen) {
            Group {
                if let m = pathMap {
                    PathMapView(
                        pathMap: m,
                        currentId: currentId,
                        visited: visited,
                        onSelectNode: { id in
                            isMapOpen = false
                            jumpToNode(id, map: m)
                        }
                    )
                } else {
                    Text("Map loading…")
                }
            }
        }
        .sheet(item: $publicProfile) { p in
            NavigationStack {
                PublicProfileView(username: p.username)
            }
        }
    }

    @ViewBuilder
    private func breadcrumbBar(map: PathMap) -> some View {
        let labels = pathFromRoot.map { id in
            if let n = map.node(id) { nodeLabel(n) } else { "·" }
        }
        if !labels.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { i, t in
                        if i > 0 {
                            Image(systemName: "chevron.compact.right")
                                .font(AppFont.caption2)
                                .foregroundStyle(UndrmndPrototypeTheme.divider)
                        }
                        Text(t)
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Path: " + labels.joined(separator: ", "))
        }
    }

    @ViewBuilder
    private func nodeBody(map: PathMap, node: PathNode) -> some View {
        switch node.nodeType {
        case .card:
            if let item = resolvedContent(node: node) {
                CardView(
                    item: item,
                    nodeByline: node.contributedBy,
                    onRequestSafari: { url, advance in
                        advanceAfterSafariDismiss = advance
                        safariItem = IdentifiedSafari(url: url)
                    },
                    onContinue: { goNext(map: map) },
                    onOpenContributor: { u in
                        publicProfile = PublicProfileID(username: u)
                    }
                )
            } else {
                Text("This card is still loading or unavailable.")
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
        case .branch:
            BranchView(
                prompt: node.branchPrompt ?? "",
                compass: node.branchCompass,
                edges: map.outgoing(from: node.id)
            ) { e in
                pathFromRoot.append(e.toNodeId)
                visited.insert(e.toNodeId)
                currentId = e.toNodeId
            }
        case .endpoint:
            EndpointView(note: node.endpointNote ?? "That’s a stopping place.") {
                dismiss()
            }
        }
    }

    private func nodeLabel(_ n: PathNode) -> String {
        if let t = n.content?.title, !t.isEmpty {
            return String(t.prefix(24)) + (t.count > 24 ? "…" : "")
        }
        if let p = n.branchPrompt { return String(p.prefix(20)) + (p.count > 20 ? "…" : "") }
        if n.nodeType == .endpoint { return "End" }
        return "·"
    }

    private func resolvedContent(node: PathNode) -> ContentItem? {
        if let c = contentCache[node.id] { return c }
        if let c = node.content { return c }
        return nil
    }

    private func load() async {
        do {
            let m = try await PathService.fetchPath(slug: slug)
            pathMap = m
            PathResumeStore.recordPathOpened(slug: slug)
            guard let root = m.rootNodes.first else {
                loadError = "This path has no start."
                return
            }
            currentId = root.id
            pathFromRoot = [root.id]
            visited = [root.id]
            for n in m.nodes {
                if let c = n.content { contentCache[n.id] = c }
            }
            await fillMissingDetails(map: m)
        } catch {
            loadError = "Couldn’t load this path. \(error.localizedDescription)"
        }
    }

    private func fillMissingDetails(map: PathMap) async {
        for n in map.nodes {
            guard n.nodeType == .card, let base = n.content else { continue }
            if base.body == nil || base.body?.isEmpty == true {
                do {
                    let full = try await ContentService.fetchCardDetail(id: base.id)
                    contentCache[n.id] = full
                } catch {
                    contentCache[n.id] = base
                }
            }
        }
    }

    private func goNext(map: PathMap) {
        guard let cur = currentId else { return }
        let out = map.outgoing(from: cur)
        guard out.count == 1, let e = out.first else { return }
        let next = e.toNodeId
        pathFromRoot.append(next)
        visited.insert(next)
        currentId = next
    }

    private func jumpToNode(_ id: UUID, map: PathMap) {
        let chain = bfsPathToNode(target: id, map: map)
        guard !chain.isEmpty else { return }
        pathFromRoot = chain
        currentId = id
        visited.formUnion(chain)
    }

    private func bfsPathToNode(target: UUID, map: PathMap) -> [UUID] {
        let roots = map.rootNodes.map(\.id)
        guard !roots.isEmpty else { return [target] }
        var q = roots
        var parent: [UUID: UUID?] = [:]
        for r in roots { parent[r] = nil }
        var head = 0
        var seen = Set(roots)
        var found = false
        while head < q.count {
            let u = q[head]
            head += 1
            if u == target {
                found = true
                break
            }
            for e in map.outgoing(from: u) {
                if !seen.contains(e.toNodeId) {
                    seen.insert(e.toNodeId)
                    parent[e.toNodeId] = u
                    q.append(e.toNodeId)
                }
            }
        }
        if !found { return [target] }
        var chain: [UUID] = []
        var x: UUID? = target
        while let node = x {
            chain.insert(node, at: 0)
            if let p = parent[node] { x = p } else { break }
        }
        return chain
    }
}
