//
//  LegalDocumentsView.swift
//  URIAGE
//
//  Created by Codex on 2026/04/29.
//

import SwiftUI

enum LegalDocument: String, Identifiable {
    case disclaimer
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disclaimer:
            return "免責事項"
        case .terms:
            return "利用規約"
        }
    }

    var sections: [LegalSection] {
        switch self {
        case .disclaimer:
            return [
                LegalSection(
                    title: "1. 本アプリの位置づけ",
                    body: "URIAGEは、フリマ販売などの売上、費用、利益を利用者自身が記録・確認するための補助ツールです。本アプリが表示する計算結果、レポート、目安情報は、入力内容およびアプリ内の計算ロジックに基づく参考情報であり、正確性、完全性、有用性を保証するものではありません。"
                ),
                LegalSection(
                    title: "2. 税務・会計上の判断について",
                    body: "本アプリは税務、会計、法務その他の専門的助言を提供するものではありません。確定申告、帳簿作成、経費計上、税額計算その他の判断については、利用者自身の責任で確認し、必要に応じて税理士、公認会計士、弁護士などの専門家または公的機関に相談してください。"
                ),
                LegalSection(
                    title: "3. 外部サービスとの関係",
                    body: "本アプリは、特定のフリマサービス、配送会社、決済事業者、その他外部サービスによって公式に提供、承認、提携されたものではありません。外部サービスの仕様、手数料、送料、規約などは変更される場合があり、本アプリの表示内容と実際の条件が異なる可能性があります。"
                ),
                LegalSection(
                    title: "4. データ管理",
                    body: "利用者が本アプリに入力した情報の管理、確認、バックアップは利用者自身の責任で行うものとします。端末の故障、アプリの削除、OSやアプリの更新、不具合その他の事情によりデータが失われた場合でも、開発者は責任を負いません。"
                ),
                LegalSection(
                    title: "5. 損害に関する免責",
                    body: "本アプリの利用または利用不能により生じた損害、逸失利益、事業上の損失、第三者との紛争、入力ミスや計算結果の利用に起因する不利益について、開発者は故意または重過失がある場合を除き、一切の責任を負いません。"
                ),
                LegalSection(
                    title: "6. 内容の変更",
                    body: "本免責事項は、必要に応じて予告なく変更されることがあります。変更後の内容は、本アプリ内に表示された時点から適用されます。"
                )
            ]
        case .terms:
            return [
                LegalSection(
                    title: "1. 適用",
                    body: "本利用規約は、URIAGEの利用条件を定めるものです。利用者は、本アプリを利用することにより、本規約に同意したものとみなされます。"
                ),
                LegalSection(
                    title: "2. 利用目的",
                    body: "利用者は、本アプリを、売上、費用、利益、資材費などを記録・確認する目的で利用できます。利用者は、法令、公序良俗、本規約に反する目的で本アプリを利用してはなりません。"
                ),
                LegalSection(
                    title: "3. 入力情報と計算結果",
                    body: "本アプリの計算結果は、利用者が入力した情報に基づいて表示されます。入力内容の正確性、計算結果の確認、実際の取引条件や証憑との照合は、利用者自身の責任で行うものとします。"
                ),
                LegalSection(
                    title: "4. 禁止事項",
                    body: "利用者は、本アプリの不正利用、解析、改変、第三者の権利を侵害する行為、法令に違反する行為、開発者または第三者に損害を与える行為を行ってはなりません。"
                ),
                LegalSection(
                    title: "5. アプリの変更・停止",
                    body: "開発者は、機能改善、保守、仕様変更、その他必要な理由により、本アプリの全部または一部を変更、追加、中断、終了することがあります。これにより利用者に損害が生じた場合でも、開発者は責任を負いません。"
                ),
                LegalSection(
                    title: "6. 知的財産権",
                    body: "本アプリに関する著作権、商標権、その他の知的財産権は、開発者または正当な権利者に帰属します。利用者は、権利者の許可なく本アプリの内容を複製、転載、配布、販売、改変してはなりません。"
                ),
                LegalSection(
                    title: "7. 免責",
                    body: "本アプリの利用に関する免責事項は、別途表示する「免責事項」に定めるとおりです。利用者は、免責事項の内容も確認し、同意したうえで本アプリを利用するものとします。"
                ),
                LegalSection(
                    title: "8. 規約の変更",
                    body: "開発者は、必要に応じて本規約を変更できるものとします。変更後の規約は、本アプリ内に表示された時点から効力を生じます。"
                ),
                LegalSection(
                    title: "9. 準拠法",
                    body: "本規約は日本法に準拠して解釈されます。本アプリに関して紛争が生じた場合、利用者と開発者は誠実に協議し解決を図るものとします。"
                )
            ]
        }
    }
}

struct LegalSection: Identifiable {
    let title: String
    let body: String

    var id: String { title }
}

struct LegalDocumentsView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(document.title)
                    .font(.title2.bold())

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)

                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("最終更新日：2026年4月29日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(AppTheme.Colors.pageBackground)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("免責事項") {
    NavigationStack {
        LegalDocumentsView(document: .disclaimer)
    }
}

#Preview("利用規約") {
    NavigationStack {
        LegalDocumentsView(document: .terms)
    }
}
