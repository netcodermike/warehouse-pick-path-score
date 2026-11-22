param([Parameter(Mandatory=$true, Position=0)][string] $InputPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Get-Distance($a, $b) {
    if ($a.Count -ne 2 -or $b.Count -ne 2) { throw 'Each grid point needs two coordinates' }
    [Math]::Abs([long]$a[0] - [long]$b[0]) + [Math]::Abs([long]$a[1] - [long]$b[1])
}

function Invoke-Analysis($data) {
    $points, $routes, $depot = $data['points'], $data['routes'], $data['depot']
    if ($null -eq $points -or $null -eq $routes -or !$points.Count -or !$routes.Count -or $depot.Count -ne 2) { throw 'Enter a depot, pick map and routes' }
    $distances = [ordered]@{}
    foreach ($name in $routes.Keys) {
        $path = $routes[$name]
        if ($path -isnot [array] -or $path.Count -ne $points.Count -or @($path | Sort-Object -CaseSensitive -Unique).Count -ne $points.Count) { throw 'Each route must visit every pick once' }
        $previous = $depot
        $distance = 0L
        foreach ($key in $path) {
            if ($key -cnotin $points.Keys) { throw 'Unknown pick' }
            $distance += Get-Distance $previous $points[$key]
            $previous = $points[$key]
        }
        $distances[$name] = $distance + (Get-Distance $previous $depot)
    }
    $shortest = $distances.Keys | Sort-Object -Property @{ Expression = { $distances[$_] } }, @{ Expression = { $_ } } -CaseSensitive | Select-Object -First 1
    @{ distances = $distances; shortest = $shortest }
}

try {
    $payload = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -AsHashtable
    if ($payload -isnot [System.Collections.IDictionary]) { throw 'Input must be a JSON object' }
    Invoke-Analysis $payload | ConvertTo-Json -Depth 30 -Compress
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
