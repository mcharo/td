[CmdletBinding()]
param()

function Add-TdTask {
    [CmdletBinding()]
    param(
        $Task
    )
    $script:Tasks += New-Object -TypeName psobject -Property @{
        Id = (New-Guid).ToString()
        Timestamp = Get-Date
        Task = $Task
        Status = 'Open'
    }
}

function Resolve-TdTask {
    [CmdletBinding()]
    param(
        $Task
    )
    if ($Task -match '\d+') {
        Get-TdTaskFromIndex -Index $Task
    } else {
        $script:Tasks | Where-Object Task -eq $Task
    }
}

function Complete-TdTask {
    [CmdletBinding()]
    param(
        $Task
    )
    Write-Verbose "Completing task: $Task"
    $ActionTask = Resolve-TdTask -Task $Task
    if ($ActionTask) {
        $ActionTask.Status = 'Completed'
    }
}

function Get-OpenTdTasks {
    [CmdletBinding()]
    param()
    $script:Tasks | Where-Object Status -eq 'Open' | Sort-Object -Property Timestamp -Descending
}

function Get-ClosedTdTasks {
    [CmdletBinding()]
    param()
    $script:Tasks | Where-Object Status -eq 'Completed' | Sort-Object -Property Timestamp -Descending
}

function Get-TdTaskFromIndex {
    [CmdletBinding()]
    param(
        [int]$Index
    )
    $IndexedTasks = @()
    $IndexedTasks += Get-OpenTdTasks
    $IndexedTasks += Get-ClosedTdTasks
    $IndexedTasks[$Index - 1]
}
function Remove-TdTask {
    [CmdletBinding()]
    param(
        $Task
    )
    $ActionTask = Resolve-TdTask -Task $Task
    if ($ActionTask) {
        $script:Tasks = $script:Tasks | Where-Object Id -ne $ActionTask.Id
    }
}

function Exit-TdTask {
    [CmdletBinding()]
    param(
        $Task
    )
    $script:Tasks
    exit
}

function Save-TdTasks {
    [CmdletBinding()]
    param()
    $script:Tasks | ConvertTo-Json | Out-File -FilePath $script:BackingFile
}

function Show-Tasks {
    [CmdletBinding()]
    param()
    $Count = 1
    Write-Host "Open tasks:"
    Get-OpenTdTasks | ForEach-Object { Write-Host "`t$Count. $($_.Task) 😰"; $Count++ }
    Write-Host "Completed tasks:"
    Get-ClosedTdTasks | ForEach-Object { Write-Host "`t$Count. $($_.Task) 😌"; $Count++ }
}

$TdPath = "$env:HOME/.td"
if (-Not (Test-Path -Path $TdPath)) {
    $null = New-Item -Path $TdPath -ItemType Directory
}
$BackingFile = "$TdPath/tasks.json"
if (Test-Path -Path $BackingFile) {
    $Tasks = Get-Content -Raw -Path $BackingFile | ConvertFrom-Json
    if ($Tasks.Count -eq 0) {
        $Tasks = @()
    }
} else {
    $null = New-Item -Path $BackingFile -ItemType File
    $Tasks = @()
}

$Actions = @{
    Add = Get-Command Add-TdTask
    Complete = Get-Command Complete-TdTask
    Remove = Get-Command Remove-TdTask
    Reopen = Get-Command Open-Task
    Quit = Get-Command Exit-TdTask
}

while ($true) {
    Show-Tasks
    $Command = Read-Host -Prompt 'Command'
    $Action, $Task = $Command.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    $RegexAction = "^$([regex]::Escape($Action))"
    if ($Matchion = $Actions.Keys -match $RegexAction) {
        & $Actions[$Matchion] ($Task -join ' ')
        Save-TdTasks
    } else {
        Write-Host "Invalid action: $Action"
    }
}
