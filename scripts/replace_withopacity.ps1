# Replace .withOpacity(x) -> .withValues(opacity: x) across .dart files
# Creates a .bak backup for each modified file.

$root = Get-Location
$files = Get-ChildItem -Path $root -Recurse -Include *.dart | Where-Object { -not ($_.FullName -like "*\\.git*") }

foreach ($f in $files) {
    try {
        $text = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
        if ($text -match "\.withOpacity\(") {
            Copy-Item -LiteralPath $f.FullName -Destination "$($f.FullName).bak" -Force -ErrorAction SilentlyContinue
            # Simpler replacement: replace the method name, preserve inner expression
            $new = $text -replace '\\.withOpacity\\(', '.withValues(opacity: '
            Set-Content -LiteralPath $f.FullName -Value $new -Force
            Write-Output "Updated: $($f.FullName)"
        }
    } catch {
        Write-Error "Failed on $($f.FullName): $_"
    }
}
Write-Output "Replacement complete."