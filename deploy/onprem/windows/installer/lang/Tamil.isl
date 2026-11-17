; Kadai Server setup - தமிழ் (Tamil). Overrides only some of Inno Setup's Default.isl messages
; (the rest stay English) and every custom message. Saved as UTF-8 with BOM; keys as English.isl.

[LangOptions]
LanguageName=தமிழ்
LanguageID=$0449
LanguageCodePage=0
DialogFontName=Nirmala UI
WelcomeFontName=Nirmala UI

[Messages]
SetupAppTitle=நிறுவல்
SetupWindowTitle=நிறுவல் - %1
UninstallAppTitle=நீக்குதல்
UninstallAppFullTitle=%1 நீக்குதல்
ButtonBack=< &பின்
ButtonNext=&அடுத்து >
ButtonInstall=&நிறுவு
ButtonOK=சரி
ButtonCancel=ரத்து
ButtonYes=&ஆம்
ButtonNo=&இல்லை
ButtonFinish=&முடி
ClickNext=தொடர அடுத்து என்பதை அழுத்துங்கள், வெளியேற ரத்து என்பதை அழுத்துங்கள்.
SelectLanguageTitle=நிறுவல் மொழி
SelectLanguageLabel=நிறுவலின் போது பயன்படுத்த வேண்டிய மொழியைத் தேர்ந்தெடுங்கள்.
WelcomeLabel1=Kadai Server-க்கு வரவேற்கிறோம்
WelcomeLabel2=உங்கள் கடைக்கான பில்லிங், சரக்கு, GST, UPI - இந்த கணினியிலேயே.%n%nKadai-க்குத் தேவையான அனைத்தையும் நிறுவல் நிறுவும்: Kadai Server சேவை, PostgreSQL 16 தரவுத்தளம், Node.js. அதன் பிறகு கடை நெட்வொர்க்கில் உள்ள கவுண்டர் கணினிகள், போன்கள், டேப்லெட்டுகள் பிரவுசரில் Kadai-ஐத் திறக்கலாம்.%n%n•  இணைய இணைப்பு தேவையில்லை%n•  சுமார் 5-10 நிமிடங்கள்%n•  உங்கள் தரவு இந்த கணினியிலேயே இருக்கும்
WizardSelectTasks=கடை நெட்வொர்க் & காப்புப்பிரதி
SelectTasksDesc=இந்த கணினியில் Kadai எப்படி வேலை செய்ய வேண்டும்?
SelectTasksLabel2=கீழே உள்ள விருப்பங்களைத் தேர்ந்தெடுத்து, அடுத்து என்பதை அழுத்துங்கள்.
WizardReady=நிறுவத் தயார்
ReadyLabel1=இந்த கணினியில் [name] நிறுவத் தயாராக உள்ளது.
ReadyLabel2a=நிறுவலைத் தொடங்க நிறுவு என்பதை அழுத்துங்கள், மாற்ற வேண்டுமெனில் பின் என்பதை அழுத்துங்கள்.
ReadyLabel2b=நிறுவலைத் தொடங்க நிறுவு என்பதை அழுத்துங்கள்.
WizardPreparing=நிறுவத் தயாராகிறது
PreparingDesc=இந்த கணினியில் [name] நிறுவத் தயாராகிறது.
WizardInstalling=நிறுவுகிறது
InstallingLabel=இந்த கணினியில் [name] நிறுவப்படும் வரை காத்திருங்கள்.
FinishedHeadingLabel=Kadai Server தயார்
FinishedLabelNoIcons=இந்த கணினியில் [name] நிறுவல் முடிந்தது.
FinishedLabel=இந்த கணினியில் [name] நிறுவல் முடிந்தது.
ClickFinish=நிறுவலை முடிக்க முடி என்பதை அழுத்துங்கள்.
ExitSetupTitle=நிறுவலிலிருந்து வெளியேறு
ExitSetupMessage=நிறுவல் இன்னும் முடியவில்லை. இப்போது வெளியேறினால் நிரல் நிறுவப்படாது.%n%nபின்னர் மீண்டும் நிறுவலை இயக்கி முடிக்கலாம்.%n%nவெளியேறவா?
WizardUninstalling=நீக்குதல் நிலை
UninstallStatusLabel=உங்கள் கணினியிலிருந்து %1 நீக்கப்படும் வரை காத்திருங்கள்.
ConfirmUninstall=%1 மற்றும் அதன் அனைத்து பகுதிகளையும் நீக்க வேண்டுமா?
ReadyMemoTasks=கூடுதல் பணிகள்:
UninstalledAll=உங்கள் கணினியிலிருந்து %1 வெற்றிகரமாக நீக்கப்பட்டது.

