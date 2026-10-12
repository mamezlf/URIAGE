import SwiftUI

struct FormViewTemplate<Content: View>: View {
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    var isSaveDisabled: Bool = false
    @ViewBuilder var content: Content

    /// push のスライド中はスケルトンを出し、TextField / DatePicker の生成は遷移後に行う
    @State private var isContentReady = false

    var body: some View {
        Form {
            if isContentReady {
                content
            } else {
                FormSkeletonSections()
            }
        }
        .deferredReveal($isContentReady, delay: SkeletonTiming.afterPush)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", role: .cancel) {
                    onCancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: onSave)
                    .disabled(isSaveDisabled)
            }
        }
    }
}
