param(
    [string]$Title = "Claude Code",
    [string]$Message = "needs your attention"
)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$forms = @()
foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = $Title
    $f.TopMost = $true
    $f.ShowInTaskbar = $false
    $f.StartPosition = "Manual"
    $f.FormBorderStyle = "FixedToolWindow"
    $f.Size = New-Object System.Drawing.Size(340,90)
    $x = $screen.WorkingArea.X + $screen.WorkingArea.Width - 360
    $y = $screen.WorkingArea.Y + $screen.WorkingArea.Height - 110
    $f.Location = New-Object System.Drawing.Point($x, $y)
    $f.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "$Title`n$Message"
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Dock = "Fill"
    $label.TextAlign = "MiddleCenter"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $f.Controls.Add($label)

    $f.Show()
    $forms += $f
}

for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.Application]::DoEvents()
}
foreach ($f in $forms) { $f.Close() }
