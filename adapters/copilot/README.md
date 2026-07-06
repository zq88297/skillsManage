# GitHub Copilot Adapter

GitHub Copilot 使用 `.github/copilot-instructions.md` 作为自定义指令文件。

## 使用方式

1. 先用 Cursor 导出脚本生成规则文件：
   ```powershell
   .\scripts\export-cursor.ps1 -OutputPath F:\MyProject
   ```

2. 将内容复制到 Copilot 指令文件：
   ```powershell
   New-Item -ItemType Directory -Force -Path F:\MyProject\.github
   Copy-Item F:\MyProject\.cursorrules F:\MyProject\.github\copilot-instructions.md
   ```

## 限制

- Copilot 指令文件没有触发条件机制 — 内容始终在上下文中
- Markdown 格式被支持，但无 frontmatter 解析
- 建议只导出通用规则，去掉项目特定的工作流指令
