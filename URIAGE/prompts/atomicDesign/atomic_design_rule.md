## 各階層の設計ルール

### Atoms（原子）

**責任範囲**: 最小単位の UI コンポーネント

**制約条件**:

- 汎用的である必要がある
- ドメイン固有の制約を持たない
- Context に依存しない
- 状態は最小限に留める
- 他のコンポーネントに依存しない

**実装例**:

- BrandButton（shadcn/ui Button のカスタマイズ）
- CustomInput（shadcn/ui Input の拡張）
- StatusBadge（ステータス表示用バッジ）

### Molecules（分子）

**責任範囲**: Atoms を組み合わせた機能的なコンポーネント

**制約条件**:

- 汎用的である必要がある
- ドメイン固有の制約を持たない
- 他のコンポーネント（主に Atoms）に依存可能
- 単一の機能を提供する

**実装例**:

- SearchBox（Input + Button の組み合わせ）
- FormField（Label + Input + ErrorMessage）
- ConfirmDialog（Dialog + Button 群）

### Organisms（有機体）

**責任範囲**: ドメイン固有の複雑なコンポーネント

**制約条件**:

- ドメイン固有の制約を持つことが許可される
- Context への接続が可能
- API 呼び出しが可能
- 複数の Molecules や Atoms を組み合わせる


### Templates（テンプレート）

**責任範囲**: ページの構造とレイアウト

**制約条件**:

- レイアウトの責任のみを持つ
- ビジネスロジックを含まない
- props でコンテンツを受け取る
- 再利用可能なレイアウト構造

### Pages（ページ）

**責任範囲**: 具体的なページの実装

**制約条件**:

- Next.js のページコンポーネントのラッパー
- データフェッチと Templates の組み合わせ
- ルーティング固有のロジック

