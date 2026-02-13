param([string]$path, [int]$minLen = 4)
$bytes = [System.IO.File]::ReadAllBytes($path)
$ascii = [System.Text.Encoding]::ASCII
$unicode = [System.Text.Encoding]::Unicode
$result = @()

# Simple extraction logic (this is slow for large files but works)
# For larger files, we might need a more optimized approach or just read chunks
# Since the file is ~120MB, reading all bytes is fine, but processing might be slow

# We will use a faster approach: Regex on the file content treated as string?
# No, binary data issues.

# Let's use `strings.exe` from Sysinternals if available? Probably not.
# We'll use a .NET approach in PowerShell.

$encoding = [System.Text.Encoding]::ASCII
$stringBuilder = [System.Text.StringBuilder]::new()

for ($i = 0; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -ge 32 -and $b -le 126) {
        [void]$stringBuilder.Append([char]$b)
    }
    else {
        if ($stringBuilder.Length -ge $minLen) {
            $stringBuilder.ToString()
            [void]$stringBuilder.Clear()
        }
        else {
            [void]$stringBuilder.Clear()
        }
    }
}
if ($stringBuilder.Length -ge $minLen) {
    $stringBuilder.ToString()
}
