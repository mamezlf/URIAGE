import SwiftUI

struct ListViewTemplate<Content: View, Filter: View, EmptyState: View>: View {
    let title: String
    let isEmpty: Bool
    /// true の間はフィルターと行の代わりにスケルトンを表示する（タイトル・ツールバーはそのまま）
    var isLoading: Bool = false
    @ViewBuilder var filterBar: Filter
    @ViewBuilder var emptyState: EmptyState
    @ViewBuilder var content: Content
    var trailingToolbar: (() -> AnyView)? = nil

    var body: some View {
        List {
            if isLoading {
                ListTemplateSkeletonSections()
            } else {
                Section {
                    filterBar
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                if isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowBackground(Color.clear)
                } else {
                    content
                }
            }
        }
        .safeAreaPadding(.top, 16)
        .navigationTitle(title)
        .toolbar {
            if let trailingToolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    trailingToolbar()
                }
            }
        }
    }
}
