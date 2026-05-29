# CSS Refactoring Plan (Atomic Design & CSS Modules)

`index.css` に集中しているスタイルを、Atomic Design の各コンポーネントごとの CSS Modules (`.module.css`) に分割する計画です。

## 1. 新しいディレクトリ構造
```text
/src/components
  /atoms
    /Button
      Button.tsx
      Button.module.css      <-- .btn-primary, .filter-tab, .lightbox-nav, .lightbox-close, .expand-indicator
    /Badge
      Badge.tsx
      Badge.module.css       <-- .tag, .tag-core, .project-type-badge
    /Eyebrow
      Eyebrow.tsx
      Eyebrow.module.css     <-- .section-label, .welcome-eyebrow, .skills-heading
    /ExternalLink
      ExternalLink.tsx
      ExternalLink.module.css <-- .research-link, .research-doc-link, .project-link, .closing-text-link
    /Avatar
      Avatar.tsx
      Avatar.module.css      <-- .bio-avatar

  /molecules
    /SectionHeader
      SectionHeader.tsx
      SectionHeader.module.css <-- .projects-header, .projects-sub
    /KeyValueRow
      KeyValueRow.tsx
      KeyValueRow.module.css   <-- .bio-info-item, .bio-info-label, .bio-info-value, .lang-item, .lang-name, .lang-level
    /FilterGroup
      FilterGroup.tsx
      FilterGroup.module.css   <-- .project-filters
    /AccordionHeader
      AccordionHeader.tsx
      AccordionHeader.module.css <-- .project-card-header, .project-meta, .project-period, .project-name, .project-tagline, .project-tags

  /organisms
    /Lightbox
      Lightbox.tsx
      Lightbox.module.css      <-- .lightbox, .lightbox-content, .lightbox-img, .lightbox-counter
    /ExpandableCard
      ExpandableCard.tsx
      ExpandableCard.module.css <-- .project-item, .project-detail-wrapper, .project-detail, .project-story, .project-images, .project-thumbnail
    /Welcome
      Welcome.tsx
      Welcome.module.css       <-- .welcome, .welcome-content, .welcome-title, .welcome-role, .welcome-philosophy, .welcome-actions, .welcome-scroll
    /About
      About.tsx
      About.module.css         <-- .about, .about-grid, .about-bio, .about-skills, .bio-identity, .bio-meta, .bio-role, .bio-text, .bio-info-row, .skills-block, .skills-core, .skills-rows, .skills-row, .tech-group-label, .tech-tags, .lang-list, .research-block, .research-body, .research-title, .research-links, .research-sep
    /Projects
      Projects.tsx
      Projects.module.css      <-- .projects, .project-list, .projects-footer, .philo-quote
    /Closing
      Closing.tsx
      Closing.module.css       <-- .closing, .closing-inner, .closing-title, .closing-text, .closing-email, .closing-links, .clink-platform, .clink-handle, .closing-footer, .footer-divider, .copyright
    /Nav (App.tsx または Nav.tsx)
      Nav.tsx
      Nav.module.css           <-- .nav, .nav-inner, .nav-logo, .nav-links, .nav-link

  /templates
    /SectionTemplate
      SectionTemplate.tsx
      SectionTemplate.module.css <-- .section-container
```

## 2. 移行プロセスとルール
1. **Colocation:** 各コンポーネントディレクトリに `[ComponentName].module.css` を作成します。
2. **CSS Modulesの適用:** 各 `.tsx` ファイルで `import styles from './[ComponentName].module.css';` を行い、`className="xxx"` を `className={styles.xxx}` に置換します。
   *※ハイフン（`-`）を含むクラス名（例：`btn-primary`）は、キャメルケース（例：`styles.btnPrimary`）に変更するか、`styles['btn-primary']` で参照します（通常はキャメルケースを推奨）。*
3. **Variantsの整理:** `Button` や `Badge` など、ベースのスタイル＋バリアントのスタイルがあるものは、CSS Modules のクラスを動的に結合します（例: `` `${styles.badge} ${styles[variant]} ${styles[color]}` ``）。
4. **`index.css` のクリーンアップ:** 移行が完了したクラスを `index.css` から順次削除します。

## 3. 残るグローバルスタイル (`index.css`)
移行後、`index.css` には以下のような Truly Global Styles のみが残ります。
- **CSS変数:** `:root { --bg, --text-primary, --font-display, --spacing-xs, etc. }`
- **リセット / グローバル設定:** `* { margin: 0; }`, `html { scroll-behavior: smooth; }`, `body { ... }`
- **キーフレームアニメーション:** `@keyframes fadeUp`, `@keyframes fadeIn`
- **疑似要素:** `body::before` (ノイズエフェクト)
- **スクロールバーのカスタマイズ:** `::-webkit-scrollbar` など
- **基本のタイポグラフィタグ:** `h1, h2, h3, h4`

## 4. 重構まとめ (Expected Outcome)
このリファクタリングにより、**「どのスタイルがどこで使われているか分からない」という状態がなくなり**、コンポーネントを修正する際の影響範囲が完全に閉じた（Encapsulated）状態になります。また、CSS モジュールによってクラス名の衝突（Global Namespace Collision）が防げます。

---
この計画で進めてよろしいでしょうか？（よろしければ Atoms から順に CSS Modules への分離と TSX の書き換えを実行していきます）
