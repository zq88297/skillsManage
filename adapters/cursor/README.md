# Cursor Adapter

将技能导出为 Cursor 的 `.cursorrules` 格式。

## 使用方式

```powershell
# 从仓库根目录运行
.\scripts\export-cursor.ps1 -OutputPath F:\MyProject
```

这会在目标目录生成 `.cursorrules` 文件，包含所有技能的规则内容（按依赖顺序排列）。

## 限制

Cursor 的 `.cursorrules` 不支持：
- YAML frontmatter（触发条件）— 规则始终生效
- 斜杠命令（slash commands）— 命令内容合并为规则文本
- 自动依赖解析 — 所有规则在一个文件中

**建议：** 在 Cursor 中定期回到本仓库同步最新版本。
