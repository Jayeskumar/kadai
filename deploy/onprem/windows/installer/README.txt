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
1. Double-click KadaiSetup-<version>-x64.exe and choose English or தமிழ்.
2. Follow the wizard (about 5-10 minutes):
     - shop network and daily backup options
     - "Choose the screens you need": tick only the parts of Kadai your shop uses
       (Stock, Purchases, Customers & khata, Accounts, Reports, ...). Billing, products and
       settings are always on. You can change this later in Kadai: Settings > Screens.
     - the network port (8080; Setup warns if another program already uses it)
   Setup installs PostgreSQL 16 (database), a private Node.js runtime and the Kadai service,
   and shows each step while it works.
3. The finish page lists the addresses to open on counter PCs and phones, for example
   http://192.168.1.10:8080. "Open Kadai now" opens Kadai in its own window.
4. Complete the setup wizard: shop name, GSTIN and the owner login.
5. Upload your licence file in Settings > System.

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

Upgrade and repair
------------------
Run the newer KadaiSetup-<version>-x64.exe. It takes a backup, installs the new version,
checks that it starts, and keeps the previous version for rollback. Your data stays in place.
Running the same version again repairs the program files and the service. An older
KadaiSetup refuses to run over a newer installation (downgrades are not supported).

Uninstall
---------
Settings > Apps > Kadai Server > Uninstall. The service, firewall rule and program files are
removed. Your data, backups and the PostgreSQL database are KEPT; running KadaiSetup again
reuses them.

Silent installation (IT staff)
------------------------------
KadaiSetup-<version>-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=C:\kadai-setup.log
  optional:  /PORT=9090   /TASKS="network,backup,desktopicon"   /LANG=tamil
             /MODULES=inventory,customers,reports   (screens to show; "all" = default, "none")
             /PGPASSWORDFILE=C:\pg.txt   (existing PostgreSQL 16: file with its postgres password;
                                         /PGPASSWORD=... also works but appears in the /LOG file)
Module names: inventory, purchases, customers, payments, accounts, reports, estimates,
promotions, labels, notifications.
Exit code 0: installed and healthy. 1: refused (a newer version is installed). 7: installation
failed (see the Kadai log in C:\ProgramData\Kadai\logs\install-*.log).
