# Claude Code Status Line — PowerShell version (Windows)
# https://github.com/Bonny07/pawline
#
# Usage: Add to settings.json (usually at %USERPROFILE%\.claude\settings.json):
#   "statusLine": {
#     "type": "command",
#     "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\statusline.ps1\""
#   }

$input = $Input | Out-String
$data = $input | ConvertFrom-Json

# --- Colors (ANSI escape sequences — works in Windows Terminal / modern terminals) ---
$e = [char]0x1b
$C_BLUE   = "$e[38;2;0;153;255m"
$C_CYAN   = "$e[38;2;86;182;194m"
$C_GREEN  = "$e[38;2;0;175;80m"
$C_ORANGE = "$e[38;2;255;176;85m"
$C_YELLOW = "$e[38;2;230;200;0m"
$C_RED    = "$e[38;2;255;85;85m"
$C_WHITE  = "$e[38;2;220;220;220m"
$C_DIM    = "$e[2m"
$C_R      = "$e[0m"
$SEP      = " ${C_DIM}|${C_R} "

# --- Parse ---
$model = if ($data.model.display_name) {
    $data.model.display_name -replace '\s*\(.*context\)', ''
} else { "Unknown" }

$used_pct = if ($data.context_window.used_percentage) { $data.context_window.used_percentage } else { 0 }
$used_int = [math]::Round($used_pct)
$total_in = if ($data.context_window.total_input_tokens) { $data.context_window.total_input_tokens } else { 0 }
$total_out = if ($data.context_window.total_output_tokens) { $data.context_window.total_output_tokens } else { 0 }
$cost_usd = if ($data.cost.total_cost_usd) { $data.cost.total_cost_usd } else { 0 }
$dur_ms = if ($data.cost.total_duration_ms) { $data.cost.total_duration_ms } else { 0 }
$lines_add = if ($data.cost.total_lines_added) { $data.cost.total_lines_added } else { 0 }
$lines_rm = if ($data.cost.total_lines_removed) { $data.cost.total_lines_removed } else { 0 }
$five_pct = $data.rate_limits.five_hour.used_percentage

# --- Project name detection ---
$cwd = (Get-Location).Path
$proj = ""
$projectDirs = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Projects",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Developer"
)
foreach ($dir in $projectDirs) {
    if ($cwd.StartsWith("$dir\")) {
        $proj = ($cwd.Substring($dir.Length + 1) -split '\\')[0]
        break
    }
}

# --- Token formatting ---
function Format-Token($n) {
    if ($n -ge 1000000) { return "{0:F1}M" -f ($n / 1000000) }
    elseif ($n -ge 1000) { return "{0:F0}K" -f ($n / 1000) }
    else { return "$n" }
}
$in_str = Format-Token $total_in
$out_str = Format-Token $total_out

# --- Cost ---
if ($cost_usd -ge 1) { $cost_str = "`${0:F2}" -f $cost_usd }
elseif ($cost_usd -ge 0.01) { $cost_str = "`${0:F2}" -f $cost_usd }
else { $cost_str = "`${0:F3}" -f $cost_usd }
$cost_str = "$" + ("{0}" -f [math]::Round($cost_usd, $(if ($cost_usd -ge 0.01) { 2 } else { 3 })))

# --- Duration ---
$dur_min = [math]::Floor($dur_ms / 60000)
$dur_sec = [math]::Floor(($dur_ms % 60000) / 1000)
if ($dur_min -ge 60) {
    $dur_hr = [math]::Floor($dur_min / 60)
    $dur_rm = $dur_min % 60
    $dur_str = "${dur_hr}h${dur_rm}m"
} elseif ($dur_min -gt 0) {
    $dur_str = "${dur_min}m"
} else {
    $dur_str = "${dur_sec}s"
}

# --- Effort level ---
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$effort = "default"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
    if ($settings.effortLevel) { $effort = $settings.effortLevel }
}
switch ($effort) {
    "max"     { $effort_color = $C_RED;    $effort_label = "MAX" }
    "high"    { $effort_color = $C_ORANGE; $effort_label = "HIGH" }
    "medium"  { $effort_color = $C_YELLOW; $effort_label = "MED" }
    "default" { $effort_color = $C_YELLOW; $effort_label = "MED" }
    "low"     { $effort_color = $C_GREEN;  $effort_label = "LOW" }
    default   { $effort_color = $C_DIM;    $effort_label = $effort }
}
$effort_str = "${effort_color}${effort_label}${C_R}"

# --- Context usage bar ---
$pct_color = $C_GREEN
if ($used_int -ge 50) { $pct_color = $C_ORANGE }
if ($used_int -ge 70) { $pct_color = $C_YELLOW }
if ($used_int -ge 90) { $pct_color = $C_RED }

$bar_filled = [math]::Floor($used_int / 10)
$bar_empty = 10 - $bar_filled
$bar = ("$([char]0x25CF)" * $bar_filled) + ("${C_DIM}$([char]0x25CB)${C_R}${pct_color}" * $bar_empty)
$ctx_str = "${pct_color}${bar} ${used_int}%${C_R}"

# --- Rate limit ---
$rl_str = ""
if ($null -ne $five_pct) {
    $five_int = [math]::Round($five_pct)
    $rl_color = $C_GREEN
    if ($five_int -ge 50) { $rl_color = $C_ORANGE }
    if ($five_int -ge 70) { $rl_color = $C_YELLOW }
    if ($five_int -ge 90) { $rl_color = $C_RED }
    $rl_str = "${SEP}${rl_color}5h ${five_int}%${C_R}"
}

# --- Assemble ---
$out = ""

if ($proj) { $out += "${C_CYAN}${proj}${C_R}${SEP}" }

$out += "${C_BLUE}${model}${C_R}${SEP}${effort_str}"
$out += "${SEP}${ctx_str}"
$out += "${SEP}${C_DIM}in${C_R}${C_WHITE}${in_str}${C_R} ${C_DIM}out${C_R}${C_WHITE}${out_str}${C_R}"

if ($lines_add -gt 0 -or $lines_rm -gt 0) {
    $out += "${SEP}${C_GREEN}+${lines_add}${C_R} ${C_RED}-${lines_rm}${C_R}"
}

$out += "${SEP}${C_DIM}`u{23F1}${C_R} ${C_WHITE}${dur_str}${C_R}"
$out += "${SEP}${C_WHITE}${cost_str}${C_R}"
$out += $rl_str

# Paw!
$out += " `u{1F43E}"

Write-Host $out -NoNewline
