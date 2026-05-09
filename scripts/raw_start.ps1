<#
.SYNOPSIS
    实验室管理系统 - Windows裸机一键部署 (无需Docker)
.DESCRIPTION
    自动检测/安装 Java21 + Node18+ + MySQL8 + Maven
    自动初始化数据库、编译后端、启动前后端
    支持交互式选择部署哪些组件
.NOTES
    以管理员身份运行效果最佳
    首次运行会自动通过 winget 安装缺失环境
#>

$Host.UI.RawUI.WindowTitle = "实验室管理系统 - 裸机部署"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ProjectRoot

# 配置
$javaMinVersion  = 21
$nodeMinVersion  = 18
$mysqlPort       = 3306
$mysqlDbName     = "lab_management"
$mysqlUser       = "root"
$mysqlPassword   = ""
$backendPort     = 8081
$frontendPort    = 3000

# ============================================
# 工具函数
# ============================================
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       实验室管理系统 - Windows 裸机一键部署              ║" -ForegroundColor Cyan
    Write-Host "║       无需 Docker，直接运行在 Windows 上                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step  { Write-Host "`n>> $args" -ForegroundColor Yellow }
function Write-OK    { Write-Host "   √ $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "   ! $args" -ForegroundColor Yellow }
function Write-Err   { Write-Host "   × $args" -ForegroundColor Red }
function Write-Info  { Write-Host "   · $args" -ForegroundColor Gray }

function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warn "建议以管理员身份运行（右键 → 以管理员身份运行）"
        Write-Warn "非管理员模式下 MySQL 服务配置可能失败"
        Write-Host ""
    }
    return $isAdmin
}

# ============================================
# 1. Java 检测与安装
# ============================================
function Ensure-Java {
    Write-Step "检测 Java 环境..."
    $found = $false

    # 尝试从常见路径找
    $paths = @(
        "$env:JAVA_HOME\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-21*\bin\java.exe",
        "C:\Program Files\Microsoft\jdk-21*\bin\java.exe",
        "C:\Program Files\Java\jdk-21*\bin\java.exe"
    )
    foreach ($p in $paths) {
        $found_path = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found_path) {
            $env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $found_path.FullName)
            $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
            $found = $true
            break
        }
    }

    # 用 java -version 验证
    if (-not $found) {
        try { $ver = (& java -version 2>&1 | Out-String); $found = ($ver -match "version") } catch {}
    }

    if ($found) {
        $ver = (& java -version 2>&1 | Select-String "version").ToString()
        Write-OK "Java: $ver"
        if ($env:JAVA_HOME) { Write-Info "JAVA_HOME=$env:JAVA_HOME" }
        return $true
    }

    Write-Warn "Java 21 未安装，正在通过 winget 安装..."
    winget install EclipseAdoptium.Temurin.21.JDK --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Java 21 安装完成"
        Write-Warn "请关闭此窗口，重新打开后再运行本脚本（需要刷新 PATH）"
        Read-Host "按回车退出"
        exit 0
    } else {
        Write-Err "Java 安装失败，请手动下载: https://adoptium.net/download/"
        return $false
    }
}

# ============================================
# 2. Node.js 检测与安装
# ============================================
function Ensure-Node {
    Write-Step "检测 Node.js 环境..."
    $found = $false
    try { $ver = (& node --version); $found = $true } catch {}

    if ($found) {
        $major = [int]($ver -replace 'v','' -split '\.')[0]
        if ($major -ge $nodeMinVersion) {
            Write-OK "Node.js: $ver"
            return $true
        }
        Write-Warn "Node.js 版本 $ver 过低，需要 18+"
    }

    Write-Warn "正在通过 winget 安装 Node.js 20 LTS..."
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Node.js 安装完成"
        Write-Warn "请关闭此窗口，重新打开后再运行本脚本"
        Read-Host "按回车退出"
        exit 0
    } else {
        Write-Err "安装失败，请手动下载: https://nodejs.org/"
        return $false
    }
}

# ============================================
# 3. MySQL 检测与安装
# ============================================
function Ensure-MySQL {
    Write-Step "检测 MySQL 环境..."

    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue

    if (-not $mysqlService) {
        Write-Warn "MySQL 服务未安装"
        Write-Info "正在通过 winget 安装 MySQL 8.0..."
        winget install Oracle.MySQL --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -ne 0) {
            Write-Err "MySQL 安装失败"
            Write-Info "也可以使用 XAMPP 自带的 MySQL: https://www.apachefriends.org/"
            Write-Info "或者 MariaDB: winget install MariaDB.Server"
            return $false
        }
        Write-OK "MySQL 安装完成"
        Write-Warn "请关闭窗口重新打开，然后重新运行本脚本"
        Read-Host "按回车退出"
        exit 0
    }

    # 检查服务是否运行
    $svc = Get-Service -Name $mysqlService.Name -ErrorAction SilentlyContinue
    if ($svc.Status -ne 'Running') {
        Write-Warn "MySQL 服务未运行，正在启动..."
        Start-Service -Name $mysqlService.Name -ErrorAction SilentlyContinue
        Start-Sleep 3
    }
    Write-OK "MySQL 服务: $($svc.Status)"

    # 检查 mysql 命令
    if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) {
        Write-Warn "mysql 命令不在 PATH 中，正在查找..."
        $mysqlPath = (Get-Item "C:\Program Files\MySQL\MySQL Server 8.*\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($mysqlPath) {
            $mysqlDir = Split-Path -Parent $mysqlPath
            $env:PATH = "$mysqlDir;$env:PATH"
            Write-OK "已添加 MySQL bin 到 PATH"
        }
    }

    return $true
}

# ============================================
# 4. Maven 检测与安装
# ============================================
function Ensure-Maven {
    Write-Step "检测 Maven..."
    $found = $false
    try { $ver = (& mvn --version 2>&1 | Select-Object -First 1); $found = $true } catch {}

    if ($found) {
        Write-OK "Maven: $ver"
        return $true
    }

    Write-Warn "Maven 未安装，正在通过 winget 安装..."
    winget install Apache.Maven.3 --accept-source-agreements --accept-package-agreements

    # Maven 可能在 Program Files 下
    $mvnHome = Get-Item "C:\Program Files\apache-maven-*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($mvnHome) {
        $env:PATH = "$($mvnHome.FullName)\bin;$env:PATH"
    }
    Write-OK "Maven 安装完成"
    return $true
}

# ============================================
# 5. 初始化数据库
# ============================================
function Init-Database {
    Write-Step "初始化数据库..."
    $schemaFile = Join-Path $ProjectRoot "backend\src\main\resources\db\schema.sql"
    if (-not (Test-Path $schemaFile)) {
        Write-Err "schema.sql 不存在: $schemaFile"
        return $false
    }

    # 读取 MySQL root 密码
    if (-not $mysqlPassword) {
        $mysqlPassword = Read-Host "请输入 MySQL root 密码（无密码直接回车）"
    }

    $mysqlArgs = "-u root"
    if ($mysqlPassword) { $mysqlArgs += " -p$mysqlPassword" }

    # 创建数据库
    Write-Info "创建数据库 $mysqlDbName ..."
    $createDb = "CREATE DATABASE IF NOT EXISTS $mysqlDbName DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    & echo $createDb | mysql $mysqlArgs 2>$null

    # 导入 schema
    Write-Info "导入表结构..."
    Get-Content $schemaFile -Encoding UTF8 | mysql $mysqlArgs $mysqlDbName 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-OK "数据库初始化完成"
        return $true
    }
    Write-Err "数据库初始化失败，请检查 MySQL 密码是否正确"
    return $false
}

# ============================================
# 6. 构建后端
# ============================================
function Build-Backend {
    Write-Step "构建后端 (Maven)..."
    $backendDir = Join-Path $ProjectRoot "backend"

    Push-Location $backendDir
    Write-Info "正在编译 (首次会下载依赖，需要几分钟)..."
    mvn clean package -DskipTests -q 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-OK "后端编译成功"
        Pop-Location
        return $true
    }
    Write-Err "后端编译失败"
    Pop-Location
    return $false
}

# ============================================
# 7. 启动后端
# ============================================
function Start-Backend {
    Write-Step "启动后端服务..."
    $jarFile = Get-Item (Join-Path $ProjectRoot "backend\target\*.jar") | Select-Object -First 1
    if (-not $jarFile) {
        Write-Err "找不到 JAR 文件，请先执行 [编译后端]"
        return
    }

    # 检查是否已在运行
    $existing = netstat -ano | Select-String ":$backendPort " | Select-String "LISTENING"
    if ($existing) {
        Write-Warn "端口 $backendPort 已被占用"
        $pid = ($existing -split '\s+')[-1]
        Write-Info "进程 PID: $pid，正在终止..."
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Start-Sleep 2
    }

    Write-Info "启动 Spring Boot (端口 $backendPort)..."
    $proc = Start-Process java -ArgumentList "-jar `"$($jarFile.FullName)`" --server.port=$backendPort" `
        -WindowStyle Minimized -PassThru
    Write-OK "后端进程 PID: $($proc.Id)"
    Write-Info "等待启动中..."
    Start-Sleep 15

    # 健康检查
    for ($i = 1; $i -le 30; $i++) {
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:$backendPort/api/actuator/health" -TimeoutSec 2 -UseBasicParsing
            if ($r.StatusCode -eq 200) {
                Write-OK "后端启动成功 (http://localhost:$backendPort/api)"
                return
            }
        } catch {}
        Start-Sleep 2
        if ($i % 10 -eq 0) { Write-Info "等待中... ($i/30)" }
    }
    Write-Warn "后端启动超时，请检查日志"
}

