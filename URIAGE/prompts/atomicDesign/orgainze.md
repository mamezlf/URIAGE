# ROLE
你是资深 Design System Architect (SwiftUI 专家)。

# GOAL
基于已有 Atomic Design Rule，
分析 URIAGE 项目页面并抽取组件。

# HARD RULES
下面是适用于 SwiftUI 的 Atomic Design Rule：

## 各階層の設計ルール

### Atoms（原子）

**責任範囲**: 最小単位の UI コンポーネント / スタイル定義

**制約条件**:
- 汎用的である（Domain-agnostic）
- 他のコンポーネントに依存しない
- 状態（State）を極力持たない
- `Font`, `Color`, `ButtonStyle`, `ViewModifier` もここに含まれる

**実装例**:
- `AmountText`: 金額表示用の共通ラベル
- `ProfitText`: 利益表示用の色付きテキスト
- `PrimaryActionButtonStyle`: アプリ共通のボタン形状
- `AppCardStyle`: カード背景の ViewModifier

### Molecules（分子）

**責任範囲**: Atoms を組み合わせた機能的な UI ユニット

**制約条件**:
- 汎用的である（Domain-agnostic）
- 複数の Atoms または標準 SwiftUI 部品を組み合わせる
- 単一の責務を持つ

**実装例**:
- `StatCard`: アイコン + ラベル + 数値
- `EmptyStateCard`: 画像 + メッセージ + アクションボタン
- `DimensionField`: ラベル + 単位付き入力フィールド

### Organisms（有機体）

**責任範囲**: ドメイン固有の知識（Domain-specific）を持つ複雑なコンポーネント

**制約条件**:
- ビジネスロジックや Data Model (SoldItem 等) に依存してよい
- 複数の Molecules や Atoms を組み合わせる
- ページを構成する主要なセクション

**実装例**:
- `SoldItemListRow`: SoldItem モデルを表示するリスト行
- `ShippingRecommendationPanel`: 送料計算のおすすめ表示
- `FilterBar`: 検索・絞り込みコントロールの集合体

### Templates（テンプレート）

**責任範囲**: ページの構造とレイアウトの抽象化

**制約条件**:
- 具体的なコンテンツを持たず、レイアウトの枠組みを提供する
- `@ViewBuilder` を多用する

**実装例**:
- `ScrollableContainer`: 標準的なパディング付きスクロールビュー

### Pages（ページ）

**責任範囲**: 具体的な画面の実装

**制約条件**:
- アプリの各タブや遷移先となる View
- `@Query` (SwiftData) によるデータフェッチとロジックの結合

**実装例**:
- `SoldItemListView`, `SoldItemFormView`, `MonthlyReportView`

# ANALYSIS RESULTS (URIAGE Project)

## 1. Atoms
- **Typography & Colors**: `AppTheme.Colors`, `AppTheme.Metrics`
- **Text Components**:
    - `AmountText`: 通貨フォーマット済みのテキスト
    - `ProfitText`: 利益/損失に応じた色付けテキスト
- **Modifiers**:
    - `appCard()`: `AppCardStyle` による共通カードレイアウト
    - `hideKeyboardOnTap()`: キーボードを閉じる共通処理
- **Styles**:
    - `PrimaryActionButtonStyle`: 塗りつぶしの主アクションボタン
    - `QuickActionButtonStyle`: インタラクション用アニメーション

## 2. Molecules
- **Information Display**:
    - `StatCard`: 統計情報の概要カード
    - `SectionCard`: タイトル付きセクションコンテナ
- **Feedback & Control**:
    - `EmptyStateCard`: 検索結果なし等の空状態表示
    - `DimensionField`: `ShippingCalculator` で使用する入力フィールド（ラベル+単位）
    - `SummaryMetric`: 送料計算の3辺合計/厚さ/重量表示
    - `PresetButton`: 定形サイズの選択ボタン
- **Rows**:
    - `ReportItemRow`: 月次レポート用の簡略化された商品行

## 3. Organisms
- **List Components**:
    - `SoldItemListRow`: 利益率計算等を含むドメイン依存のリスト行
    - `FilterBar`: 期間・ソート・検索を管理する複合コントロール
- **Specialized UI**:
    - `ShippingRecommendationPanel`: 推奨される発送方法の表示パネル
    - `ShippingOptionRow`: 送料オプションの詳細表示と選択ロジック
    - `SoldItemFormFields`: 利益プレビューを含む入力フォーム群
    - `MercariLinkImporter`: リンク解析と自动输入ロジックを含むユニット

## 4. Templates
- `FormViewTemplate`: 標準的な `Form` + 保存/キャンセルツールバー
- `ListViewTemplate`: `List` + `FilterBar` + `EmptyState` の共通構成

## 5. Pages
- `SoldItemListView`: 販売履歴一覧
- `SoldItemFormView`: 登録・編集フォーム
- `MonthlyReportView`: 月次収支レポート
- `ShippingCalculatorView`: 送料シミュレーター
- `SuppliesView`: 梱包資材管理
- `SettingsView`: アプリ設定

# ARCHITECTURE STRATEGY
1. **Atoms の徹底的な分離**: `SharedUI.swift` にある `AmountText`, `ProfitText` を `Atoms/` に物理的に分割し、再利用性を高める。
2. **Molecules の純粋化**: `StatCard` などからドメイン知識を排除し、汎用的な `StatCard(title: String, value: String, ...)` として定義する。
3. **Organisms の抽出**: 巨大な `SoldItemListView` から `FilterBar` を独立したファイルとして切り出し、メンテナンス性を向上させる。
4. **Variant-first**: ボタンやバッジは `enum Variant` を用いて、`.primary`, `.secondary`, `.ghost` などのバリエーションを一貫して管理する。

# TASK STATUS
- [x] 全局分析所有页面
- [x] 识别共享 UI Pattern
- [x] 基于 Rule 进行 Atomic 分类
- [x] 输出统一组件架构
- [x] 识别 Variant
- [x] 避免重复组件
