//
//  Skeleton.swift
//  URIAGE
//
//  読み込み中に表示するグレーの占位ブロックと、きらっと流れるシマー効果。
//

import SwiftUI

/// 実際のテキストや数値の位置に置く、グレーの角丸ブロック
struct SkeletonBlock: View {
    /// nil の場合は横幅いっぱいに広がる
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.Colors.skeleton)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .shimmering()
            .accessibilityHidden(true)
    }
}

extension View {
    /// 左から右へ光が流れるシマー効果。「視差効果を減らす」がオンの場合は静止表示。
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }

    /// スケルトン全体を VoiceOver に「読み込み中」として 1 要素で伝える
    func skeletonAccessibility() -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel("読み込み中")
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// 1 往復の秒数。全ブロックが同じ時計を見るので、光るタイミングが揃う
    private let duration: TimeInterval = 1.4

    private var highlight: Color {
        colorScheme == .dark ? .white.opacity(0.10) : .white.opacity(0.55)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.overlay {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSinceReferenceDate
                    let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
                    // -0.5 ... 1.5 を移動させ、光の帯が画面外から入って画面外へ抜ける
                    let center = progress * 2 - 0.5

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: highlight, location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: UnitPoint(x: center - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: center + 0.5, y: 0.5)
                    )
                }
                .mask { content }
                .allowsHitTesting(false)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SkeletonBlock(width: 160, height: 20)
        SkeletonBlock(height: 14)
        SkeletonBlock(width: 80, height: 10)
    }
    .padding()
}
