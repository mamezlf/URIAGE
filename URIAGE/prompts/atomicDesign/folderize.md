请帮我重构当前组件目录结构。

目前：

```txt
/components/atoms
  Button.tsx
  Button.module.css

我希望改成：

/components/atoms/Button
  Button.tsx
  Button.module.css
  index.ts（如果需要）

请自动完成：

创建对应组件文件夹
移动 tsx 和 module.css 文件
自动修复 import 路径
更新 export/index 文件（如果有）
保持现有功能和样式不变
不修改组件逻辑

规则：

一个组件一个文件夹
样式与组件 colocated
保持 Atomic Design 结构
使用 PascalCase 组件目录名
不要创建多余文件

请输出：

重构后的目录结构
修改的 import/export 内容
所有被移动的文件