[CustomMessages]
GroupNetwork=கடை நெட்வொர்க்
GroupBackup=காப்புப்பிரதி
GroupShortcuts=குறுக்குவழிகள்
TaskNetwork=கவுண்டர் கணினிகள், போன்கள் இணைய அனுமதி (நெட்வொர்க் Private ஆகும்)
TaskBackup=ஒவ்வொரு நாளும் இரவு 22:45-க்கு தரவுத்தளத்தைக் காப்புப்பிரதி எடு
TaskDesktop=டெஸ்க்டாப்பில் "Kadai" குறுக்குவழி வை

ModulesTitle=உங்களுக்குத் தேவையான திரைகளைத் தேர்ந்தெடுங்கள்
ModulesSubtitle=கடைக்குத் தேவையானதை மட்டும் காட்டுங்கள். பின்னர் அமைப்புகள் > திரைகள் பகுதியில் மாற்றலாம்.
ModulesAlwaysOn=எப்போதும் இயக்கத்தில்: பில்லிங் (POS, பில்கள், திருப்பங்கள்), பொருட்கள் & விலைகள், அமைப்புகள்
ModulesHint=மறைத்த திரைகள் உள்ளே தொடர்ந்து வேலை செய்யும் (பில்கள் சரக்கைப் புதுப்பிக்கும்); மெனுவில் மட்டும் தெரியாது.
ModulesPresetAll=அனைத்தும்
ModulesPresetSimple=எளிய கடை
ModulesPresetBilling=பில்லிங் மட்டும்
Module_inventory=சரக்கு
Module_inventory_d=கையிருப்பு, சரக்கு நகர்வு, சரிசெய்தல், மாற்றம், பேட்ச்கள்
Module_purchases=கொள்முதல் & சப்ளையர்கள்
Module_purchases_d=கொள்முதல் ஆர்டர்கள், StockSense, கொள்முதல் பில்கள், சப்ளையர்கள்
Module_customers=வாடிக்கையாளர்கள் & கடன் கணக்கு
Module_customers_d=வாடிக்கையாளர் பட்டியல், கடன் இருப்பு, நினைவூட்டல்கள்
Module_payments=பணம் & UPI
Module_payments_d=பெற்ற / செலுத்திய பணம், UPI வசூல்
Module_accounts=கணக்குகள் & செலவுகள்
Module_accounts_d=செலவுகள், ஷிஃப்ட், நாள் புத்தகம், லெட்ஜர்கள், அறிக்கைகள்
Module_reports=அறிக்கைகள் & GST ரிட்டர்ன்கள்
Module_reports_d=விற்பனை, சரக்கு, லாப அறிக்கைகள், GSTR-1 / 3B
Module_estimates=மதிப்பீடுகள்
Module_estimates_d=பின்னர் பில்லாக மாறும் விலைப்புள்ளிகள்
Module_promotions=சலுகைகள் & திட்டங்கள்
Module_promotions_d=தள்ளுபடி, ஒன்று வாங்கினால் ஒன்று, காம்போ சலுகைகள்
Module_labels=பார்கோடு லேபிள்கள்
Module_labels_d=பார்கோடு / விலை லேபிள்கள் அச்சிடுதல்
Module_notifications=வாட்ஸ்அப் & SMS
Module_notifications_d=வாட்ஸ்அப் / SMS மூலம் பில்கள், நினைவூட்டல்கள்

