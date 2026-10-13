# 冒烟测试一键入口：检查 app 连通性后执行全量冒烟
# 用法: .\tool\run_smoke.ps1 [-Instance suchat]
# app 重新启动后 URI 会变——脚本检测到失联会打印重新注册命令。

param([string]$Instance = "suchat")

[Console]::OutputEncoding = [Text.Encoding]::UTF8

$doctor = & marionette doctor 2>&1 | Out-String
if ($doctor -notmatch "reachable" -or $doctor -match "unreachable") {
  Write-Output "== 实例 '$Instance' 不可达。请按顺序执行："
  Write-Output "  1. flutter run -d windows   (debug 启动 app)"
  Write-Output "  2. 从控制台复制 VM Service 地址，形如 ws://127.0.0.1:端口/xxx/ws"
  Write-Output "  3. marionette register $Instance <粘贴的ws地址>"
  Write-Output "  4. 重新运行本脚本"
  & marionette list
  exit 1
}

& $PSScriptRoot\marionette_smoke.ps1 -Instance $Instance
exit $LASTEXITCODE
