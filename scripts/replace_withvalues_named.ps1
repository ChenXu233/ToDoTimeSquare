$root = Get-Location
$files = Get-ChildItem -Path $root -Recurse -Include *.dart | Where-Object { -not ($_.FullName -like "*\.git*") }

foreach ($f in $files) {
    try {
        $text = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
        if ($text -match 'withValues\(opacity:\s*') {
            Copy-Item -LiteralPath $f.FullName -Destination "$($f.FullName).bak2" -Force -ErrorAction SilentlyContinue
            $new = $text -replace 'withValues\(opacity:\s*', 'withValues('
            Set-Content -LiteralPath $f.FullName -Value $new -Force
            Write-Output "Updated: $($f.FullName)"
        }
    } catch {
        Write-Error "Failed on $($f.FullName): $_"
    }
}
Write-Output "Replacement complete."