//
//  DeferredContent.swift
//  URIAGE
//
//  画面遷移を止めないための遅延描画コンテナ。
//
//  SwiftUI は遷移先の body を描き終えるまで画面を切り替えないため、
//  重い集計や Form の生成があると「遷移前の画面で一瞬止まる」状態になる。
//  まず軽いスケルトンを描いて遷移を始め、次のフレーム以降に本物の中身へ差し替える。
//

import SwiftUI

enum SkeletonTiming {
    /// タブ内の切り替え（タブ・ページ送り）用：1 フレーム描いたらすぐ本体へ
    static let inPlace: Duration = .zero
    /// push 遷移用：スライドアニメーションが終わる頃に本体を描き始める
    static let afterPush: Duration = .milliseconds(250)
}

struct DeferredContent<Content: View, Placeholder: View>: View {
    var delay: Duration = SkeletonTiming.inPlace
    @ViewBuilder var content: () -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var isReady = false

    var body: some View {
        ZStack(alignment: .top) {
            if isReady {
                content()
                    .transition(.opacity)
            } else {
                placeholder()
                    .transition(.opacity)
            }
        }
        .deferredReveal($isReady, delay: delay)
    }
}

extension View {
    /// 画面表示後、スケルトンを最低 1 フレーム描いてから `isReady` を true にする。
    /// List / Form の中だけを差し替えたい画面（タイトルやツールバーは即表示したい）で使う。
    func deferredReveal(_ isReady: Binding<Bool>, delay: Duration = SkeletonTiming.inPlace) -> some View {
        task {
            guard isReady.wrappedValue == false else { return }
            let minimumFrame: Duration = .milliseconds(16)
            try? await Task.sleep(for: max(delay, minimumFrame))
            // 途中で画面を離れた（ページを素早くめくった等）場合は本体を作らない
            guard Task.isCancelled == false else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                isReady.wrappedValue = true
            }
        }
    }
}
