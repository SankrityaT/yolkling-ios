import SwiftUI
import YolklingCore

/// The brand's segmented control. ALWAYS use this for segmented selection.
///
/// PROJECT RULE: never use SwiftUI's `Picker(...).pickerStyle(.segmented)` (the system
/// segmented control does not match the Yolkling look). Every aisle/tab/toggle switch
/// in the app is a custom pill row like this one.
///
/// Lives in Core/Components (NOT Core/DesignSystem) because DesignSystem is compiled
/// into the widget extension and this uses Haptics, which is not widget-safe.
///
/// A row of pill segments inside a soft capsule; the active segment fills with ink.
struct YolkSegmented<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { opt in
                let active = selection == opt
                Button {
                    Haptics.shared.select()
                    withAnimation(.easeInOut(duration: 0.18)) { selection = opt }
                } label: {
                    Text(label(opt))
                        .font(YolkType.bodySmall.weight(active ? .semibold : .medium))
                        .foregroundStyle(active ? YolkColor.shell : YolkColor.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(active ? YolkColor.ink : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(YolkColor.shell2, in: Capsule())
    }
}
