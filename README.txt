# HB DRM-Free bulk downloader
Download link:
https://github.com/mmarcincin/HB-DRM-free-bulk-downloader/archive/master.zip
----------------------
It's a powershell script which allows you to download DRM-Free content (e-books, games, music, etc) from Humble Bundle pages (https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX) in bulk.
- works natively for Windows 8+, Windows 7 required downloading the Powershell 3+, link below
- uses Humble Bundle API to access your downloads using '_simpleauth_sess' cookie (no Internet Explorer required anymore)

To install newer Powershell on Windows 7, visit this link: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6

----------------------
HB DRM-Free bulk downloader 0.4.3
----------------------
Bundle files are downloaded sequentially and saved in folder structure as shown in this example: downloads\bundleName\bookName\specificBookFile.extension

latest additions:
- based on reports and suggestions of https://github.com/cowbutt:
	- fixed unexpected input in bundles like 'HUMBLE BUNDLE WITH ANDROID 5' and 'HUMBLE BUNDLE: PC AND ANDROID 8'
	- added option to add timestamp to log files (more info in README, md5 global switch)
	- bundle folder modified date updates when new content is downloaded inside

0.4.0 additions:
- uses Humble Bundle API to access your downloads using '_simpleauth_sess' cookie (no Internet Explorer required anymore)
- added option to download bittorent files instead of actual files
- added options to reduce file path length - more info below in switches section (path length switches)

All switches below modify the behaviour until modified again.
Both switches and links are entered in the links.txt file which will open once you launch RUN.bat.
If you want to make shortcut for the script, create shortcut for the RUN.bat.

Example of links.txt:
```
^_simpleauth_sess cookie
#pdf
https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
```

_simpleauth_sess cookie
----------------------
a) developer console option
1. navigate to humblebundle.com in your browser, open developer console using shift+i/shift+c
2. at the top you can see tabs like Elements, Console, ... open application tab (if not visible click on >>)
3. select cookies and then humblebundle.com, filter cookies by '_simpleauth_sess'
4. click on it and copy Cookie Value shown below into links.txt (best entered as first line) in format: ^text

b) browser settings option
1. a) easy steps - Copy this link into browser:
- For Opera: opera://settings/cookies/detail?site=humblebundle.com
- For Google Chrome: chrome://settings/cookies/detail?site=humblebundle.com

1. b) detailed steps
- open settings in your browser, for Opera go to Settings (alt+p), for Google Chrome click on 3 vertical dots in top right corner > go to Settings
- for Opera and Google Chrome: Enter 'cookies' into search settings field > Cookies and other site data > See all cookies and site data. > Enter 'humblebundle' into Search cookies field, choose humblebundle.com
2. Find '_simpleauth_sess' cookie and copy the cookie text in field Content into links.txt (best entered as first line) in format: ^text

You can have multiple '_simpleauth_sess' cookie text strings (if you need to download the DRM-Free files from some other humble bundle account) in your links.txt file.

comments in links.txt
----------------------
Any line which doesn't start with switch character like ~,!,@,#,$,%,^,* or https://www.humblebundle.com/downloads?key= is ignored/treated like comment line.
Because of that you can for example put titles of bundles in links.txt like this:
```
^_simpleauth_sess cookie
#pdf
Humble Book Bundle: Programming Cookbooks by O'Reilly
https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
```

Switches
----------------------
To specify your preferred label/extension/format for link only, use:
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX#pdf
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX#pdf,epub,mp3
- link preferred label will always override global one

for global preferred label use:
- #pdf
- #pdf,epub,mp3
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
- #none (default, this will return to downloading all versions)
- if some book/game/audio doesn't have preferred label, it'll download first label (unless overridden by %strict)

platform/section global switches:
- default sections: @windows,audio,video,ebook,others
- known sections: windows,linux,mac,android,audio,video,ebook,others
- @linux,mac (override default sections and download only these sections (multiple options))
- @+linux,mac (add mentioned sections to download sections in addition to default ones (multiple options))
- @-windows,video (supress downloading mentioned sections (takes precedence over default and additional sections))
- @+ (default, restore default sections)
- @- (default, no supressed sections)
- @all (disable section filtering)
- @all- (default, enable section filtering if modified before in links.txt)
- all of them works but it has to be the exact wording (e.g. @android, @+android, @-android)

md5 global switches:
- !md5+ (default, enable md5 file integrity check)
- !md5- (disable md5 file integrity check completely; !md5s- is not needed)
- !md5s+ (default, enable md5 hash check/file integrity of previously stored/downloaded files in addition to the files you just downloaded, disabled if you use !md5-)
- !md5s- (disable md5 hash check/file integrity of previously stored/downloaded files)
- md5 file integrity check works for log purposes only, no further actions are taken for now
- !logtime (log files are saved in 'logs' folder with date and time in format LOG-all-yyyy-MM-dd-HHmmss.txt and LOG-error-yyyy-MM-dd-HHmmss.txt)
- !logtimeutc (log files are saved in 'logs' folder with UTC date and time in format LOG-all-yyyy-MM-dd-HHmmssZ.txt and LOG-error-yyyy-MM-dd-HHmmssZ.txt)
- unlike most switches !logtime and !logtimeutc are applied once per script execution and can't be modified for now (intentional)


