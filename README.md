This is the autologin script (initial loader is AutologinUI.pas) for the PAID adrenaline version.

AutologinUI doesn't provide UI to update account credentials (need to edit settings file), but provides UI to control accounts.

AutologinUI can automatically restart accounts if the window was closed (instantly), or script detects offline state (usually when the server restarts, but it can take up to 5 minutes in some cases).

AutologinUI can also unload accounts automatically.

AutologinUI is used as a controller script. You load it in one adrenaline profile, and the script will auto-load/unload required accounts.

Quickstart
==========

DEMO: https://disk.yandex.com/i/GB5MQ3tqTPQm8A

Settings
--------
1. Open Settings.ini file and change account data.
For example account_0=False,Login,Password,Nickanme -> This is first account 

BE VERY CAREFUL HERE, Nickname is already existing character name, which is used to validate the account "is nickname online".
If you fill it incorrectly or fill in incorrect credentials, the script will try to load the account infinity times.
...

2. Change how many accounts will be visible in UI / controlled
max_accounts=11

3. Change client game path
client_path="C:\bin\L2Kot\system\l2.exe"

Load script
-----------
In Adrenaline UI add a profile (Add account button) and load script (AutologinUI.pas) only in the first profile.
Then run it. If you filled all settings correctly, enable the first account and wait when it will be loaded. If something goes wrong (script trying to load it again). Stop script and check Settings.ini file.

After you loaded and validated all accounts, you can dynamically enable/disable them.

Links
=======
- Demos: https://disk.yandex.com/i/GB5MQ3tqTPQm8A