PortTitle=நெட்வொர்க் போர்ட்
PortSubtitle=Kadai Server எந்தப் போர்ட்டைப் பயன்படுத்த வேண்டும்?
PortText=கவுண்டர் கணினிகள், போன்கள், டேப்லெட்டுகள் http://<இந்த கணினி>:<போர்ட்> என்பதைத் திறக்கும். இந்த கணினியில் வேறு நிரல் 8080-ஐப் பயன்படுத்தாவிட்டால் அதையே வைத்திருங்கள்.
PortLabel=&போர்ட்:
PortInvalid=1 முதல் 65535 வரையிலான போர்ட் எண்ணை உள்ளிடுங்கள்.
PortInUse=போர்ட் %1-ஐ இந்த கணினியில் வேறு ஒரு நிரல் ஏற்கனவே பயன்படுத்துகிறது.%n%nவேறு போர்ட்டைத் தேர்ந்தெடுங்கள் (எ.கா. 8081).
PgTitle=PostgreSQL
PgSubtitle=இந்த கணினியில் PostgreSQL 16 ஏற்கனவே நிறுவப்பட்டுள்ளது
PgText=Kadai அதில் தனக்கான தரவுத்தளத்தையும் பங்குகளையும் உருவாக்கும். அதன் "postgres" பயனரின் கடவுச்சொல்லை உள்ளிடுங்கள்.
PgLabel=&"postgres" பயனரின் கடவுச்சொல்:
PgMissing=PostgreSQL "postgres" பயனரின் கடவுச்சொல்லை உள்ளிடுங்கள்.

ReadyInstall=Kadai Server %1, PostgreSQL 16, Node.js ஆகியவற்றை நிறுவு.
ReadyUpgrade=Kadai Server %1-இலிருந்து %2-க்கு மேம்படுத்து. முதலில் உங்கள் தரவு காப்புப்பிரதி எடுக்கப்படும்; பழைய பதிப்பு திரும்பப் பெற வைக்கப்படும்.
ReadyRepair=Kadai Server %1-ஐச் சரிசெய்: நிரல் கோப்புகளையும் சேவையையும் மீண்டும் நிறுவு. உங்கள் தரவு மாறாது.
ReadyReinstall=%2-இல் வைக்கப்பட்ட அமைப்பு மற்றும் தரவுடன் Kadai Server %1-ஐ மீண்டும் நிறுவு.
ReadyAddress=கவுண்டர் கணினிகள், போன்களுக்கான முகவரி:
ReadyScreens=திரைகள்:
ReadyAllScreens=அனைத்து திரைகளும்
ReadyFolders=நிரல்: %1%nதரவு, காப்புப்பிரதி, பதிவுகள்: %2

ProgressTitle=Kadai Server நிறுவப்படுகிறது
ProgressSubtitle=காத்திருங்கள். ஒவ்வொரு படியும் சரிபார்க்கப்பட்டு, இறுதியில் Kadai தொடங்கும்.
ProgressElapsed=கடந்த நேரம் %1
Step_start=தயாராகிறது
Step_checksum=நிறுவல் கோப்புகள் சரிபார்க்கப்படுகின்றன
Step_unpack=Kadai Server நகலெடுக்கப்படுகிறது
Step_node=Node.js அமைக்கப்படுகிறது
Step_postgres=தரவுத்தளம் (PostgreSQL 16) நிறுவப்படுகிறது - இதுவே நீண்ட படி, 2-5 நிமிடங்கள்
Step_database=கடைக்கான தரவுத்தளம் உருவாக்கப்படுகிறது
Step_service=Kadai Server சேவை பதிவு செய்யப்படுகிறது
Step_firewall=கடை நெட்வொர்க் திறக்கப்படுகிறது
Step_backup=உங்கள் தரவு காப்புப்பிரதி எடுக்கப்படுகிறது
Step_task=தினசரி காப்புப்பிரதி திட்டமிடப்படுகிறது
Step_waiting=Kadai தொடங்கி தரவுத்தளம் தயாராகிறது
Step_ready=Kadai இயங்குகிறது

