//
//  ReportScrollTracking.swift
//  URIAGE
//
//  レポートの各ページ（List）のスクロール量を ReportView に伝える。
//  ReportView はこれを使って、上部（タイトル・期間ヘッダー）をスクロールに合わせて縮める。
//

import SwiftUI

nonisolated struct ReportScrollMetrics: Equatable, Sendable {
    /// 一番上からどれだけスクロールしたか（引っ張ったときはマイナス）
    var offset: CGFloat
    /// あとどれだけスクロールできるか（コンテンツの高さ − 表示領域の高さ）
    var scrollableHeight: CGFloat
}

extension EnvironmentValues {
    /// 表示中のページにだけ渡す。左右の先読みページには nil を渡し、ヘッダーに影響させない
    @Entry var reportScrollHandler: ((ReportScrollMetrics) -> Void)? = nil
    /// 上部が縮んだ高さ。同じ分だけ List の下に余白を足して、スクロールできる量が変わらないようにする
    @Entry var reportCollapsedHeight: CGFloat = 0
}

private struct ReportScrollTracking: ViewModifier {
    @Environment(\.reportScrollHandler) private var handler
    @Environment(\.reportCollapsedHeight) private var collapsedHeight

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, collapsedHeight, for: .scrollContent)
            .onScrollGeometryChange(for: ReportScrollMetrics.self) { geometry in
            ReportScrollMetrics(
                offset: geometry.contentOffset.y + geometry.contentInsets.top,
                scrollableHeight: geometry.contentSize.height
                    + geometry.contentInsets.top
                    + geometry.contentInsets.bottom
                    - geometry.containerSize.height
            )
        } action: { _, newValue in
            handler?(newValue)
        }
    }
}

extension View {
    /// レポートの List に付ける。スクロール量を ReportView に伝える
    func reportScrollTracking() -> some View {
        modifier(ReportScrollTracking())
    }
}
