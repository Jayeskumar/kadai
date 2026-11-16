Kadai Server - on-premise installation for Windows
===================================================

Kadai (கடை) - billing, stock, GST, khata and UPI for your shop - runs on this PC as the
Windows service "Kadai Server". Other PCs, phones and tablets on the shop network use it in
their web browser. No internet connection is needed for daily billing.

Requirements
------------
- Windows 10 or 11 (64-bit), or Windows Server 2016 or newer
- 4 GB RAM (8 GB recommended), 5 GB free disk space
- Administrator rights for installation

Install
-------
1. Double-click KadaiSetup-<version>-x64.exe and follow the wizard (about 5-10 minutes).
   Setup installs PostgreSQL 16 (database), a private Node.js runtime and the Kadai service.
2. Open the "Kadai" shortcut on the desktop (or http://localhost:8080).
3. Complete the setup wizard: shop name, GSTIN and the owner login.
4. Upload your licence file in Settings > System.

Counter PCs, phones and tablets open:  http://<name of this PC>:8080
If they cannot connect, make sure the shop network is "Private" in Windows
(Settings > Network & Internet > your network > Network profile type > Private).

Where things are
----------------
Program files        C:\Program Files\Kadai
Configuration        C:\ProgramData\Kadai\kadai.env   <- COPY THIS FILE TO A USB DRIVE AND KEEP
                                                         IT SAFE: needed to restore on a new PC
Data and backups     C:\ProgramData\Kadai\data  (backups in data\backups)
Logs                 C:\ProgramData\Kadai\logs  (Start menu > Kadai > Kadai logs)

Daily operation (PowerShell as administrator, in C:\Program Files\Kadai\scripts)
-----------------------------------------------------------------------------
Status / restart     Get-Service kadai   /   Restart-Service kadai
Back up now          .\backup.ps1        (or  .\backup.ps1 -Dest E:\KadaiBackups)
Restore              .\restore.ps1 -File C:\ProgramData\Kadai\data\backups\<file>.dump
Undo last upgrade    .\install.ps1 -Rollback

Kadai backs up the database every day by itself. To also copy each backup to a USB drive or a
network share, add the line  KADAI_BACKUP_COPY_TO=E:\KadaiBackups  to kadai.env and restart
the service.

Upgrade
-------
Run the newer KadaiSetup-<version>-x64.exe. It takes a backup, installs the new version,
checks that it starts, and keeps the previous version for rollback. Your data stays in place.

Uninstall
---------
Settings > Apps > Kadai Server > Uninstall. The service, firewall rule and program files are
removed. Your data, backups and the PostgreSQL database are KEPT; running KadaiSetup again
reuses them.

Silent installation (IT staff)
------------------------------
KadaiSetup-<version>-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=C:\kadai-setup.log
  optional:  /PORT=9090   /TASKS="network,backup,desktopicon"   /PGPASSWORD=<existing postgres password>
Exit code 0: installed and healthy. Exit code 7: installation failed (see the Kadai log in
C:\ProgramData\Kadai\logs\install-*.log).
