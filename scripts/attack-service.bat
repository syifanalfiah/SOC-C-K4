@echo off
echo [*] Creating suspicious service...
sc create updater binPath= "C:\Windows\System32\cmd.exe"

echo [*] Querying service...
sc query updater

echo [*] Deleting service...
sc delete updater

echo [DONE] Cek Wazuh Dashboard - filter rule.groups: windows atau rule.id: 7036