param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("add", "delete")]
    [string]$Action
)

$Domain = "unitechonduras.instructure.com"
$Port = 443
$RulePrefix = "Allow HTTPS ($Domain) to"

$Domain2 = "du11hjcvx0uqb.cloudfront.net"
$RulePrefix2 = "Allow HTTPS ($Domain2) to"

# Función para obtener IPs del dominio
function Get-IPs {
    try {
        return [System.Net.Dns]::GetHostAddresses($Domain)
    } catch {
        Write-Error "No se pudo resolver $Domain"
        exit 1
    }
}

# Función para obtener IPs del dominio
function Get-IP2s {
    try {
        return [System.Net.Dns]::GetHostAddresses($Domain2)
    } catch {
        Write-Error "No se pudo resolver $Domain2"
        exit 1
    }
}
# Acción: ADD
if ($Action -eq "add") {
    $ips = Get-IPs
    foreach ($ip in $ips) {
        $ruleName = "$RulePrefix $($ip.IPAddressToString)"
        Write-Output "➕ Agregando regla: $ruleName"
        netsh advfirewall firewall add rule name="$ruleName" dir=out action=allow remoteip=$($ip.IPAddressToString) protocol=TCP remoteport=$Port enable=yes
    }
    $ips = Get-IP2s
    foreach ($ip in $ips) {
        $ruleName = "$RulePrefix2 $($ip.IPAddressToString)"
        Write-Output "➕ Agregando regla: $ruleName"
        netsh advfirewall firewall add rule name="$ruleName" dir=out action=allow remoteip=$($ip.IPAddressToString) protocol=TCP remoteport=$Port enable=yes
    }
    exit 0
}

# Acción: DELETE
elseif ($Action -eq "delete") {
    $ips = Get-IPs
    foreach ($ip in $ips) {
        $ruleName = "$RulePrefix $($ip.IPAddressToString)"
        Write-Output "❌ Eliminando regla: $ruleName"
        netsh advfirewall firewall delete rule name="$ruleName"
    }
    $ips = Get-IP2s
    foreach ($ip in $ips) {
        $ruleName = "$RulePrefix2 $($ip.IPAddressToString)"
        Write-Output "❌ Eliminando regla: $ruleName"
        netsh advfirewall firewall delete rule name="$ruleName"
    }
    exit 0
}
