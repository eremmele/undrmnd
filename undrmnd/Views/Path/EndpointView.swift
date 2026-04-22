import SwiftUI

struct EndpointView: View {
    let note: String
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text(note)
                .font(AppFont.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onDone) {
                Text("Done")
                    .undrmndShellCtaTextStyle()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done with this path")
        }
        .frame(maxWidth: .infinity)
    }
}
