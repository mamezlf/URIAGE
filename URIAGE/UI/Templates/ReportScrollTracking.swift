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
    /// 上部（タイトル・期間ヘッダー）は List の上に重ねて表示する。その本来の高さ分だけ List の上に余白を空ける
    @Entry var reportTopInset: CGFloat = 0
    /// 内容が短いページでも上部を縮めきれるように、List の下に足す余白
    @Entry var reportBottomInset: CGFloat = 0
}

private struct ReportScrollTracking: ViewModifier {
    @Environment(\.reportScrollHandler) private var handler

    func body(content: Content) -> some View {
        content
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

/// 上部の下に List の内容が隠れないよう、上下の余白を空ける。
/// 余白はスクロールしても変わらないので、スクロール中に List の大きさが変わって引っかかることはない
private struct ReportContentMargins: ViewModifier {
    @Environment(\.reportTopInset) private var topInset
    @Environment(\.reportBottomInset) private var bottomInset

    func body(content: Content) -> some View {
        content
            .contentMargins(.top, topInset, for: .scrollContent)
            .contentMargins(.top, topInset, for: .scrollIndicators)
            .contentMargins(.bottom, bottomInset, for: .scrollContent)
    }
}

extension View {
    /// レポートの各ページ（List とスケルトン）に付ける。上部の高さ分の余白を空ける
    func reportContentMargins() -> some View {
        modifier(ReportContentMargins())
    }

    /// レポートの List に付ける。スクロール量を ReportView に伝える
    func reportScrollTracking() -> some View {
        modifier(ReportScrollTracking())
    }
}
