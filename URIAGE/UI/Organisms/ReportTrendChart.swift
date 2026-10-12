//
//  ReportTrendChart.swift
//  URIAGE
//
//  月別推移 / 年別推移 の共通グラフ。販売額は淡い棒、利益は線。
//  タップした月（年）の数字と、ベスト月（年）はグラフの下に表示する。空白をタップすると選択解除。
//

import SwiftUI
import Charts

struct ReportTrendChart: View {
    enum Unit {
        case month
        case year

        var name: String {
            switch self {
            case .month: "月"
            case .year: "年"
            }
        }

        var reportTitle: String {
            switch self {
            case .month: "月次レポート"
            case .year: "年次レポート"
            }
        }
    }

    let points: [ReportTrendPoint]
    let bestPoint: ReportTrendPoint?
    let unit: Unit
    let currencyFormatter: AppCurrencyFormatter
    let onOpen: (Date) -> Void

    @State private var selectedLabel: String?

    private var selectedPoint: ReportTrendPoint? {
        guard let selectedLabel else { return nil }
        return points.first { $0.label == selectedLabel && $0.isFuture == false }
    }

    private var pastPoints: [ReportTrendPoint] {
        points.filter { $0.isFuture == false }
    }

    private var hasNegativeProfit: Bool {
        pastPoints.contains { $0.profit < 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value(unit.name, point.label),
                        y: .value("販売額", point.sales.doubleValue)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(AppTheme.Colors.sales.opacity(barOpacity(for: point)))
                }

                ForEach(pastPoints) { point in
                    LineMark(
                        x: .value(unit.name, point.label),
                        y: .value("利益", point.profit.doubleValue),
                        series: .value("系列", "利益")
                    )
                    .foregroundStyle(AppTheme.Colors.success)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value(unit.name, point.label),
                        y: .value("利益", point.profit.doubleValue)
                    )
                    .foregroundStyle(AppTheme.profitColor(for: point.profit))
                    .symbolSize(point.label == selectedLabel ? 110 : 45)
                }

                if hasNegativeProfit {
                    RuleMark(y: .value("ゼロ", 0))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            // タップで選択 / 解除する（標準の chartXSelection は指を離すと解除され、空白の判定もできないため自前で処理）
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture().onEnded { value in
                                handleTap(at: value.location, proxy: proxy, geometry: geometry)
                            }
                        )
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(axisLabel(for: label))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.formatted(.number.notation(.compactName).locale(Locale(identifier: "ja_JP"))))
                        }
                    }
                }
            }
            .frame(height: 220)

            legend

            detail
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
                .padding(.top, 4)
                .animation(.snappy, value: selectedLabel)
        }
    }

    /// 棒・点のある所をタップしたら選択、空白（データのない月 / 棒より上の余白 / グラフの外側）なら解除。
    /// 選択中の月（年）をもう一度タップしても解除する。
    private func handleTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let plotArea = geometry[plotFrame]
        let plotLocation = CGPoint(x: location.x - plotArea.minX, y: location.y - plotArea.minY)

        guard plotArea.contains(location),
              let label: String = proxy.value(atX: plotLocation.x),
              let point = points.first(where: { $0.label == label }),
              point.isFuture == false,
              point.sales != 0 || point.profit != 0
        else {
            selectedLabel = nil
            return
        }

        // 棒（または利益の点）の上端より上の余白は「空白」扱い。小さい棒でも押せるよう少し余裕を持たせる
        let tolerance: CGFloat = 20
        let top = max(point.sales, point.profit, 0).doubleValue
        let bottom = min(point.profit, 0).doubleValue
        if let topY = proxy.position(forY: top), let bottomY = proxy.position(forY: bottom),
           plotLocation.y < topY - tolerance || plotLocation.y > bottomY + tolerance {
            selectedLabel = nil
            return
        }

        selectedLabel = (selectedLabel == label) ? nil : label
    }

    private func axisLabel(for label: String) -> String {
        points.first { $0.label == label }?.axisLabel ?? label
    }

    // 販売額の棒は背景として淡く、利益の線を主役にする
    private func barOpacity(for point: ReportTrendPoint) -> Double {
        guard selectedLabel != nil else { return 0.28 }
        return point.label == selectedLabel ? 0.55 : 0.14
    }

    @ViewBuilder
    private var detail: some View {
        if let point = selectedPoint {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(point.label)
                        .font(.headline)
                    Spacer()
                    Button {
                        onOpen(point.start)
                    } label: {
                        HStack(spacing: 2) {
                            Text(unit.reportTitle)
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }

                HStack(spacing: 16) {
                    metric("販売額", currencyFormatter.string(from: point.sales), tint: AppTheme.Colors.sales)
                    metric("利益", currencyFormatter.string(from: point.profit), tint: AppTheme.profitColor(for: point.profit))
                    metric("件数", "\(point.soldCount)", tint: AppTheme.Colors.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let bestPoint {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text("ベスト\(unit.name)は\(bestPoint.label)")
                            .font(.headline)
                    }
                    Text("利益 \(currencyFormatter.string(from: bestPoint.profit))・\(bestPoint.soldCount)件")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("グラフをタップすると\(unit.name)ごとの数字を表示します")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func metric(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.Colors.sales.opacity(0.35), label: "販売額", isLine: false)
            legendItem(color: AppTheme.Colors.success, label: "利益", isLine: true)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func legendItem(color: Color, label: String, isLine: Bool) -> some View {
        HStack(spacing: 6) {
            if isLine {
                Capsule().fill(color).frame(width: 14, height: 3)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            }
            Text(label)
        }
    }
}

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
