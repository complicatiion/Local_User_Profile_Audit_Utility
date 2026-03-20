@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Local User Profile Audit Utility

color 06
chcp 65001 >nul

:: Check for administrator rights
net session >nul 2>&1
if %errorlevel%==0 (
  set "ISADMIN=1"
) else (
  set "ISADMIN=0"
)

:: Report folder on desktop
set "REPORTROOT=%USERPROFILE%\Desktop\UserReports"
if not exist "%REPORTROOT%" md "%REPORTROOT%" >nul 2>&1

set "AGEDAYS=60"

:MAIN
cls
echo ============================================================
echo User Account and Profile Audit by complicatiion
echo ============================================================
echo.
if "%ISADMIN%"=="1" (
  echo Admin status: YES
) else (
  echo Admin status: NO
)
echo Report folder: %REPORTROOT%
echo Whitelist pattern: *ADMP*  /  *Admin*
echo Old domain profiles: older than %AGEDAYS% days
echo.
echo [1] List user accounts and profiles
echo [2] Profiles with details and last usage sorting
echo [3] Check profile sizes
echo [4] Generate report
echo [5] Delete profile (clean)                          [Admin]
echo [6] Delete local user account                  [Admin]
echo [7] Delete profile and local account               [Admin]
echo [8] Delete all domain profiles (clean)            [Admin]
echo [9] Delete old domain profiles only               [Admin]
echo [A] Show old domain profiles with whitelist
echo [B] Report folder oeffnen
echo [0] Exit
echo.
set /p CHO="Selection: "

if "%CHO%"=="1" goto :LIST
if "%CHO%"=="2" goto :DETAILS
if "%CHO%"=="3" goto :SIZES
if "%CHO%"=="4" goto :REPORT
if "%CHO%"=="5" goto :DELPROFILE
if "%CHO%"=="6" goto :DELUSER
if "%CHO%"=="7" goto :DELBOTH
if "%CHO%"=="8" goto :DELDOMAINPROFILES
if "%CHO%"=="9" goto :DELOLDOMAINPROFILES
if /I "%CHO%"=="A" goto :SHOWOLD
if /I "%CHO%"=="B" goto :OPENFOLDER
if "%CHO%"=="0" goto :END
goto :MAIN

