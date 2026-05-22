<#
.SYNOPSIS
    OSED用アプリケーション再起動&Windbgアタッチコマンド
.DESCRIPTION
    サービス名、またはアプリケーションの絶対パスを使用し、対象が起動している場合は再起動、未起動の場合は起動してからWindbgで対象ぷろせすにアタッチする
.PARAMETER ServiceName
    デバッグ対象サービス名
.PARAMETER BinaryPath
    デバッグ対象バイナリの絶対パス
.PARAMETER WindbgCommand
    アタッチ後に実行するWindbgコマンド
.EXAMPLE
    Debug -ServiceName fastbackserver -WindbgCommand 'bp kernelbase!virtualprotect;g'
    Debug -BinaryPath 'C:\VulnApp1.exe' -WindbgCommand 'bp kernelbase!virtualprotect;g'
#>

[CmdletBinding(DefaultParameterSetName='BinaryPath')]
param(
    [Parameter(Mandatory, ParameterSetName='BinaryPath')]
    [string]$BinaryPath,

    [Parameter(Mandatory, ParameterSetName='ServiceName')]
    [string]$ServiceName,

    [Parameter()]
    [string]$WindbgCommand
)


begin {
    Write-Verbose 'Restart process or service and attach Windbg...'
    $ErrorActionPreference = 'Stop'
}

process {
    $CommandLine = ""

    switch($PSCmdlet.ParameterSetName) {
        'BinaryPath' {
            if (-not (Test-Path $BinaryPath)) {
                Write-Error "Does not exists: $BinaryPath"
                exit 1
            }

            $Process = Get-Process | Where-Object { $_.Path -eq $BinaryPath }
            if(-not $Process) {
                Start-Process -FilePath $BinaryPath
                $Deadline = (Get-Date).AddSeconds(5)
                while ((Get-Date) -lt $Deadline) {
                    $Process = Get-Process | Where-Object { $_.Path -eq $BinaryPath }
                    if ($Process) { break; }
                }
            }

            if (-not $Process) {
                Write-Error "The process did not start within the specified time."
                exit 1
            }

            $CommandLine += "-p $($Process.id)"
        }
        'ServiceName' {
            $Service  = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$ServiceName'"
            if (-not $Service) {
                Write-Error "Service does not exists: $ServiceName"
                exit 1
            }

            if ($Service.State -ne 'Running') {
                Start-Service -Name $ServiceName
                $Deadline = (Get-Date).AddSeconds(5)
                while ((Get-Date) -lt $Deadline) {
                    $Service  = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$ServiceName'"
                    if ($Service.State -eq 'Running') { break; }
                }
            }

            if ($Service.State -ne 'Running') {
                Write-Error "The Service did not start within the specified time."
                exit 1
            }

            $CommandLine += "-p $($Service.ProcessId)"
        }
    }

    $WindbgPath = ''
    if ([IntPtr]::Size -eq 8) {
        $WindbgPath = "C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\windbg.exe"
    } else {
        $WindbgPath = "C:\Program Files\Windows Kits\10\Debuggers\x86\windbg.exe"
    }

    $CommandLine += ' -c "' + $WindbgCommand + '"'
    Write-Output "Attaching to process. CommandLine: $CommandLine"
    Start-Process -FilePath $WindbgPath -verb RunAs -ArgumentList $CommandLine
}

end {
    Write-Verbose 'Done!'
}