log files:
- LOG-all.txt -- complete log(downloads + errors)
- LOG-error.txt -- log of errors only (md5 fails and unsuccessful downloads)
- if you use !md5-, LOG-all.txt and LOG-error.txt will contain only unsuccessful downloads

preference global switches:
- %normal (default, return to downloading at least 1 label)
- %strict (download only your preferred label)
-
- %pref (default, download first found preferred label in list and skip others)
- %all (download all preferred labels)

Switches #,%,!,~ support multiple parameters in one line:
- %strict,pref (download only 1 specified label and skip others, even those without the pref label)

direct download switches:
- *direct - downloads file itself
- *bittorrent - downloads bittorent file

path length switches:
- ~fullbundle (default, fully qualified bundle name)
- ~keybundle (bundle name is represented by key value from purchase link)
- ~if_title-60_file-30 (conditional filename shortening: if title length is longer than 60, shorten filename length including extension to 30; values can be modified)
- ~if_title-0_file-0 (default, to disable conditional file shortnening if you enabled it earlier in links.txt)
- they can be used in one line as well like: ~keybundle,if_title-60_file-30
- example:
	- bundle title: Humble Book Bundle_ Cybersecurity presented by Wiley
	- ebook title: Practical Reverse Engineering_ x86_ x64_ ARM_ Windows Kernel_ Reversing Tools_ and Obfuscation
	- filename: practical_reverse_engineering_x86_x64_arm_windows_kernel_reversing_tools_and_obfuscation.pdf
	- these 3 alone make the file path length of 240 extra 44 if you add default script folder structure (HB-DRM-Free-bulk-downloader-master\downloads)
	- using ~keybundle switch the bundle title will have length of 16 (vs 52) which saves you 36 characters, in addition using ~IF_title-60_file-30 you'll get filename with length of 30 (vs 92) which saves you another 62 characters for a total of 98 characters total
	- the end result structure would look like this: XXXXXXXXXXXXXXXX\Practical Reverse Engineering_ x86_ x64_ ARM_ Windows Kernel_ Reversing Tools_ and Obfuscation\practical_reverse_engineer.pdf
	
255+ file paths issues
----------------------
If you still have troubles with long file paths, considering moving downloader up in the folder structure or try using subst for your folder.
- You can find more info using links below:
- https://support.code42.com/Incydr/Agent/Troubleshooting/Windows_file_paths_longer_than_255_characters
- https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#enable-long-paths-in-windows-10-version-1607-and-later

Downloads are permanently stored after each book/download versions are retrieved.
If you interrupt it then your partially downloaded book/download will be removed.
Next time you start this script, it'll continue where you left (the next book/download) if you kept the downloaded books/downloads in downloads folder.

To better track the download progress without minimizing your active window, you can go to Taskbar settings: Combine Taskbar buttons > 'When Taskbar is full'. 
Then you'll be able to see the download progress shown in the window title on your taskbar.

Powershell ExecutionPolicy change
----------------------
start RUN.bat to launch the script
for editing the script itself open HB-DRM-Free_download.ps1 in notepad (or notepad++, etc...)

If the window closes fast after starting RUN.bat, follow these steps: 
1. Go to any folder (file explorer) and choose file > open windows powershell > open windows powershell as administrator.
2. In the Windows PowerShell window type: get-ExecutionPolicy.
3. If you are geting the 'Restricted' text, type: set-ExecutionPolicy RemoteSigned,
   then just confirm with y for yes.
4. After that the RUN.bat should work as intented.

If you'd like to create a shortcut for the script, you just need to make shortcut of RUN.bat file.

Possible Errors - unremovable folder with leading/trailing space
----------------------
There were bundles which had space at the end of their name, before version 0.3.5 it didn't remove those spaces which could cause problems mentioned below.

If my script created folder with space (" ") in name and you can't remove it now, you could try this to fix it:
quote by JustSolvedIt from https://superuser.com/questions/565334/rename-delete-windows-x64-folder-with-leading-and-trailing-space/911994#911994
> I just had a similar problem with folder "Monuments - Discography " created in linux. Windows Vista and Windows 7 couldn't recognize this folder as a valid data and when I tried to rename or remove it I got Info message saying that folder does not exist etc. The solution was to explore a dir with 7zip file manager and rename the folder by removing a white space from the end. Simple. Now I can enjoy the music once again :D
