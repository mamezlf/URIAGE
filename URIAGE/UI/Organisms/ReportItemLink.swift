//
//  ReportItemLink.swift
//  URIAGE
//
//  レポートの「利益上位5件」の 1 行。タップで販売記録の詳細へ。
//  集計結果は値のコピー（SoldRecord）なので、遷移時に元の SoldItem を探す。
//

import SwiftUI

struct ReportItemLink: View {
    let record: SoldRecord
    let items: [SoldItem]
    let currencyFormatter: AppCurrencyFormatter

    var body: some View {
        NavigationLink {
            if let item = items.first(where: { $0.id == record.id }) {
                SoldItemDetailView(item: item)
            } else {
                ContentUnavailableView(
                    "販売記録が見つかりません",
                    systemImage: "tray",
                    description: Text("削除された可能性があります。")
                )
            }
        } label: {
            ReportItemRow(item: record, currencyFormatter: currencyFormatter)
        }
    }
}
