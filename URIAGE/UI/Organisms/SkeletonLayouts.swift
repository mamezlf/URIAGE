//
//  SkeletonLayouts.swift
//  URIAGE
//
//  実レイアウトを真似たスケルトン。行の高さ・余白は本物の Row に合わせている。
//  待ちが発生する場面（レポートの集計・記録タブの初回表示）だけで使う。
//

import SwiftUI

/// 行ごとに幅を少し変えて、本物のテキストらしく見せる
private enum SkeletonWidths {
    static let titles: [CGFloat] = [168, 128, 190, 112, 150, 176, 136, 158]
    static let amounts: [CGFloat] = [72, 60, 84, 66, 78]

    static func title(_ index: Int) -> CGFloat { titles[index % titles.count] }
    static func amount(_ index: Int) -> CGFloat { amounts[index % amounts.count] }
}

// MARK: - Rows

/// 「ラベル ……… 値」の 1 行（サマリー行など）
struct SkeletonKeyValueRow: View {
    var index: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            SkeletonBlock(width: 56 + CGFloat(index % 2) * 12, height: 14)
            Spacer(minLength: 16)
            SkeletonBlock(width: SkeletonWidths.amount(index) + 24, height: 16)
        }
        .padding(.vertical, 3)
    }
}

/// SoldItemListRow / SupplyItemRow を模した 2 段の行
struct SkeletonTwoLineRow: View {
    var index: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                SkeletonBlock(width: SkeletonWidths.title(index), height: 16)
                Spacer(minLength: 12)
                SkeletonBlock(width: SkeletonWidths.amount(index), height: 14)
            }
            HStack(spacing: 12) {
                SkeletonBlock(width: 84, height: 11)
                Spacer(minLength: 12)
                SkeletonBlock(width: SkeletonWidths.amount(index + 2) - 10, height: 11)
            }
        }
        .padding(.vertical, 6)
    }
}

/// ReportItemRow を模した行
struct SkeletonReportItemRow: View {
    var index: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                SkeletonBlock(width: SkeletonWidths.title(index), height: 14)
                Spacer(minLength: 12)
                SkeletonBlock(width: SkeletonWidths.amount(index), height: 14)
            }
            SkeletonBlock(width: 84, height: 11)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pages

/// レポート（月 / 年 / すべて）のスケルトン。見出しは固定文言なので本物を出す
struct ReportSkeleton: View {
    /// nil の場合はグラフ欄なし（月次レポート）
    var chartTitle: String? = nil

    var body: some View {
        List {
            Section("サマリー") {
                ForEach(0..<4, id: \.self) { index in
                    SkeletonKeyValueRow(index: index)
                }
            }

            if let chartTitle {
                Section(chartTitle) {
                    SkeletonBlock(height: 200, cornerRadius: 10)
                        .padding(.vertical, 8)
                }
            }

            Section("利益上位5件") {
                ForEach(0..<5, id: \.self) { index in
                    SkeletonReportItemRow(index: index)
                }
            }
        }
        .scrollDisabled(true)
        .skeletonAccessibility()
    }
}

/// ListViewTemplate（販売記録一覧）の List 内に入れるスケルトン（FilterBar + 行）
struct ListTemplateSkeletonSections: View {
    var rowCount: Int = 8

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SkeletonBlock(width: 64, height: 18)
                    Spacer()
                    SkeletonBlock(width: 80, height: 14)
                }
                SkeletonBlock(height: 32, cornerRadius: 8)
                Divider().overlay(AppTheme.Colors.separator)
                HStack {
                    SkeletonBlock(width: 72, height: 14)
                    Spacer()
                    SkeletonBlock(width: 140, height: 32, cornerRadius: AppTheme.Metrics.controlCornerRadius)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .skeletonAccessibility()

        Section {
            ForEach(0..<rowCount, id: \.self) { index in
                SkeletonTwoLineRow(index: index)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Monthly") {
    ReportSkeleton()
}

#Preview("Yearly") {
    ReportSkeleton(chartTitle: "月別推移")
}

#Preview("Sold items") {
    List { ListTemplateSkeletonSections() }
}
