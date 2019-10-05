# HB DRM-Free bulk downloader
https://github.com/mmarcincin/HB-DRM-free-bulk-downloader/archive/master.zip
----------------------
It's a powershell script which allows you to download books from humble bundle pages (https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX) in bulk.
It works natively for Windows 8+, Windows 7 required downloading the Powershell 3+, link below.
It uses Internet Explorer instance to retrieve the links so all you need to do is login to humble bundle through the Internet Explorer and that's it.

To install newer Powershell on Windows 7, visit this link: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6

----------------------
HB DRM-Free bulk downloader 0.3.5
----------------------
Bundle files are downloaded sequentially and saved in folder structure as shown in this example: downloads\bundleName\bookName\specificBookFile.extension

latest additions:
- support for MD5 hash file check (more info below)
- it's possible to download bundles with leading/trailing space in titles now (thanks to ratinoxone from GitHub)

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

platform global switches:
- @default (needed only when you want to reset it back, for exmaple from mac back to default for next set of links)
- @windows (usually selected by default; if you really want to reset it use @default instead)
- @mac
- @linux
- all of them works but it has to be the exact wording (e.g. @android)

md5 global switches:
- !md5+ (default, enable md5 file integrity check)
- !md5- (disable md5 file integrity check)
- !md5s+ (default, enable md5 hash check/file integrity of previously stored/downloaded files, disabled if you use !md5-)
- !md5s- (disable md5 hash check/file integrity of previously stored/downloaded files)

log files:
- LOG-all.txt -- complete log(downloads + errors)
- LOG-error.txt -- log of errors only (md5 fails and unsuccessful downloads)
- if you use !md5-, LOG-all.txt and LOG-error.txt will contain only unsuccessful downloads

other global switches:
- %normal (default, this will return to downloading at least 1 label)
- %strict (this will download only your preferred label)

another set of global switches:
- %pref (default, download first found preferred label in list and skip others)
- %all (download all preferred labels)

They can be used together in one line:
- %strict,pref (this would download only 1 specified label and skip others, even those without the pref label)

only # and % switches supports multiple parameters

Downloads are permanently stored after each book/download versions are retrieved.
If you interrupt it then partially downloaded books will be removed.
Next time you start this script, it'll continue where you left (the next book/download) if you kept the downloaded books in downloads folder.

To better track the download progress without minimizing your active window, you can go to Taskbar settings: Combine Taskbar buttons > 'When Taskbar is full'. 
Then you'll be able to see the download progress shown in the window title of your taskbar.

Powershell ExecutionPolicy change
----------------------
start RUN.bat to launch the script
for editing the script itself open HB-books_download.ps1 in notepad (or notepad++,etc...)

If the window closes fast after starting RUN.bat, follow these steps: 
1. Go to any folder (file explorer) and choose file > open windows powershell > 
   > open windows powershell as administrator.
2. In the Windows PowerShell window type: get-ExecutionPolicy.
3. If you are geting the 'Restricted' text, type: set-ExecutionPolicy RemoteSigned,
   then just confirm with y for yes.
4. After that the RUN.bat should work as intented.

If you'd like to create a shortcut for the script, you just need to make shortcut of RUN.bat file.

Possible Errors - download stuck at the beginning
----------------------
If your bundle haven't started downloading already for 10+ sec and you were redirected here then open your Internet Explorer and go to https://www.humblebundle.com/.
Try to click on the dropdown menu button in top right corner, it doesn't respond most likely. You also can't see any bundles on the front page.

To make it work, follow these steps:
1. Open Internet Explorer, press alt (the toolbar will show up), go to Tools > Internet Options > Security Tab(at the top) > Trusted sites
   - move the vertical bar to the bottom (Low option)
   - click on Sites button and add 'https://www.humblebundle.com/' into the list (otherwise the site would load only partially)
2. Enable Protected Mode for Trusted sites (ReadyState was blank when this was disabled so script was stuck).
3. It's possible you'll get logged out of Humble Bundle after changing to Protected Mode so just login there again.

My script loads IE instance only for links and once the download starts, the IE instance should be already closed.
If you saw the PowerShell message to check this error, the IE instance is already closed as well.

Killing Internet Explorer instances might help if you encountered problems before it started working. 

The fastest way to do it is to run this 'stop process' command in PowerShell: 
get-process iexplore.exe | stop-process

You can check afterwards with 'get-process iexplore.exe', if you've got an error it means the IE doesn't have any windows opened. If you still have the iexplore.exe there it means you have to launch Powershell as administrator (option in File menu in your File Explorer) and run the same 'stop process' command again.

Possible Errors - 'Humble Bundle - Key already claimed'
----------------------
If you're getting 'Humble Bundle - Key already claimed' instead of bundle title when you run the script, it means you're not logged into your Humble Bundle account (which owns the bundle) in the Internet Explorer.

Possible Errors - 'Exception from HRESULT: 0x800A01B6'
----------------------
If you're getting 'Exception from HRESULT: 0x800A01B6' error, try launching RUN.bat as administrator.
You could also follow steps in 'Possible Errors - download stuck at the beginning' above.

Possible Errors - unremovable folder with leading/trailing space
----------------------
If my script created folder with space (" ") in name and you can't remove it now, you could try this to fix it:
quote by JustSolvedIt from https://superuser.com/questions/565334/rename-delete-windows-x64-folder-with-leading-and-trailing-space/911994#911994
> I just had a similar problem with folder "Monuments - Discography " created in linux. Windows Vista and Windows 7 couldn't recognize this folder as a valid data and when I tried to rename or remove it I got Info message saying that folder does not exist etc. The solution was to explore a dir with 7zip file manager and rename the folder by removing a white space from the end. Simple. Now I can enjoy the music once again :D