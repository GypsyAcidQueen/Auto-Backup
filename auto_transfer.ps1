# Function to eject the card
function Eject-SDCard {
    param([string]$driveLetter)
    $eject = New-Object -comObject Shell.Application
    $eject.NameSpace(17).ParseName($driveLetter + ":").InvokeVerb('Eject')
}

$waitingForCard = $true

# Main loop
while ($true) {
    # Check if the drive is available
    if (Test-Path 'K:\') {
        Write-Host "Detected card."
        $waitingForCard = $true # Reset flag after detection for next cycle
        
        # Stage 1: Generate a folder with the current date and time
        $destinationPath = "I:\SD_Card_Backup\" + (Get-Date -Format "dd-MM-yyyy-HH-mm-ss")
        New-Item -ItemType Directory -Path $destinationPath

        # Stage 2: Use robocopy to copy all .mov and .mp4 files
        $sourcePath = "K:\PRIVATE\M4ROOT\CLIP"
        robocopy $sourcePath $destinationPath *.mov *.mp4 /E

        # Stage 3: Use PowerShell hashing to verify all the copied files
        Get-ChildItem -Path $destinationPath -Recurse | Where-Object { $_.Extension -match "mov|mp4" } | ForEach-Object {
            $sourceFile = $_.FullName.Replace($destinationPath, $sourcePath)
            $sourceHash = (Get-FileHash $sourceFile).Hash
            $destinationHash = (Get-FileHash $_.FullName).Hash

            if ($sourceHash -eq $destinationHash) {
                Write-Host "Verification successful for file: $($_.Name)"
            } else {
                Write-Host "Verification failed for file: $($_.Name)"
            }
        }

        # Stage 4: Eject the card
        Eject-SDCard -driveLetter "K"

        # Notification sound when the process is completed
        [System.Media.SystemSounds]::Beep.Play()
        
        Write-Host "Operation completed. Waiting for next card."
        # Wait a bit after ejecting before next check to prevent immediate re-detection
        Start-Sleep -Seconds 10
    } else {
        # Only print waiting for card if not already waiting
        if ($waitingForCard) {
            Write-Host "Waiting for card..."
            $waitingForCard = $false # Prevent message from repeating
        }
        # Wait for 10 seconds before checking again
        Start-Sleep -Seconds 10
    }
}
