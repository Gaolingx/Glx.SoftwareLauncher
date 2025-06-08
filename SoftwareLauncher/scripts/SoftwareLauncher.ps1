<#
.SYNOPSIS
    一个简单的软件启动器脚本，允许用户选择以普通用户或管理员权限运行，并从列表中启动预定义的软件。
.DESCRIPTION
    此脚本在启动时会询问用户希望以何种权限运行。
    它会显示一个可执行文件列表，用户可以通过按数字键选择启动。
    启动软件后，菜单会重新显示，直到用户按 ESC 键退出。
.NOTES
    文件名: SoftwareLauncher.ps1
    确保脚本中列出的 .exe 文件 (aaa.exe, bbb.exe, ccc.exe) 存在于系统 PATH 环境变量中，
    或者与此脚本位于同一目录下，或者在脚本中为它们提供完整路径。
#>

# 定义一个参数，用于标记脚本是否因提权而成功重启
param (
    [switch]$WasElevatedSuccessfully
)

# 函数：检查当前是否为管理员权限
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 获取初始管理员状态
$scriptIsAdmin = Test-IsAdmin

# --- 权限提升处理 ---
# 如果当前不是管理员权限，并且脚本不是因为提权操作而重启的
if (-not $scriptIsAdmin -and -not $WasElevatedSuccessfully) {
    Clear-Host
    Write-Host "软件启动器 - 权限选择" -ForegroundColor Cyan
    Write-Host "========================="
    Write-Host "1. 以 当前用户 权限运行"
    Write-Host "2. 以 管理员 权限运行 (如果软件运行需要)"
    Write-Host "-------------------------"
    Write-Host "请按数字键选择 (1 或 2):" -NoNewline

    $validElevationChoice = $false
    while (-not $validElevationChoice) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $char = $key.Character

        if ($char -eq '1') {
            Write-Host "`n选择: 以当前用户权限运行。" -ForegroundColor Green
            $validElevationChoice = $true
            # $scriptIsAdmin 保持为 $false
            Start-Sleep -Seconds 1
        } elseif ($char -eq '2') {
            Write-Host "`n选择: 以管理员权限运行。正在尝试提升权限..." -ForegroundColor Yellow
            $validElevationChoice = $true
            try {
                # 使用管理员权限重新启动当前脚本，并传递 -WasElevatedSuccessfully 参数
                $powershellArgs = "-NoProfile -File `"$($MyInvocation.MyCommand.Path)`" -WasElevatedSuccessfully"
                Start-Process PowerShell.exe -Verb RunAs -ArgumentList $powershellArgs -ErrorAction Stop
                # 退出当前的非管理员实例
                exit
            } catch {
                Write-Warning "提升权限失败: $($_.Exception.Message)"
                Write-Host "将以当前用户权限继续运行。" -ForegroundColor Red
                # $scriptIsAdmin 保持为 $false
                Start-Sleep -Seconds 3
            }
        } else {
            Write-Host "`n无效输入。请按 '1' 或 '2'。" -ForegroundColor Red
            Write-Host "请按数字键选择 (1 或 2):" -NoNewline
        }
    }
} elseif ($scriptIsAdmin -and $WasElevatedSuccessfully) {
    # 如果脚本是因提权成功而重启的
    Clear-Host
    Write-Host "已成功以管理员权限启动！" -ForegroundColor Green
    Start-Sleep -Seconds 2
}
# 如果脚本一开始就是管理员权限启动的，或者用户选择了“当前用户”，或者提权失败，则会继续执行。
# 重新检查管理员状态，以确保 $scriptIsAdmin 的值是最新的。
$scriptIsAdmin = Test-IsAdmin

# --- 软件配置 ---
# 假设这些软件 (aaa.exe, bbb.exe, ccc.exe) 存在
# 用户需要确保这些程序位于 PATH 环境变量中，或与脚本在同一目录，或在此处提供完整路径
$softwareApplications = @(
    @{ Name = "《崩坏3》"; Path = "F:\Games\Honkai Impact 3rd Game\BH3.exe" },
    @{ Name = "《崩坏：星穹铁道》"; Path = "F:\Games\Star Rail Game\StarRail.exe" },
    @{ Name = "《绝区零》"; Path = "F:\Games\ZenlessZoneZero Game\ZenlessZoneZero.exe" }
    # --- 测试时可以使用以下常见应用程序 ---
    # @{ Name = "记事本 (Notepad)"; Path = "notepad.exe" },
    # @{ Name = "计算器 (Calculator)"; Path = "calc.exe" },
    # @{ Name = "画图 (Paint)"; Path = "mspaint.exe" }
)

# --- 主应用程序循环 ---
function Display-SoftwareMenu {
    Clear-Host
    Write-Host "软件启动器" -ForegroundColor Cyan
    Write-Host "=========================="
    if ($scriptIsAdmin) {
        Write-Host "当前权限: 管理员" -ForegroundColor Green
    } else {
        Write-Host "当前权限: 普通用户" -ForegroundColor Yellow
    }
    Write-Host "--------------------------"
    for ($i = 0; $i -lt $softwareApplications.Count; $i++) {
        Write-Host "$($i + 1). 启动 $($softwareApplications[$i].Name)"
    }
    Write-Host "ESC. 退出"
    Write-Host "--------------------------"
    Write-Host "请选择要启动的软件 (按数字键) 或按 ESC 退出:" -NoNewline
}

do {
    Display-SoftwareMenu
    $userInput = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $userChar = $userInput.Character
    $userVirtualKey = $userInput.VirtualKeyCode # 获取虚拟键码

    if ($userVirtualKey -eq 27) { # ESC 键的虚拟键码是 27
        Write-Host "`n正在退出启动器..."
        Start-Sleep -Seconds 1
        break # 退出 do...while 循环
    }

    # 检查输入是否为1到9的数字字符
    if ($userChar -match '^[1-9]$') {
        $selectedIndex = 0
        try {
            # 将字符转换为整数，并调整为基于0的索引
            $selectedIndex = [int]::Parse($userChar) - 1
        } catch {
            # 一般不会到这里，因为 regex 已经做了初步过滤
            Write-Host "`n内部错误：无法解析数字输入。" -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue # 继续下一次循环
        }

        if ($selectedIndex -ge 0 -and $selectedIndex -lt $softwareApplications.Count) {
            $appToLaunch = $softwareApplications[$selectedIndex]
            Write-Host "`n正在启动 $($appToLaunch.Name)..."
            try {
                Start-Process -FilePath $appToLaunch.Path -ErrorAction Stop
                Write-Host "$($appToLaunch.Name) 已启动。" -ForegroundColor Green
            } catch {
                Write-Warning "启动 $($appToLaunch.Name) 失败: $($_.Exception.Message)"
                Write-Host "请确保 '$($appToLaunch.Path)' 存在于系统 PATH 环境变量中，或脚本中已提供其完整路径。" -ForegroundColor Yellow
            }
            Write-Host "`n按任意键返回菜单..." -NoNewline
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        } else {
            Write-Host "`n无效的数字选择。请输入列表中的有效数字 (1-$($softwareApplications.Count))。" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } else {
        # 处理非数字键 (且非 ESC 键) 的输入
        Write-Host "`n无效输入。请按列表中的数字键 (1-$($softwareApplications.Count)) 或 ESC 键。" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }

} while ($true)

Write-Host "启动器已关闭。"