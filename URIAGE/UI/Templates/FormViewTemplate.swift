import SwiftUI

struct FormViewTemplate<Content: View>: View {
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    var isSaveDisabled: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        Form {
            content
        }
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