FailTitle=Kadai Server-ஐ நிறுவ முடியவில்லை
FailNext=சிக்கலைச் சரிசெய்து நிறுவலை மீண்டும் இயக்குங்கள் - நின்ற இடத்திலிருந்து தொடரும்.
FailLog=முழு பதிவு: %1
FailOpenLog=பதிவை Notepad-இல் திறக்கவா?
FailTimeout=%1 நிமிடங்களுக்குள் நிறுவல் முடியவில்லை.
FailStart=Windows PowerShell-ஐத் தொடங்க முடியவில்லை: %1
FailTemp=%1-இல் தற்காலிகக் கோப்பை எழுத முடியவில்லை.
FailNeedPg=இந்த கணினியில் PostgreSQL 16 ஏற்கனவே உள்ளது: அதன் "postgres" கடவுச்சொல் தேவை (/PGPASSWORDFILE=<கோப்பு> அல்லது /PGPASSWORD=...).
FailPortParam=தவறான போர்ட் "%1": /PORT=<1-65535> கொடுங்கள்.
Downgrade=இந்த கணினியில் Kadai Server %1 நிறுவப்பட்டுள்ளது; இது இந்த நிறுவலை (%2) விடப் புதியது.%n%nபழைய பதிப்புக்குத் திரும்ப இயலாது: KadaiSetup %1 அல்லது புதிய பதிப்பை இயக்குங்கள்.

FinishInstalled=Kadai Server நிறுவப்பட்டு Windows சேவையாக இயங்குகிறது.
FinishUpgraded=Kadai Server %1-க்கு மேம்படுத்தப்பட்டு இயங்குகிறது.
FinishRepaired=Kadai Server சரிசெய்யப்பட்டு இயங்குகிறது.
FinishThisPc=இந்த கணினியில்: "Kadai" குறுக்குவழியைத் திறக்கவும் (http://localhost:%1)
FinishOthers=கடை நெட்வொர்க்கில் உள்ள கவுண்டர் கணினிகள், போன்கள், டேப்லெட்டுகள்:
FinishFirstRun=முதல் முறை: அமைவு வழிகாட்டியை முடியுங்கள் (கடைப் பெயர், GSTIN, உரிமையாளர் உள்நுழைவு), பிறகு அமைப்புகள் > சிஸ்டம் பகுதியில் உரிமத்தைப் பதிவேற்றுங்கள்.
FinishKeepEnv=%1 கோப்பின் நகலை USB டிரைவில் பாதுகாப்பாக வைத்திருங்கள்: புதிய கணினியில் Kadai-ஐ மீட்டெடுக்க இது தேவை.

RunOpen=இப்போதே Kadai-ஐத் திற
IconLogs=Kadai பதிவுகள்
IconGuide=Kadai வழிகாட்டி
IconUninstall=Kadai Server-ஐ நீக்கு
UninstallStatus=Kadai Server சேவை நிறுத்தப்பட்டு நீக்கப்படுகிறது...
UninstallKept=Kadai Server நீக்கப்பட்டது.%n%nஉங்கள் கடைத் தரவு, காப்புப்பிரதிகள், PostgreSQL தரவுத்தளம் %1 மற்றும் PostgreSQL 16-இல் பாதுகாப்பாக உள்ளன. KadaiSetup-ஐ மீண்டும் இயக்கினால் அவை மீண்டும் பயன்படுத்தப்படும்.
