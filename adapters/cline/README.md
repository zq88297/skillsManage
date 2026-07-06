# Cline Adapter

Cline 使用 `.clinerules` 文件，格式与 Cursor 的 `.cursorrules` 完全兼容。

## 使用方式

1. 先用 Cursor 导出脚本生成为 `.cursorrules`：
   ```powershell
   .\scripts\export-cursor.ps1 -OutputPath F:\MyProject
   ```

2. 重命名为 `.clinerules`：
   ```powershell
   Rename-Item F:\MyProject\.cursorrules .clinerules
   ```

或者直接生成：
   ```powershell
   .\scripts\export-cursor.ps1 -OutputPath F:\MyProject
   Move-Item F:\MyProject\.cursorrules F:\MyProject\.clinerules
   ```

## 限制

与 Cursor 相同的限制：无触发条件、无斜杠命令、无依赖解析。
