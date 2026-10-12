//
//  ReportTrendPoint.swift
//  URIAGE
//
//  推移グラフの 1 本分（月別推移なら 1 か月、年別推移なら 1 年）
//

import Foundation

struct ReportTrendPoint: Identifiable, Equatable {
    /// 表示名（「9月」「2026年」）。グラフの x 値にも使う
    let label: String
    /// x 軸に出す短いラベル（「9」「'26」）
    let axisLabel: String
    let start: Date
    let isFuture: Bool
    let sales: Decimal
    let profit: Decimal
    let soldCount: Int

    var id: String { label }
}