:LIST
cls
echo ============================================================
echo User accounts and profiles
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false } | ForEach-Object { $name = Split-Path $_.LocalPath -Leaf; $last = if($_.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($_.LastUseTime) } else { $null }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($_.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $type = if($isLocal){ 'Local' } else { 'Domain/External' }; $wl = if($name -match 'ADMP|Admin'){ 'Yes' } else { 'No' }; [pscustomobject]@{ User=$name; Typ=$type; Whitelist=$wl; LastUse=$last; Loaded=$_.Loaded; Status=$_.Status; Path=$_.LocalPath } }; $profiles | Sort-Object LastUse | Format-Table -AutoSize"
echo.
pause
goto :MAIN

:DETAILS
cls
echo ============================================================
echo Profile details
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false } | ForEach-Object { $name = Split-Path $_.LocalPath -Leaf; $last = if($_.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($_.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { $null }; $state = if($days -ge 180){ 'Old' } elseif($days -ge %AGEDAYS%){ 'Aging' } else { 'Active' }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($_.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $type = if($isLocal){ 'Local' } else { 'Domain/External' }; $wl = if($name -match 'ADMP|Admin'){ 'Yes' } else { 'No' }; [pscustomobject]@{ User=$name; Typ=$type; Whitelist=$wl; LastUse=$last; DaysInactive=$days; State=$state; Loaded=$_.Loaded; Path=$_.LocalPath } }; $profiles | Sort-Object LastUse | Format-Table -AutoSize"
echo.
pause
goto :MAIN

:SIZES
cls
echo ============================================================
echo Profile sizes
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $result = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $type = if($isLocal){ 'Local' } else { 'Domain/External' }; $wl = if($name -match 'ADMP|Admin'){ 'Yes' } else { 'No' }; $size = 0; if(Test-Path $p.LocalPath){ try { $size = (Get-ChildItem $p.LocalPath -Force -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {} }; [pscustomobject]@{ User=$name; Typ=$type; Whitelist=$wl; LastUse=$last; SizeGB=[math]::Round(($size / 1GB),2); Path=$p.LocalPath } }; $result | Sort-Object LastUse | Format-Table -AutoSize"
echo.
echo Note: Size calculation may take time depending on profile size.
echo.
pause
goto :MAIN

:REPORT
cls
echo [*] Creating report...
echo.
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set STAMP=%%I
set "OUTFILE=%REPORTROOT%\User_Profile_Report_%STAMP%.txt"

(
echo ============================================================
echo Userkonto- und Profilreport
echo ============================================================
echo Date: %DATE% %TIME%
echo Computer: %COMPUTERNAME%
echo User: %USERNAME%
echo Threshold for old domain profiles: %AGEDAYS% days
echo Whitelist-Muster: ADMP / Admin
echo ============================================================
echo.

echo [1] Locale Userkonten
net user
echo.

echo [2] Userprofile sortiert nach letzter Nutzung
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false } | ForEach-Object { $name = Split-Path $_.LocalPath -Leaf; $last = if($_.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($_.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { $null }; $state = if($days -ge 180){ 'Old' } elseif($days -ge %AGEDAYS%){ 'Aging' } else { 'Active' }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($_.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $type = if($isLocal){ 'Local' } else { 'Domain/External' }; $wl = if($name -match 'ADMP|Admin'){ 'Yes' } else { 'No' }; [pscustomobject]@{ User=$name; Typ=$type; Whitelist=$wl; LastUse=$last; DaysInactive=$days; State=$state; Loaded=$_.Loaded; Status=$_.Status; Path=$_.LocalPath } }; $profiles | Sort-Object LastUse | Format-Table -AutoSize"
echo.

echo [3] Profile sizes
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $result = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $type = if($isLocal){ 'Local' } else { 'Domain/External' }; $wl = if($name -match 'ADMP|Admin'){ 'Yes' } else { 'No' }; $size = 0; if(Test-Path $p.LocalPath){ try { $size = (Get-ChildItem $p.LocalPath -Force -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {} }; [pscustomobject]@{ User=$name; Typ=$type; Whitelist=$wl; LastUse=$last; SizeGB=[math]::Round(($size / 1GB),2); Path=$p.LocalPath } }; $result | Sort-Object LastUse | Format-Table -AutoSize"
echo.

echo [4] Locale Konten mit Details
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, PasswordExpires, UserMayChangePassword | Sort-Object LastLogon | Format-Table -AutoSize } catch { 'Get-LocalUser not available on this system.' }"
echo.

echo [5] Olde Domaenenprofile ohne Whitelist
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $result = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { 99999 }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $isWhite = ($name -match 'ADMP|Admin'); if((-not $isLocal) -and (-not $isWhite) -and ($days -ge %AGEDAYS%)){ [pscustomobject]@{ User=$name; DaysInactive=$days; Loaded=$p.Loaded; Path=$p.LocalPath } } }; if($result){ $result | Sort-Object DaysInactive -Descending | Format-Table -AutoSize } else { 'No old domain profiles without whitelist found.' }"
echo.

echo [6] Summary
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $items = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { 99999 }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $isWhite = ($name -match 'ADMP|Admin'); [pscustomobject]@{ User=$name; Tage=$days; Loaded=$p.Loaded; Local=$isLocal; White=$isWhite } }; 'Profiles total: ' + $items.Count; 'Locale Profile: ' + (($items | Where-Object { $_.Local -eq $true }).Count); 'Domain/External profiles: ' + (($items | Where-Object { $_.Local -eq $false }).Count); 'Whitelisted profiles: ' + (($items | Where-Object { $_.White -eq $true }).Count); 'Profiles older than %AGEDAYS% days: ' + (($items | Where-Object { $_.Tage -ge %AGEDAYS% }).Count); 'Olde Domaenenprofile ohne Whitelist: ' + (($items | Where-Object { $_.Local -eq $false -and $_.White -eq $false -and $_.Tage -ge %AGEDAYS% }).Count); 'Loadede Profile: ' + (($items | Where-Object { $_.Loaded -eq $true }).Count)"
echo.
) > "%OUTFILE%" 2>&1

echo Report created:
echo %OUTFILE%
echo.
pause
goto :MAIN

:SHOWOLD
cls
echo ============================================================
echo Olde Domaenenprofile mit Whitelist
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $result = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { 99999 }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $isWhite = ($name -match 'ADMP|Admin'); if((-not $isLocal) -and ($days -ge %AGEDAYS%)){ [pscustomobject]@{ User=$name; Whitelist=$(if($isWhite){'Yes'}else{'No'}); DaysInactive=$days; Loaded=$p.Loaded; Path=$p.LocalPath } } }; if($result){ $result | Sort-Object DaysInactive -Descending | Format-Table -AutoSize } else { 'No old domain profiles found.' }"
echo.
pause
goto :MAIN

:DELPROFILE
if not "%ISADMIN%"=="1" goto :NEEDADMIN
cls
echo ============================================================
echo Delete profile (clean)
echo ============================================================
echo.
set /p DELNAME="Usernamen fuer Profil-Loeschung eingeben: "
if "%DELNAME%"=="" goto :MAIN
echo.
echo Target profile: %DELNAME%
echo This profile will be removed via Win32_UserProfile.
set /p CONFIRM="Type YES to confirm: "
if /I not "%CONFIRM%"=="JA" goto :MAIN
powershell -NoProfile -ExecutionPolicy Bypass -Command "$name='%DELNAME%'; $profile = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -eq ('C:\Users\' + $name) -and $_.Special -eq $false }; if(-not $profile){ Write-Host 'Profile not found.'; exit 1 }; if($profile.Loaded){ Write-Host 'Profile is currently loaded and cannot be deleted.'; exit 2 }; Invoke-CimMethod -InputObject $profile -MethodName Delete | Out-Null; Write-Host 'Profile was deleted.'"
echo.
pause
goto :MAIN

:DELUSER
if not "%ISADMIN%"=="1" goto :NEEDADMIN
cls
echo ============================================================
echo Delete local user account
echo ============================================================
echo.
set /p DELUSERNAME="Localen Usernamen eingeben: "
if "%DELUSERNAME%"=="" goto :MAIN
echo.
echo Target account: %DELUSERNAME%
echo This local account will be deleted.
set /p CONFIRM="Type YES to confirm: "
if /I not "%CONFIRM%"=="JA" goto :MAIN
net user "%DELUSERNAME%" /delete
echo.
pause
goto :MAIN

:DELBOTH
if not "%ISADMIN%"=="1" goto :NEEDADMIN
cls
echo ============================================================
echo Delete profile and local account
echo ============================================================
echo.
set /p DELBOTHNAME="Usernamen eingeben: "
if "%DELBOTHNAME%"=="" goto :MAIN
echo.
echo Target: %DELBOTHNAME%
echo The profile will be deleted first, then the local account.
set /p CONFIRM="Type YES to confirm: "
if /I not "%CONFIRM%"=="JA" goto :MAIN
powershell -NoProfile -ExecutionPolicy Bypass -Command "$name='%DELBOTHNAME%'; $profile = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -eq ('C:\Users\' + $name) -and $_.Special -eq $false }; if($profile){ if($profile.Loaded){ Write-Host 'Profile is currently loaded and cannot be deleted.'; exit 2 } else { Invoke-CimMethod -InputObject $profile -MethodName Delete | Out-Null; Write-Host 'Profile was deleted.' } } else { Write-Host 'Profile not found or already removed.' }"
net user "%DELBOTHNAME%" /delete
echo.
pause
goto :MAIN

:DELDOMAINPROFILES
if not "%ISADMIN%"=="1" goto :NEEDADMIN
cls
echo ============================================================
echo Delete all domain profiles (clean)
echo ============================================================
echo.
echo Es werden nur Domain/External profiles entfernt.
echo Locale Profile auf diesem PC bleiben erhalten.
echo Loadede Profile werden automatisch uebersprungen.
echo Whitelist is not considered in this option.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $domainProfiles = foreach($p in $profiles){ $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; if(-not $isLocal){ [pscustomobject]@{ User=(Split-Path $p.LocalPath -Leaf); SID=$p.SID; Loaded=$p.Loaded; Path=$p.LocalPath } } }; if(-not $domainProfiles){ Write-Host 'No domain/external profiles found.'; exit 0 }; Write-Host 'Gefundene Domain/External profiles:'; $domainProfiles | Sort-Object User | Format-Table -AutoSize"
echo.
set /p CONFIRM="Type YES to delete all non-loaded domain profiles: "
if /I not "%CONFIRM%"=="JA" goto :MAIN
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $deleted = 0; $skipped = 0; $failed = 0; foreach($p in $profiles){ $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; if(-not $isLocal){ if($p.Loaded){ Write-Host ('Skipped, profile loaded: ' + $p.LocalPath); $skipped++ } else { try { Invoke-CimMethod -InputObject $p -MethodName Delete | Out-Null; Write-Host ('Deleted: ' + $p.LocalPath); $deleted++ } catch { Write-Host ('Error on: ' + $p.LocalPath); $failed++ } } } }; Write-Host ''; Write-Host ('Deleted: ' + $deleted); Write-Host ('Skipped: ' + $skipped); Write-Host ('Errors: ' + $failed)"
echo.
pause
goto :MAIN

:DELOLDOMAINPROFILES
if not "%ISADMIN%"=="1" goto :NEEDADMIN
cls
echo ============================================================
echo Delete old domain profiles only
echo ============================================================
echo.
echo Es werden nur Domain/External profiles geprueft.
echo Locale Profile bleiben erhalten.
echo Nur Profiles older than %AGEDAYS% days werden geloescht.
echo Profiles with ADMP or Admin in the name are whitelisted.
echo Loadede Profile werden automatisch uebersprungen.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $result = foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { 99999 }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $isWhite = ($name -match 'ADMP|Admin'); if((-not $isLocal) -and ($days -ge %AGEDAYS%)){ [pscustomobject]@{ User=$name; Whitelist=$(if($isWhite){'Yes'}else{'No'}); DaysInactive=$days; Loaded=$p.Loaded; Path=$p.LocalPath } } }; if($result){ Write-Host 'Found old domain profiles:'; $result | Sort-Object DaysInactive -Descending | Format-Table -AutoSize } else { Write-Host 'No old domain profiles found.' }"
echo.
set /p CONFIRM="Type YES to delete all old domain profiles without whitelist: "
if /I not "%CONFIRM%"=="JA" goto :MAIN
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like 'C:\Users\*' -and $_.Special -eq $false }; $deleted = 0; $skippedLoaded = 0; $skippedWhitelist = 0; $skippedYoung = 0; $failed = 0; foreach($p in $profiles){ $name = Split-Path $p.LocalPath -Leaf; $last = if($p.LastUseTime){ [Management.ManagementDateTimeConverter]::ToDateTime($p.LastUseTime) } else { $null }; $days = if($last){ [int]((Get-Date) - $last).TotalDays } else { 99999 }; $sidObj = New-Object System.Security.Principal.SecurityIdentifier($p.SID); $acct = try { $sidObj.Translate([System.Security.Principal.NTAccount]).Value } catch { $null }; $isLocal = $false; if($acct){ $prefix = ($acct -split '\\')[0]; if($prefix -eq $env:COMPUTERNAME){ $isLocal = $true } }; $isWhite = ($name -match 'ADMP|Admin'); if($isLocal){ continue }; if($days -lt %AGEDAYS%){ $skippedYoung++; continue }; if($isWhite){ Write-Host ('Skipped, whitelist: ' + $p.LocalPath); $skippedWhitelist++; continue }; if($p.Loaded){ Write-Host ('Skipped, profile loaded: ' + $p.LocalPath); $skippedLoaded++; continue }; try { Invoke-CimMethod -InputObject $p -MethodName Delete | Out-Null; Write-Host ('Deleted: ' + $p.LocalPath); $deleted++ } catch { Write-Host ('Error on: ' + $p.LocalPath); $failed++ } }; Write-Host ''; Write-Host ('Deleted: ' + $deleted); Write-Host ('Skipped young: ' + $skippedYoung); Write-Host ('Skipped whitelist: ' + $skippedWhitelist); Write-Host ('Skipped loaded: ' + $skippedLoaded); Write-Host ('Errors: ' + $failed)"
echo.
pause
goto :MAIN

:OPENFOLDER
start "" explorer.exe "%REPORTROOT%"
goto :MAIN

:NEEDADMIN
cls
echo Administrator rights are required for this action.
echo.
pause
goto :MAIN

:END
endlocal
exit /b
