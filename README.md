# HB DRM-Free bulk downloader
https://github.com/mmarcincin/HB-DRM-free-bulk-downloader/archive/master.zip
----------------------
It's a powershell script (It should work for Windows 7+) which allows you to download books and other DRM-Free files from humble bundle pages (https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX) in bulk.
It uses Internet Explorer instance to retrieve the links so all you need to do is login to humble bundle through the Internet Explorer and that's it.
----------------------
HB DRM-Free bulk downloader 0.2 (previously named HB books bulk downloader 0.1)
----------------------
Bundle files are downloaded sequentially and saved in folder structure as shown in this example: downloads\bundleName\bookName\specificBookFile.extension

To specify your preferred label/extension/format for link only, use:
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX#pdf
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX#pdf,epub,mp3
- link preferred label will always override global one

for global preferred label use:
- #pdf
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
- https://www.humblebundle.com/downloads?key=XXXXXXXXXXXXXXXX
- #none (default, this will return to downloading all versions)
- if some book/game/audio doesn't have preferred label, it'll download first label (unless overridden by %strict)

platform global switches:
- @windows (default)
- @mac
- @linux
- all of them works but it has to be the exact wording (e.g. @android)

other global switches:
- %strict (this will download only your preferred label)
- %normal (default, this will return to downloading at least 1 label)
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

If the window closes fast after starting RUN.bat (or it doesn't show on startup when using that option): 
1. Go to any folder (file explorer) and choose file > open windows powershell > 
   > open windows powershell as administrator.
2. In the Windows PowerShell window type: get-ExecutionPolicy.
3. If you are geting the 'Restricted' text, type: set-ExecutionPolicy RemoteSigned,
   then just confirm with y for yes.
4. After that the RUN.bat should work as intented.

If you'd like to create a shortcut for the script, you just need to make shortcut of RUN.bat file.
