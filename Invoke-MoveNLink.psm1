
function Invoke-MoveNLink {
    param (
        # Source
        [Parameter(Mandatory=$true)]
        [string]
        $SourceFilePath,
        # Destination
        [Parameter(Mandatory=$true)]
        [string]
        $DestinationFilePath,
        # MaxLastWriteTime
        [Parameter(Mandatory=$true)]
        [datetime]
        $MaxLastWriteTime
    )
    
    if (-not (Test-Path -Path $SourceFilePath)) {
        Write-Error "Invalid source path"
        return
    }
    if (-not (Test-Path -Path $DestinationFilePath)) {
        New-Item -ItemType Directory -Path $DestinationFilePath -ErrorAction Stop
    }
    else {
        Write-Verbose "Destination directory already exists"
    }

    $SourceFiles = Get-ChildItem -Path $SourceFilePath -File -Recurse -Force | Where-Object -Property LastWriteTime -lt $MaxLastWriteTime
    $SourceDirectories = Get-ChildItem -Path $SourceFilePath -Directory -Recurse

    #Create all directories
    $SourceDirectories | Foreach-Object {
        $d = $DestinationFilePath + $_.FullName.Substring($SourceFilePath.Length)
        if (-not (Test-Path -Path $d)) {
            New-Item -ItemType Directory -Path $d
        }
    }
    # $SourceFiles | format-table

    $SourceFiles | Foreach-Object {
        $d = $DestinationFilePath + $_.FullName.Substring($SourceFilePath.Length)
        $f = $_.CopyTo($d,$true)
        # New-Item -ItemType SymbolicLink -Path
    }

}
