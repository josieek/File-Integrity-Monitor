<#
.PURPOSE
    This script allows the user to collect a new baseline or monitor files with a saved baseline.

.DESCRIPTION
    The user can choose between two options:
    - A: Collect a new baseline, which calculates the hash of files in the "Files" folder and stores them in "baseline.txt."
    - B: Begin monitoring files with the saved baseline, which continuously monitors the "Files" folder for file changes.
#>

Write-Host ""
Write-Host "What would you like to do?"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"


$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Existing-Baseline() {
   if(Test-Path -Path .\baseline.txt) {
     # Delelte it
     Remove-Item -Path .\baseline.txt
    }
}
 

if ($response -eq "A".ToUpper()) {
    # Delete baseline.txt if it already exsits
    Erase-Existing-Baseline
    # Calculate Hash from the target files and store in baseline.txt

    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files $directoryPath -File -Recurse

    # For each file, calculate the hash, and write to baseline.txt
    foreach($file in $files) {
        $hash = Calculate-File-Hash $file.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }

}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}
    $notifiedFiles = New-Object -TypeName 'System.Collections.ArrayList';  # Arraylist to keep track of notified files

    # Load file|hash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    foreach ($filepathAndHash in $filePathsAndHashes) {
        $fileHashDictionary.add($filepathAndHash.Split("|")[0], $filepathAndHash.Split("|")[1])
    }

    # Begin (continuously) monitoring files with saved Baseline
    while($true) {
        Start-Sleep -Seconds 1
        # Calculate Hash from the target files and store in baseline.txt

        # Collect all files in the target folder
        $files = Get-ChildItem -Path .\Files -File -Recurse

        # For each file, calculate the hash, and write to baseline.txt
        foreach($file in $files) {
            $hash = Calculate-File-Hash $file.FullName

           # Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                # A new file has been created!
                if (-Not $notifiedFiles.Contains($hash.Path)) {
                    Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
                    $notifiedFiles.Add($hash.Path)
                }
            }

            # Notify if a file has been changed
            elseif ($fileHashDictionary[$hash.Path] -ne $hash.Hash) {
                # File has been compromised!, notify the user
                if (-Not $notifiedFiles.Contains($hash.Path)) {
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                    $notifiedFiles.Add($hash.Path)
                }
            }
        } 

        # Check for deleted baseline files
        foreach ($key in $fileHashDictionary.Keys) {
                $baselineFilesStillExists = Test-Path -Path $key
                if (-Not $baselineFilesStillExists) {
                    # One of the baseline files must have been deleted, notify the user
                    if (-Not $notifiedFiles.Contains($key)) {
                    Write-Host "$($key) has been deleted!" -ForegroundColor Red
                    $notifiedFiles.Add($key)
                }
                }
        }
  }
}
