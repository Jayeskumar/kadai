; Kadai Server setup - English texts (custom messages + overrides of Inno Setup's Default.isl).
; Saved as UTF-8 with BOM. Keep the keys in sync with Tamil.isl.

[Messages]
WelcomeLabel1=Welcome to Kadai Server
WelcomeLabel2=Billing, stock, GST and UPI for your shop - on this PC.%n%nSetup installs everything Kadai needs: the Kadai Server service, the PostgreSQL 16 database and a private Node.js runtime. Counter PCs, phones and tablets on the shop network then open Kadai in their browser.%n%n•  No internet connection needed%n•  About 5-10 minutes%n•  Your data stays on this PC
FinishedHeadingLabel=Kadai Server is ready
WizardSelectTasks=Shop network and backups
SelectTasksDesc=How should Kadai work on this PC?
SelectTasksLabel2=Choose the options below, then click Next.

[CustomMessages]
GroupNetwork=Shop network
GroupBackup=Backups
GroupShortcuts=Shortcuts
TaskNetwork=Let counter PCs, phones and tablets connect (marks this network as Private)
TaskBackup=Back up the database every day at 22:45
TaskDesktop=Put a "Kadai" shortcut on the desktop

ModulesTitle=Choose the screens you need
ModulesSubtitle=Show only what your shop uses. Change it any time in Kadai: Settings > Screens.
ModulesAlwaysOn=Always on: Billing (POS, bills, returns), Products & prices, Settings
ModulesHint=Hidden screens keep working underneath (bills still update stock); they are only left out of the menu.
ModulesPresetAll=Everything
ModulesPresetSimple=Simple shop
ModulesPresetBilling=Billing only
Module_inventory=Stock
Module_inventory_d=Stock on hand, movements, adjustments, transfers and batches
Module_purchases=Purchases & suppliers
Module_purchases_d=Purchase orders, StockSense reorder planner, purchase bills, suppliers
Module_customers=Customers & khata
Module_customers_d=Customer list, credit (khata) balances and reminders
Module_payments=Payments & UPI
Module_payments_d=Payments received and paid, UPI collections
Module_accounts=Accounts & expenses
Module_accounts_d=Expenses, shifts and cash closing, day book, ledgers, statements
Module_reports=Reports & GST returns
Module_reports_d=Sales, stock and profit reports, GSTR-1 / 3B
Module_estimates=Estimates
Module_estimates_d=Quotations that become bills later
Module_promotions=Offers & schemes
Module_promotions_d=Discounts, buy-x-get-y and combo offers
Module_labels=Barcode labels
Module_labels_d=Design and print barcode / price labels
Module_notifications=WhatsApp & SMS
Module_notifications_d=Bills and reminders by WhatsApp / SMS, message log

PortTitle=Network port
PortSubtitle=Which port should Kadai Server use?
PortText=Counter PCs, phones and tablets open http://<this PC>:<port>. Keep 8080 unless another program on this PC already uses it.
PortLabel=&Port:
PortInvalid=Enter a port number between 1 and 65535.
PortInUse=Port %1 is already used by another program on this PC.%n%nChoose another port (for example 8081).
PgTitle=PostgreSQL
PgSubtitle=PostgreSQL 16 is already installed on this PC
PgText=Kadai creates its own database and roles in it. Enter the password of its "postgres" superuser.
PgLabel=&Password of the "postgres" user:
PgMissing=Enter the password of the PostgreSQL "postgres" user.

ReadyInstall=Install Kadai Server %1 with PostgreSQL 16 and Node.js.
ReadyUpgrade=Upgrade Kadai Server %1 to %2. Your data is backed up first; the previous version is kept for rollback.
ReadyRepair=Repair Kadai Server %1: reinstall the program files and the service. Your data stays as it is.
ReadyReinstall=Reinstall Kadai Server %1 with the configuration and data kept in %2.
ReadyAddress=Address for counter PCs and phones:
ReadyScreens=Screens:
ReadyAllScreens=All screens
ReadyFolders=Program: %1%nData, backups and logs: %2

ProgressTitle=Installing Kadai Server
ProgressSubtitle=Please wait. Setup checks every step and starts Kadai at the end.
ProgressElapsed=Elapsed %1
Step_start=Preparing
Step_checksum=Checking the installation files
Step_unpack=Copying Kadai Server
Step_node=Setting up the Node.js runtime
Step_postgres=Installing the database (PostgreSQL 16) - the longest step, 2-5 minutes
Step_database=Creating the shop database
Step_service=Registering the Kadai Server service
Step_firewall=Opening the shop network
Step_backup=Taking a backup of your data
Step_task=Scheduling daily backups
Step_waiting=Starting Kadai and preparing the database
Step_ready=Kadai is running

FailTitle=Kadai Server could not be installed
FailNext=Fix the problem and run Setup again - it continues where it stopped.
FailLog=Full log: %1
FailOpenLog=Open the log in Notepad?
FailTimeout=The installation did not finish within %1 minutes.
FailStart=Windows PowerShell could not be started: %1
FailTemp=Could not write a temporary file in %1.
FailNeedPg=PostgreSQL 16 is already installed on this PC: its "postgres" password is needed (/PGPASSWORDFILE=<file> or /PGPASSWORD=...).
FailPortParam=Invalid port "%1": pass /PORT=<1-65535>.
Downgrade=Kadai Server %1 is installed on this PC, which is newer than this setup (%2).%n%nDowngrading is not supported: run KadaiSetup %1 or newer.

FinishInstalled=Kadai Server is installed and running as a Windows service.
FinishUpgraded=Kadai Server was upgraded to %1 and is running.
FinishRepaired=Kadai Server was repaired and is running.
FinishThisPc=On this PC: open the "Kadai" shortcut (http://localhost:%1)
FinishOthers=Counter PCs, phones and tablets on the shop network:
FinishFirstRun=First visit: complete the setup wizard (shop name, GSTIN, owner login), then upload the licence in Settings > System.
FinishKeepEnv=Keep a copy of %1 on a USB drive: it is needed to restore Kadai on a new PC.

RunOpen=Open Kadai now
IconLogs=Kadai logs
IconGuide=Kadai guide
IconUninstall=Uninstall Kadai Server
UninstallStatus=Stopping and removing the Kadai Server service...
UninstallKept=Kadai Server was removed.%n%nYour shop data, backups and the PostgreSQL database are kept in %1 and PostgreSQL 16. Running KadaiSetup again reuses them.
