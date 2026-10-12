//
//  ReportInput.swift
//  URIAGE
//
//  レポート集計の入力。SwiftData のモデルはメインスレッド専用なので、
//  集計に必要な値だけを値型に写し取り、バックグラウンドで集計できるようにする。
//

import Foundation

/// 集計用の販売記録（SoldItem の値のコピー）
nonisolated struct SoldRecord: Sendable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let soldAt: Date
    let salePrice: Decimal
    let profit: Decimal
    let directPackagingCost: Decimal
}

/// 集計用の資材（SupplyItem の値のコピー）
nonisolated struct SupplyRecord: Sendable, Equatable {
    let purchaseDate: Date
    let totalCost: Decimal
}

/// レポート集計の入力一式。内容が同じならキャッシュした集計結果をそのまま使える
nonisolated struct ReportInput: Sendable, Equatable {
    let soldItems: [SoldRecord]
    let supplies: [SupplyRecord]

    init(soldItems: [SoldRecord], supplies: [SupplyRecord]) {
        self.soldItems = soldItems
        self.supplies = supplies
    }

    var isCheapToAggregate: Bool {
        soldItems.count + supplies.count <= 3_000
    }
}

extension SoldRecord {
    @MainActor
    init(_ item: SoldItem) {
        self.init(
            id: item.id,
            title: item.title,
            soldAt: item.soldAt,
            salePrice: item.salePrice,
            profit: item.profit,
            directPackagingCost: item.directPackagingCost
        )
    }
}

extension SupplyRecord {
    @MainActor
    init(_ supply: SupplyItem) {
        self.init(purchaseDate: supply.purchaseDate, totalCost: supply.totalCost)
    }
}

extension ReportInput {
    @MainActor
    init(items: [SoldItem], supplies: [SupplyItem]) {
        self.init(
            soldItems: items.map(SoldRecord.init),
            supplies: supplies.map(SupplyRecord.init)
        )
    }
}
