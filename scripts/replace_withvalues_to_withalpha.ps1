$root = Get-Location
$files = Get-ChildItem -Path $root -Recurse -Include *.dart | Where-Object { -not ($_.FullName -like "*\.git*") }

foreach ($f in $files) {
    try {
        $text = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
        $orig = $text
        # named param: withValues(opacity: expr)
        $text = [regex]::Replace($text, 'withValues\(\s*opacity:\s*([^\)]+)\)', 'withAlpha((($1)*255).round())')
        # positional: withValues(expr)
        $text = [regex]::Replace($text, 'withValues\(\s*([^\)]+)\s*\)', 'withAlpha((($1)*255).round())')
        if ($text -ne $orig) {
            Copy-Item -LiteralPath $f.FullName -Destination "$($f.FullName).bak3" -Force -ErrorAction SilentlyContinue
            Set-Content -LiteralPath $f.FullName -Value $text -Force
            Write-Output "Updated: $($f.FullName)"
        }
    } catch {
        Write-Error "Failed on $($f.FullName): $_"
    }
}
Write-Output "Replacement complete."