# ============================================
# 8. 启动前端
# ============================================
function Start-Frontend {
    Write-Step "启动前端服务..."
    $frontendDir = Join-Path $ProjectRoot "frontend"

    # 检查 node_modules
    if (-not (Test-Path (Join-Path $frontendDir "node_modules"))) {
        Write-Info "安装前端依赖..."
        Push-Location $frontendDir
        npm install --registry=https://registry.npmmirror.com 2>&1 | Out-Null
        Pop-Location
        Write-OK "依赖安装完成"
    }

    Push-Location $frontendDir
    Write-Info "启动 Vite 开发服务器 (http://localhost:$frontendPort)..."
    Start-Process npm -ArgumentList "run dev" -WindowStyle Minimized
    Pop-Location
    Write-OK "前端已启动，浏览器访问 http://localhost:$frontendPort"
}

# ============================================
# 9. 环境总览
# ============================================
function Show-Status {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    环境状态总览                          ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    # Java
    try { $j = (& java -version 2>&1 | Select-String "version").ToString() }
    catch { $j = "未安装" }
    Write-Host ("║  Java:     {0,-48}║" -f ($j -replace '\s+', ' ').Substring(0,[Math]::Min(48,($j -replace '\s+', ' ').Length))) -ForegroundColor Green

    # Node
    try { $n = (& node --version) } catch { $n = "未安装" }
    Write-Host ("║  Node.js:  {0,-48}║" -f $n) -ForegroundColor Green

    # MySQL
    $msvc = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
    $mysqlStatus = if ($msvc) { "$($msvc.Name) - $($msvc.Status)" } else { "未安装" }
    Write-Host ("║  MySQL:    {0,-48}║" -f $mysqlStatus) -ForegroundColor Green

    # Maven
    try { $m = (& mvn --version 2>&1 | Select-Object -First 1) } catch { $m = "未安装" }
    Write-Host ("║  Maven:    {0,-48}║" -f ($m.Substring(0,[Math]::Min(48,$m.Length)))) -ForegroundColor Green

    # 端口监听
    $bRunning = (netstat -ano | Select-String ":$backendPort " | Select-String "LISTENING") -ne $null
    $fRunning = (netstat -ano | Select-String ":$frontendPort " | Select-String "LISTENING") -ne $null
    Write-Host ("║  后端({0}):  {1,-47}║" -f $backendPort, $(if($bRunning){"运行中"}else{"未启动"})) -ForegroundColor $(if($bRunning){'Green'}else{'Red'})
    Write-Host ("║  前端({0}):  {1,-47}║" -f $frontendPort, $(if($fRunning){"运行中"}else{"未启动"})) -ForegroundColor $(if($fRunning){'Green'}else{'Red'})
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# ============================================
# 主菜单
# ============================================
function Show-Menu {
    Write-Banner
    Show-Status
    Write-Host ""
    Write-Host "  请选择操作:" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "  [1] 一键安装 + 部署 (推荐首次使用)" -ForegroundColor Green
    Write-Host "  [2] 仅安装环境 (Java + Node + MySQL + Maven)" -ForegroundColor Yellow
    Write-Host "  [3] 仅初始化数据库" -ForegroundColor Yellow
    Write-Host "  [4] 仅编译后端" -ForegroundColor Yellow
    Write-Host "  [5] 仅启动后端" -ForegroundColor Yellow
    Write-Host "  [6] 仅启动前端" -ForegroundColor Yellow
    Write-Host "  [7] 完整启动 (编译后端+启动前后端)" -ForegroundColor Cyan
    Write-Host "  [8] 停止所有服务" -ForegroundColor Red
    Write-Host "  [0] 退出" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# 一键部署 (ALL)
# ============================================
function Invoke-AllInOne {
    Write-Banner
    Write-Host "  一键部署开始..." -ForegroundColor Green
    Write-Host ""

    $ok = $true
    $ok = $ok -and (Ensure-Java)
    $ok = $ok -and (Ensure-Node)
    $ok = $ok -and (Ensure-Maven)
    $ok = $ok -and (Ensure-MySQL)

    if (-not $ok) {
        Write-Err "环境安装有问题，请手动处理后再试"
        return
    }

    Init-Database
    Build-Backend
    Start-Backend
    Start-Frontend

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    部署完成！                            ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║  前端页面: http://localhost:$frontendPort                          ║" -ForegroundColor Green
    Write-Host "║  后端API:  http://localhost:$backendPort/api                        ║" -ForegroundColor Green
    Write-Host "║  默认账号: admin / admin123                             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
}

# ============================================
# 仅安装环境
# ============================================
function Invoke-InstallEnvOnly {
    Ensure-Java
    Ensure-Node
    Ensure-Maven
    Ensure-MySQL
}

# ============================================
# 停止服务
# ============================================
function Invoke-Stop {
    Write-Step "停止所有服务..."
    $b = netstat -ano | Select-String ":$backendPort " | Select-String "LISTENING"
    if ($b) { Stop-Process -Id ($b -split '\s+')[-1] -Force -ErrorAction SilentlyContinue; Write-OK "后端已停止" }
    $f = netstat -ano | Select-String ":$frontendPort " | Select-String "LISTENING"
    if ($f) { Stop-Process -Id ($f -split '\s+')[-1] -Force -ErrorAction SilentlyContinue; Write-OK "前端已停止" }
    Write-OK "完成"
}

# ============================================
# 主循环
# ============================================
function Main {
    Test-Admin | Out-Null

    while ($true) {
        Show-Menu
        $choice = Read-Host "  请输入数字选择"
        Write-Host ""

        switch ($choice) {
            "1" { Invoke-AllInOne; Read-Host "按回车返回菜单" }
            "2" { Invoke-InstallEnvOnly; Read-Host "按回车返回菜单" }
            "3" { Init-Database; Read-Host "按回车返回菜单" }
            "4" { Build-Backend; Read-Host "按回车返回菜单" }
            "5" { Start-Backend; Read-Host "按回车返回菜单" }
            "6" { Start-Frontend; Read-Host "按回车返回菜单" }
            "7" {
                Build-Backend
                Start-Backend
                Start-Frontend
                Read-Host "按回车返回菜单"
            }
            "8" { Invoke-Stop; Read-Host "按回车返回菜单" }
            "0" { Write-Host "  再见！"; exit 0 }
            default { Write-Warn "无效选择，请重新输入" }
        }
    }
}

Main
