
function Invoke-MoveNLink {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][datetime]$MaxLastWriteTime,
        [Parameter(Mandatory=$False)][string[]]$ExcludeFileExtensions,
        [Parameter(Mandatory=$False)][switch]$Recurse,
        [Parameter(Mandatory=$False)][switch]$WhatIf
    )
    
    # VALIDATE SOURCE PATH
    try {
        $SourceItem = Get-Item -Path $Path -ErrorAction Stop
    }
    catch {
        Write-Error -ErrorRecord $_
        break
    }
    Write-Verbose "Path found $($SourceItem.FullName)"
    if ( -not ($SourceItem.PSIsContainer) ) {
        Write-Error "Source path is not a container"
        return
    }

    # VALIDATE DESTINATION PATH
    if (-not (Test-Path -Path $Destination)) {
        $ResultDestinationDirectory = New-Item -ItemType Directory -Path $Destination -ErrorAction Stop
        Write-Verbose "Destination directory created $($ResultDestinationDirectory.FullName)"
    }
    else {
        Write-Verbose "Destination directory already exists"
    }

    # PARAMATERS FOR SPLATTING TO GET-CHILDITEM FOR SOURCE PATH
    $GCIparam = @{Path=$SourceItem.FullName;Recurse=$false;Exclude=""}
    if ($Recurse.IsPresent) {
        $GCIparam.Recurse = $true
    }
    if ($ExcludeFileExtensions) {
        for ($i = 0; $i -lt $ExcludeFileExtensions.Count; $i++) {
            if ($ExcludeFileExtensions[$i][0] -ne "*") {
                $ExcludeFileExtensions[$i] = $ExcludeFileExtensions[$i].Insert(0,"*")
            }
            if ($ExcludeFileExtensions[$i][1] -ne ".") {
                $ExcludeFileExtensions[$i] = $ExcludeFileExtensions[$i].Insert(1,".")
            }
        }
        $GCIparam.Exclude = $ExcludeFileExtensions
    }
    
    # GET SOURCE FILES AND DIRECTORIES
    $AllChildItems = Get-ChildItem @GCIparam
    $SourceFiles = $AllChildItems | Where-Object  {$_.LastWriteTime -lt $MaxLastWriteTime -and $_.PSIsContainer -EQ $False -and $_.Attributes -notmatch "ReparsePoint"}
    $SourceDirectories = $AllChildItems | Where-Object {$_.PSIsContainer -EQ $True}
    Write-Verbose "Found in source $($SourceDirectories.Count) directories and $($SourceFiles.Count) files"

    # WHATIF PARAMETER FOR SPLATTING TO IMPACTFUL CMDLETS
    $WhatIfParam = @{WhatIf=$false}
    if ($WhatIf.IsPresent) {
        $WhatifParam.WhatIf = $true
    }

    # CREATE DESTINATION DIRECTORIES AND SUBDIRECTORIES
    $ResultDirectories = $SourceDirectories | Foreach-Object {
        $d = $Destination + $_.FullName.Substring($Path.Length)
        if (-not (Test-Path -Path $d)) {
            New-Item -ItemType Directory -Path $d @WhatIfParam
        }
    }
    Write-Verbose "Created $($ResultDirectories.Count) directories in the destination directory"

    # COPY SOURCE FILES TO DESTINATION AND CREATE SYMBOLIC LINK IN SOURCE
    $ResultSymLinks = $SourceFiles | Foreach-Object {
        $d = $Destination + $_.FullName.Substring($Path.Length)
        # $f = $_.CopyTo($d,$true)
        Copy-Item -Path $_.FullName -Destination $d @WhatifParam | Out-Null
        # New-Item -ItemType SymbolicLink -Path $_.FullName -Target $f.FullName -Force @WhatifParam
        New-Item -ItemType SymbolicLink -Path $_.FullName -Target $d -Force @WhatifParam
    }

    Write-Output "Copied and created symbolic links for $($ResultSymLinks.Count) files in the source directory"

}
