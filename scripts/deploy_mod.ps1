# ModLocalizePatch 自动部署脚本
# 将构建后的模组文件复制到游戏的本地模组目录

$ErrorActionPreference = "Stop"

# 源目录（构建输出）
$SourceDir = "E:\编码仓库\QY\ModLocalizePatch"

# 目标目录（游戏本地模组目录）
$GameModsDir = "$env:USERPROFILE\Documents\Klei\OxygenNotIncluded\mods\Local"
$TargetDir = Join-Path $GameModsDir "ModLocalizePatch"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ModLocalizePatch 自动部署工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查源目录是否存在
if (-not (Test-Path $SourceDir))
{
    Write-Host " 错误: 源目录不存在: $SourceDir" -ForegroundColor Red
    exit 1
}

# 检查必要的文件
$RequiredFiles = @("ModLocalizePatch.dll", "mod.yaml", "mod_info.yaml", "preview.png")
$RequiredDirs = @("localizations")

foreach ($file in $RequiredFiles)
{
    $filePath = Join-Path $SourceDir $file
    if (-not (Test-Path $filePath))
    {
        Write-Host "✗ 错误: 缺少必要文件: $file" -ForegroundColor Red
        exit 1
    }
}

foreach ($dir in $RequiredDirs)
{
    $dirPath = Join-Path $SourceDir $dir
    if (-not (Test-Path $dirPath))
    {
        Write-Host "✗ 错误: 缺少必要目录: $dir" -ForegroundColor Red
        exit 1
    }
}

# 创建目标目录
if (-not (Test-Path $GameModsDir))
{
    Write-Host "✗ 错误: 游戏模组目录不存在: $GameModsDir" -ForegroundColor Red
    Write-Host "  请确认游戏已至少运行过一次。" -ForegroundColor Yellow
    exit 1
}

Write-Host "→ 创建目标目录: $TargetDir" -ForegroundColor Green
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# 复制文件
Write-Host ""
Write-Host "正在复制文件..." -ForegroundColor Cyan

$filesToCopy = @(
    "ModLocalizePatch.dll",
    "mod.yaml",
    "mod_info.yaml",
    "preview.png",
    "README.md"
)

foreach ($file in $filesToCopy)
{
    $src = Join-Path $SourceDir $file
    $dst = Join-Path $TargetDir $file
    Copy-Item -Path $src -Destination $dst -Force
    Write-Host "  ✓ $file" -ForegroundColor Gray
}

# 复制 localizations 目录（递归）
Write-Host "  ✓ localizations/ (包含所有翻译文件)" -ForegroundColor Gray
$srcLoc = Join-Path $SourceDir "localizations"
$dstLoc = Join-Path $TargetDir "localizations"
New-Item -ItemType Directory -Path $dstLoc -Force | Out-Null
# 使用 robocopy /MIR 镜像 localizations 目录树：既稳健合并（Copy-Item -Recurse -Force 在目标已存在
# 同名子目录时会抛"无法将容器复制到现有叶项"而中止），又自动清除源中已改名/删除的旧翻译文件夹
# （如翻译文件夹改名后游戏目录残留的旧目录）。目标为可从源完整重生的部署产物，镜像安全。退出码 <8 均为成功。
robocopy $srcLoc $dstLoc /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8)
{
    Write-Host "✗ 错误: localizations 复制失败 (robocopy 退出码 $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

# 验证部署
Write-Host ""
Write-Host "验证部署结果..." -ForegroundColor Cyan

$verifyFiles = @(
    "ModLocalizePatch.dll",
    "mod.yaml",
    "localizations\config.json"
)

$allGood = $true
foreach ($file in $verifyFiles)
{
    $filePath = Join-Path $TargetDir $file
    if (-not (Test-Path $filePath))
    {
        Write-Host "  ✗ 缺失: $file" -ForegroundColor Red
        $allGood = $false
    }
    else
    {
        Write-Host "  ✓ 存在: $file" -ForegroundColor Green
    }
}

# 统计翻译文件
$zhFiles = Get-ChildItem -Path (Join-Path $TargetDir "localizations") -Filter "zh.json" -Recurse
Write-Host ""
Write-Host "找到 $( $zhFiles.Count ) 个汉化文件:" -ForegroundColor Cyan
foreach ($f in $zhFiles)
{
    $relativePath = $f.FullName.Substring($TargetDir.Length + 1)
    Write-Host "  • $relativePath" -ForegroundColor Gray
}

Write-Host ""
if ($allGood)
{
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✓ 部署成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "模组目录: $TargetDir" -ForegroundColor White
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Yellow
    Write-Host "  1. 启动缺氧游戏" -ForegroundColor White
    Write-Host "  2. 在模组管理器中启用 '汉化补丁 (ModLocalizePatch)'" -ForegroundColor White
    Write-Host "  3. 同时启用需要汉化的目标模组（如 Wall Pumps、Custom Geysers 等）" -ForegroundColor White
    Write-Host "  4. 查看日志文件获取详细信息：" -ForegroundColor White
    Write-Host "     %USERPROFILE%\AppData\LocalLow\Klei\Oxygen Not Included\Player.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "在日志中搜索 '[ModLocalizePatch]' 可以看到详细的检测和复制过程。" -ForegroundColor Yellow
}
else
{
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ✗ 部署失败，请检查上述错误" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
