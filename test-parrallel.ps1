# Adapted from / inspired by LawrenceSystems https://forums.lawrencesystems.com/t/5072
# Bulk DNS Lookup
#
# Generates a CSV of DNS lookups from a list of domains.
#
# Domain lists
# - https://oisd.nl/downloads
# - https://firebog.net/
# File name/path of domain list:

$domain_list ='examples\coinminers.txt' # One FQDN per line in file.
# $domain_list ='examples\simple_malvertising.txt' # One FQDN per line in file.

# IP address of the nameserver used for lookups:
$ns1_ip='1.1.1.1' # Cloudflare
$ns2_ip='9.9.9.9' # Quad9
$ns3_ip='1.1.1.2' # Cloudflare Malware
$ns4_ip='1.1.1.3' # Cloudflare Malware & Porn

# Start looping through domains
# foreach($line in Get-Content .\$domain_list) {
#     $ip1 = Resolve-DnsName -Name $line -Server $ns1_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
#     $ip2 = Resolve-DnsName -Name $line -Server $ns2_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
#     $ip3 = Resolve-DnsName -Name $line -Server $ns3_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
#     $ip4 = Resolve-DnsName -Name $line -Server $ns4_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;

#     "$line;$ip1;$ip2;$ip3;$ip4" | add-content -path $file
# }

#Get the temp path of the context user
$TempPath = "$PSScriptRoot\TempResult";
New-Item -Path $TempPath -ItemType Directory # and create a new sub directory

Get-Content .\$domain_list | ForEach-Object -parallel {
    $ip1 = Resolve-DnsName -Name $_ -Server $ns1_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
    $ip2 = Resolve-DnsName -Name $_ -Server $ns2_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
    $ip3 = Resolve-DnsName -Name $_ -Server $ns3_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;
    $ip4 = Resolve-DnsName -Name $_ -Server $ns4_ip -Type A | Select-Object -ExpandProperty IPAddress -Last 1;

    $TempFileName = [System.Guid]::NewGuid().Guid + ".csv" #GUID.txt will ensure randomness
    $FullTempFilePath = Join-Path -Path "$using:TempPath" -ChildPath $TempFileName
    "$line;$ip1;$ip2;$ip3;$ip4" | Out-File -Path $FullTempFilePath -Force #Write out to the random file
} -ThrottleLimit 5 

# Start CSV
$fileName = 'result.csv';
$file = "$PSScriptRoot\$fileName";

New-Item -Path $PSScriptRoot -Name $fileName -ItemType "file" -Force

"Domain name;$ns1_ip;$ns2_ip;$ns3_ip;$ns4_ip" | add-content -path $file

$TempFiles = Get-ChildItem -Path $TempPath
foreach ($TempFile in $TempFiles) {
    Get-Content -Path $TempFile.FullName | Out-File $file -Append #concatenate all the files
}

Remove-Item -Path $TempPath -Force -Recurse #clean up

# In Excel
# =COUNTV(B3:B5000)-COUNTIF(B3:B5000;"0.0.0.0")