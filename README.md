This is autologin script (intial loader is AutologinUI.pas) for PAID adrenaline version.

AutologinUI doesnt provide UI to update account credentials (need to edit settings file), but provide UI to control accounts.

AutologinUI can automaticaly restart accounts if window was closed (instantly), or script detected offline state (usualy when server restart, but it can take up to 5 minutes in some cases).

AutologinUI can also unload accounts automaticaly.

AutologinUI used as controller script. You load it in one adrenaline profile, and script will auto-load/unload required accounts.

Quickstart
==========

DEMO: https://disk.yandex.com/i/GB5MQ3tqTPQm8A

Settings
--------
1. Open Settings.ini file and change accounts data.
For example account_0=False,Login,Password,Nickanme -> This is first account 

BE WERY CAREFUL HERE, Nickname is already existing charactre name, which used to validate account "is nickname online".
If you fill it incorrectly, or fill incorrect credentials, script will try to load account infinity times.
...

2. Change how much accounts will be visible in UI / controlled
max_accounts=11

3. Change client game path
client_path="C:\bin\L2Kot\system\l2.exe"

Load script
-----------
In Adrenaline UI add profile (Add account button) and load script (AutologinUI.pas) only in first profile.
Then run it. If you filled all settings correctly, enable first account and wait when it fill be loaded. If something going wrong (script trying to load it again). Stop script and check Settings.ini file.

After you loaded and validated all accounts, you can dynamicale enable/disable them.

Links
=======
- Demos: https://disk.yandex.com/i/GB5MQ3tqTPQm8A
