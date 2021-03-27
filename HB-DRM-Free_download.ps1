#Requires -Version 3.0
### HB DRM-Free bulk downloader 0.3.7 by https://github.com/mmarcincin
#$links = "links.txt"
$invocation = (Get-Variable MyInvocation).Value
$DownloadDirectory = Split-Path $invocation.MyCommand.Path
### expansion for 260+ length paths \\?\
	$DownloadDirectory = "\\?\"+"$DownloadDirectory"
$links = "$($DownloadDirectory)\links.txt"
$logAll = "$($DownloadDirectory)\LOG-all.txt"
$logError = "$($DownloadDirectory)\LOG-error.txt"
$DownloadDirectory = "$($DownloadDirectory)\downloads"
#$DownloadDirectory = "downloads"
$temp = "$DownloadDirectory\temp"

### default behavior ###
#0 means if preferred label is set and not found at specific book/game, it'll download first label/extension in the list, 1 means pref labels only
$strictSwitch = 0
#1 means it'll download the first labels/extension found in the list, 0 means it'll download all labels/extensions in the list
$prefSwitch = 1
#default Operating System
$osSwitch = "default"
#md5 hash check of files enabled
$md5Switch = 1
#md5 hash check of previously stored/downloaded files enabled
$md5sSwitch = 1
#not implemented - for future use
$genListSwitch = 0
#if 1 opens visible Internet Explorer window to login
$loginSwitch = 0
###

$bundleLog = 0
$titleLog = 0
$bundleErrorLog = 0
$titleErrorLog = 0
$md5Errors = 0
$notFoundErrors = 0

write-host HB DRM-Free bulk downloader 0.3.7 by https://github.com/mmarcincin
write-host `nDownload directory`: $DownloadDirectory`n

$ConCountr1 = 0
### Test Internet connection
While (!(Test-Connection -ComputerName humblebundle.com -count 1 -Quiet -ErrorAction SilentlyContinue )) {
	Write-Host -ForegroundColor Red "Waiting for internet connection to continue..."
	Start-Sleep -Seconds 10
	$ConCountr1 += 1
	If ($ConCountr1 -ge 12) {
		Write-Host -ForegroundColor Red "Script terminated because of no internet connection/humblebundle response for 120 seconds."
		Start-Sleep -Seconds 5
		return
	}
}


If (!(Test-Path $DownloadDirectory)){
	New-Item -ItemType directory -Path $DownloadDirectory | Out-Null
}

If (!(Test-Path $temp)){
	New-Item -ItemType directory -Path $temp | Out-Null
}
Remove-Item "$temp\*" -Recurse


If (!(Test-Path $links)){
	New-Item -ItemType file -Path $links | Out-Null
}

If ((Test-Path $logAll)){ Remove-Item $logAll }
If (!(Test-Path $logAll)){
	New-Item -ItemType file -Path $logAll | Out-Null
	Get-Date -Format "yyyy-MM-dd dddd HH:mm K" | Out-File $logAll
}

If ((Test-Path $logError)){ Remove-Item $logError }
If (!(Test-Path $logError)){
	New-Item -ItemType file -Path $logError | Out-Null
	Get-Date -Format "yyyy-MM-dd dddd HH:mm K" | Out-File $logError
}


function downfile($url, $filename)  
{  
$wc = New-Object System.Net.WebClient  
try  
{  
	$wc.DownloadFile($url, $filename)  
}  
catch [System.Net.WebException]  
{  
	Write-Host("Cannot download $url")  
}   
finally  
{    
	$wc.Dispose()  
}  
}

function md5hash($path)
{
	#$fullPath = Resolve-Path $path
	$fullPath = $path
	If ((Test-Path $fullPath)) {
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	$file = [System.IO.File]::Open($fullPath,[System.IO.Filemode]::Open, [System.IO.FileAccess]::Read)
	try {
		[System.BitConverter]::ToString($md5.ComputeHash($file))
	} finally {
		$file.Dispose()
	}
	} else {
		return "none"
	}
}

$currentDownload = 0
$downloadCount = Get-Content $links | Where {$_.indexOf("https://www.humblebundle.com/downloads?key=") -eq "0"} | Measure-Object -Line | Select -ExpandProperty Lines
$emptyCheck = Get-Content $links | Measure-Object -Line | Select -ExpandProperty Lines
if ($emptyCheck -eq "0") { echo "*login" | Out-File $links -append }

Get-Content $links | Foreach-Object {
	if ($_.indexOf("https://www.humblebundle.com/downloads?key=") -eq "0") {
		$currentDownload++
		$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount
		
		$ie = new-object -ComObject "InternetExplorer.Application"
		$requestUri = $_.trim()
		
		$requestLink = $requestUri.split("#")[0]
		$prefLabel = $requestUri.split("#")[1]
		if ($prefLabel.length -eq 0) { $prefLabel = $prefGLabels}
		if (($prefLabel.length -eq 0) -and ($prefGLabels.length -eq 0)) { $prefLabel = "none" }
		$prefLabels = $prefLabel.split(",")
		write-host link: $requestLink
		if ($prefSwitch -eq "1") { write-host preferred labels: $prefLabel } else { if ($prefSwitch -eq "0") { write-host download labels: $prefLabel }}
		if ($strictSwitch -eq "0") { write-host strict mode: disabled } else { if ($strictSwitch -eq "1") { write-host strict mode: enabled }}
		write-host OS: $osSwitch
		if ($md5Switch -eq "1") { write-host MD5 file check: enabled } else { if ($md5Switch -eq "0") { write-host MD5 file check: disabled }}
		if ($md5Switch -eq "1") { if ($md5sSwitch -eq "1") { write-host MD5 stored file check: enabled } else { if ($md5sSwitch -eq "0") { write-host MD5 stored file check: disabled }}}

		#$ie.visible = $true
		$ie.silent = $true
		$ie.navigate($requestLink)
		#while($ie.Busy) { Start-Sleep -Milliseconds 100 }
		while($ie.Busy -or $ie.ReadyState -ne "4") { Start-Sleep -Milliseconds 100 }
		
		$drmCheckCounter = 0
		while (($ie.Document.getElementsByClassName("whitebox-redux").length -eq "0") -or ($ie.Document.getElementsByClassName("whitebox-redux")[0].innerText.length -eq "0") -or ($ie.Document.getElementsByClassName("icn").length -eq "0") -or ($ie.Document.getElementsByClassName("icn")[0].innerText.length -eq "0")) { 
			Start-Sleep -Milliseconds 100
			$drmCheckCounter += 1
			if (($ie.Document.getElementsByClassName("page_title")[0].getElementsByTagName("h1").length -gt 0) -and ($ie.Document.getElementsByClassName("page_title")[0].getElementsByTagName("h1")[0].innerHTML.toLower() -eq "this page is claimed")) { break; }
			if ($drmCheckCounter -ge 100) {
				if ($ie.Document.getElementsByClassName("mosaic-view").length -eq "0") { $ie.quit(); write-host "`nBundle information is not visible.`nCheck README file for 'Possible Errors - download stuck at the beginning'.`n"; pause; Exit;}
				write-host "`nNo DRM-Free content detected for this bundle (10 seconds waiting time).`n"
				break;
			}
		}
		Start-Sleep -Seconds 1
		#pause
		$doc = $ie.Document
		if (($doc.getElementsByTagName("title").length -gt 0) -and ($doc.getElementsByTagName("title")[0].innerHTML.trim().length -gt 0)) {
			$docTitle = $doc.getElementsByTagName("title")[0].innerText.trim()
		} else {	
			$docTitle = $doc.getElementById("hibtext").innerHTML.split(">")[1].split("<")[0].trim()
		}
		if ($docTitle.lastIndexOf("(") -eq -1) {$bundleName = $docTitle;} else {$bundleName = $docTitle.substring(0, $docTitle.lastIndexOf("(") - 1)}
		$bundleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($bundleName))
		$bundleTitle = $bundleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
		$bundleTitle = $bundleTitle -replace '/', '_'
		$bundleTitle = $bundleTitle.trim()
		
		$allScripts = $ie.Document.getElementsByTagName("script")
		for ($i = 0; $i -lt $allScripts.length; $i++) {
			if ($allScripts[$i].src.length -eq 0 -and $allScripts[$i].text.IndexOf("window.models.user_json") -ne -1) {
				$loginCheck = $allScripts[$i].text.substring($allScripts[$i].text.indexOf("window.models.user_json")).split("`n")[0].replace(" ","");
				if ($loginCheck -ne "window.models.user_json={};") {$loginInfoJSON = $loginCheck.substring($loginCheck.indexOf("={")+1,$loginCheck.length-$loginCheck.indexOf("={")-2); $loginAccount = ($loginInfoJSON | ConvertFrom-Json).email} else {$loginAccount = "none"}
			break;
			}
		}
		#loginAccount none if not logged in, email if logged
		if ($bundleTitle -eq "Humble Bundle - Key already claimed") {
			if ($loginAccount -eq "none") {
				$bundleTitle += "`n`nYou are currently not logged into your Humble Bundle Account through the Internet Explorer.`nYou can log-in manually or use the *login switch in links.txt (more info in readme file).`n";
			} else {
				$bundleTitle += "`n`nYou are currently logged into Humble Bundle Account '" + $loginAccount + "'`n(through the Internet Explorer) not linked to this bundle.`nYou can log-in manually or use the *login switch in links.txt (more info in readme file).`n" 
			}
		}
		
		write-host ==============================================================
		write-host $currentDownload "/" $downloadCount - $bundleTitle
		write-host $requestLink
		write-host --------------------------------------------------------------
		$bundleLog = 0
		$bundleErrorLog = 0

		if ($osSwitch -ne "default") {
			if ($doc.getElementsByClassName("dlplatform-list").length -gt 0) {
				$platforms = $doc.getElementsByClassName("dlplatform-list")
				for ($i = 0; $i -lt $platforms.length; $i++) {
					$platform = $platforms[$i].getElementsByClassName("label")
					for ($j = 0; $j -lt $platform.length; $j++) {
						if ($platform[$j].innerHTML.toLower() -eq $osSwitch) { 
							$platform[$j].click()
							if ($doc.getElementsByClassName("dlplatform-list")[$i].getElementsByClassName("label")[$j].parentNode.className.indexOf("active") -eq "-1") { $failedOSSwitch = 1 }
							Start-Sleep -Seconds 1
						}
					}
				}
			}
		}
		if ($failedOSSwitch -eq 1) {
			write-host Failed to switch OS platform
			pause
		}

		$titleList = New-Object System.Collections.ArrayList
		$downTitleList = New-Object System.Collections.ArrayList
		$downLinkList = New-Object System.Collections.ArrayList
		$curLabelList = New-Object System.Collections.ArrayList
		$md5List = New-Object System.Collections.ArrayList
		$publisherList = New-Object System.Collections.ArrayList
		
		### link collection section
		
		$hb = $doc.getElementsByClassName("icn")
		for ($i = 0; $i -lt $hb.length; $i++) {
			$curTitle = $hb[$i].parentNode
			$humbleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($curTitle.getAttribute("data-human-name")))
			$humbleTitle = $humbleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
			$humbleTitle = $humbleTitle -replace '/', '_'
			$humbleTitle = $humbleTitle.trim()
			$humblePublisher = $curTitle.getElementsByClassName("subtitle")[0].getElementsByTagName("a")[0].innerText
			
			$titleList.Add($humbleTitle) > $null
			$publisherList.Add($humblePublisher) > $null
			
			$downAlready = -1
			if ($curTitle.getElementsByClassName("download-buttons")[0].innerHTML.length -gt "0") {
				$downLabels = $curTitle.getElementsByClassName("download-buttons")[0].getElementsByClassName("label")
				for ($j = 0; $j -lt $prefLabels.length; $j++) {
					for ($k = $downLabels.length-1; $k -ge 0; $k--) {
						if (($downAlready -eq "1") -and ($prefSwitch -eq "1") -and ($prefLabels[0].ToLower().trim() -ne "none")) { break; }
						$curLabel = $downLabels[$k].innerHTML
						if (($curLabel.ToLower() -eq $prefLabels[$j].ToLower().trim()) -or ($prefLabels[0].ToLower().trim() -eq "none")) {
							$downAlready = 1
							
							$downLink = $downLabels[$k].parentNode.getElementsByClassName("a")[0].href
							$md5c = $downLabels[$k].parentNode.parentNode.getElementsByClassName("dlmd5")[0]
							$md5c.click()
							#Start-Sleep -Seconds 1
							$md5c = $downLabels[$k].parentNode.parentNode.getElementsByClassName("dlmd5")[0]
							$md5ct = $md5c.innerText.trim()
							$downName = $downLink.split("?")[0].split("/")
							$downTitle = $downName[$downName.length-1].trim()
							
							$downTitleList.Add($downTitle) > $null
							$downLinkList.Add($downLink) > $null
							$curLabelList.Add($curLabel) > $null
							$md5List.Add($md5ct) > $null
						}
					}
				}
				
				### if preferred label is not found, it'll download the first label unless %strict global switch is applied
			if (($downAlready -eq "-1") -and ($strictSwitch -eq "0")) {
				#write-host `-`- Preferred label not found`, downloading first label `-`-
				$curLabel = $downLabels[$downLabels.length-1].innerHTML
				$downLink = $downLabels[$downLabels.length-1].parentNode.getElementsByClassName("a")[0].href
				$md5c = $downLabels[$downLabels.length-1].parentNode.parentNode.getElementsByClassName("dlmd5")[0]
				$md5c.click()
				$md5c = $downLabels[$downLabels.length-1].parentNode.parentNode.getElementsByClassName("dlmd5")[0]
				$md5ct = $md5c.innerText.trim()
				$downName = $downLink.split("?")[0].split("/")
				$downTitle = $downName[$downName.length-1].trim()
				
				$downTitleList.Add($downTitle) > $null
				$downLinkList.Add($downLink) > $null
				$curLabelList.Add($curLabel) > $null
				$md5List.Add($md5ct) > $null
			}
			
			$downTitleList.Add($i) > $null
			$downLinkList.Add($i) > $null
			$curLabelList.Add($i) > $null
			$md5List.Add($i) > $null
			}
		}
		#$downTitleList
		#pause
		$ie.quit()
		#pause
		### download section
		$downIndex = 0
		for ($i = 0; $i -lt $titleList.Count; $i++) {
			$humbleTitle = $titleList[$i]
			$chunkLength = $titleList.Count
			$chunkNumber = $i+1
			$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount +" `| "+ $chunkNumber + "/" + $chunkLength
			
			write-host `n$chunkNumber / $chunkLength - $humbleTitle
			$titleLog = 0
			$titleErrorLog = 0
			
			for ($j = $downIndex; $j -lt $downTitleList.Count; $j++) {
				if ($downTitleList[$j] -eq $i) { $downIndex = $j + 1; break; }
				
				$downTitle = $downTitleList[$j]
				$downLink = $downLinkList[$j]
				$curLabel = $curLabelList[$j]
				$curMD5 = $md5List[$j]
				
				write-host $curLabel - $downTitle

				$downDest = "$temp\$bundleTitle\$humbleTitle\$downTitle"

				If (!(Test-Path $DownloadDirectory\$bundleTitle\$humbleTitle\$downTitle)){
					#$wc.DownloadFile($downLink, $downDest)
					If (!(Test-Path $temp\$bundleTitle\$humbleTitle)){ New-Item -ItemType directory -Path $temp\$bundleTitle\$humbleTitle | Out-Null }
					downFile $downLink $downDest
					### md5 check and output to LOG files
					if ($md5Switch -eq 1 -or !(Test-Path $downDest)) {
						$md5f = md5hash("$downDest")
						$md5fd = $md5f.ToLower().replace("-", "")
						if ($md5fd -eq $curMD5) {
							write-host "   "OK - File integrity `(MD5`) verified.
							
							if ($bundleLog -eq 0) {
							echo "==============================================================" | Out-File $logAll -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logAll -append
							echo "$requestLink" | Out-File $logAll -append
							echo "--------------------------------------------------------------" | Out-File $logAll -append
							$bundleLog = 1
							}
							
							if ($titleLog -eq 0) {
								echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logAll -append
								$titleLog = 1
							}
							
							echo "$curLabel - $downTitle" | Out-File $logAll -append
							echo "   OK - File integrity `(MD5`) verified." | Out-File $logAll -append
							echo "   MD5`: $curMD5" | Out-File $logAll -append
						} else {
							if ($md5fd -eq "none") { $notFoundErrors++; $errorReason = "Unsuccessful download (file not found)." } else { $errorReason = "File integrity `(MD5`) failed." }
							$md5Errors++
							write-host "   "FAIL - $errorReason
							write-host "   "File MD5`: $md5fd
							write-host "   "HB   MD5`: $curMD5
							
							if ($bundleLog -eq 0) {
							echo "==============================================================" | Out-File $logAll -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logAll -append
							echo "$requestLink" | Out-File $logAll -append
							echo "--------------------------------------------------------------" | Out-File $logAll -append
							$bundleLog = 1
							}
							
							if ($bundleErrorLog -eq 0) {
							echo "==============================================================" | Out-File $logError -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logError -append
							echo "$requestLink" | Out-File $logError -append
							echo "--------------------------------------------------------------" | Out-File $logError -append
							$bundleErrorLog = 1
							}
							
							if ($titleLog -eq 0) { echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logAll -append ; $titleLog = 1 }
							if ($titleErrorLog -eq 0) { echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logError -append; $titleErrorLog = 1 }
							
							echo "$curLabel - $downTitle" | Out-File $logAll -append
							echo "   FAIL - $errorReason" | Out-File $logAll -append
							echo "   File MD5`: $md5fd" | Out-File $logAll -append
							echo "   HB   MD5`: $curMD5" | Out-File $logAll -append
							
							echo "$curLabel - $downTitle" | Out-File $logError -append
							echo "   FAIL - $errorReason" | Out-File $logError -append
							echo "   File MD5`: $md5fd" | Out-File $logError -append
							echo "   HB   MD5`: $curMD5" | Out-File $logError -append
						}
					}
				} else {
					write-host "   "File downloaded already, skipping...
					if ($md5Switch -eq 1 -and $md5sSwitch -eq 1) {
						$md5f = md5hash("$DownloadDirectory\$bundleTitle\$humbleTitle\$downTitle")
						$md5fd = $md5f.ToLower().replace("-", "")
						if ($md5fd -eq $curMD5) {
							write-host "   "OK - File integrity `(MD5`) verified.
							
							if ($bundleLog -eq 0) {
							echo "==============================================================" | Out-File $logAll -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logAll -append
							echo "$requestLink" | Out-File $logAll -append
							echo "--------------------------------------------------------------" | Out-File $logAll -append
							$bundleLog = 1
							}
							
							if ($titleLog -eq 0) {
								echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logAll -append
								$titleLog = 1
							}
							
							echo "$curLabel - $downTitle" | Out-File $logAll -append
							echo "   File downloaded already, skipping..." | Out-File $logAll -append
							echo "   OK - File integrity `(MD5`) verified." | Out-File $logAll -append
							echo "   MD5`: $curMD5" | Out-File $logAll -append
						} else {
							if ($md5fd -eq "none") { $notFoundErrors++; $errorReason = "Unsuccessful download (file not found)." } else { $errorReason = "File integrity `(MD5`) failed." }
							$md5Errors++
							write-host "   "FAIL - $errorReason
							write-host "   "File MD5`: $md5fd
							write-host "   "HB   MD5`: $curMD5
							
							if ($bundleLog -eq 0) {
							echo "==============================================================" | Out-File $logAll -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logAll -append
							echo "$requestLink" | Out-File $logAll -append
							echo "--------------------------------------------------------------" | Out-File $logAll -append
							$bundleLog = 1
							}
							
							if ($bundleErrorLog -eq 0) {
							echo "==============================================================" | Out-File $logError -append
							echo "$currentDownload / $downloadCount - $bundleTitle" | Out-File $logError -append
							echo "$requestLink" | Out-File $logError -append
							echo "--------------------------------------------------------------" | Out-File $logError -append
							$bundleErrorLog = 1
							}
							
							if ($titleLog -eq 0) { echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logAll -append ; $titleLog = 1 }
							if ($titleErrorLog -eq 0) { echo "`n$chunkNumber / $chunkLength - $humbleTitle" | Out-File $logError -append; $titleErrorLog = 1 }
							
							echo "$curLabel - $downTitle" | Out-File $logAll -append
							echo "   File downloaded already, skipping..." | Out-File $logAll -append
							echo "   FAIL - $errorReason" | Out-File $logAll -append
							echo "   File MD5`: $md5fd" | Out-File $logAll -append
							echo "   HB   MD5`: $curMD5" | Out-File $logAll -append
							
							echo "$curLabel - $downTitle" | Out-File $logError -append
							echo "   File downloaded already, skipping..." | Out-File $logError -append
							echo "   FAIL - $errorReason" | Out-File $logError -append
							echo "   File MD5`: $md5fd" | Out-File $logError -append
							echo "   HB   MD5`: $curMD5" | Out-File $logError -append
						}
					}
				}
			
			If (!(Test-Path $DownloadDirectory\$bundleTitle\$humbleTitle)){
			New-Item -ItemType directory -Path $DownloadDirectory\$bundleTitle\$humbleTitle | Out-Null
			}
			Move-Item -Path $temp\$bundleTitle\$humbleTitle\* -Destination $DownloadDirectory\$bundleTitle\$humbleTitle
			}
		}
		
	Remove-Item "$temp\*" -Recurse
	write-host ==============================================================
	echo "==============================================================" | Out-File $logAll -append
	echo "==============================================================" | Out-File $logError -append
	
	Start-Sleep -Seconds 4
	} else {
		if ($_.indexOf("#") -eq "0") {
			$prefGLabels = $_.split("#")[1]
		}
		if ($_.indexOf("%") -eq "0") {
			$strictDown = $_.split("%")[1].split(",")
			for ($i = 0; $i -lt $strictDown.length; $i++) {
			switch ($strictDown[$i].toLower().trim()) {
				"strict" {$strictSwitch = 1; break}
				"normal" {$strictSwitch = 0; break}
				"all" {$prefSwitch = 0; break}
				"pref" {$prefSwitch = 1; break}
			}
			}
		}
		if ($_.indexOf("@") -eq "0") {
			$osSwitch = $_.split("@")[1].toLower().trim()
		}
		if ($_.indexOf("!") -eq "0") {
			$md5fork = $_.split("!")[1].split(",")
			for ($i = 0; $i -lt $md5fork.length; $i++) {
			switch ($md5fork[$i].toLower().trim()) {
				"md5+" {$md5Switch = 1; break}
				"md5-" {$md5Switch = 0; break}
				"md5s-" {$md5sSwitch = 0; break}
				"md5s+" {$md5sSwitch = 1; break}
				"genlist" {$genListSwitch = 1; break} # not in use
			}
			}
		}
		if ($_.indexOf("*") -eq "0") {
			$loginfork = $_.split("*")[1].split(",")
			for ($i = 0; $i -lt $loginfork.length; $i++) {
			switch ($loginfork[$i].toLower().trim()) {
				"login" {$loginSwitch = 1; break}
				"login_pause" {$loginSwitch = 2; break}
			}
			}
		}
	}
	if ($loginSwitch -gt "0") {
		$loginAccount = "none"
		$ie = new-object -ComObject "InternetExplorer.Application"
		$ie.visible = $true
		$ie.navigate("https://www.humblebundle.com/login?hmb_source=navbar&goto=%2F")
		while ($loginAccount -eq "none" -and $ie.name.length -ne "0") {
		while($ie.Busy -or $ie.ReadyState -ne "4") { Start-Sleep -Milliseconds 100 }
			$allScripts = $ie.Document.getElementsByTagName("script")
			for ($i = 0; $i -lt $allScripts.length; $i++) {
				if ($allScripts[$i].src.length -eq 0 -and $allScripts[$i].text.IndexOf("window.models.user_json") -ne -1) {
					$loginCheck = $allScripts[$i].text.substring($allScripts[$i].text.indexOf("window.models.user_json")).split("`n")[0].replace(" ","");
					if ($loginCheck -ne "window.models.user_json={};") {$loginInfoJSON = $loginCheck.substring($loginCheck.indexOf("={")+1,$loginCheck.length-$loginCheck.indexOf("={")-2); $loginAccount = ($loginInfoJSON | ConvertFrom-Json).email} else {$loginAccount = "none"}
				break;
				}
			}
			Start-Sleep -Seconds 2
		}
		if ($loginSwitch -eq "2") {pause}
		$loginSwitch = 0
	}
}
$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount +" `| Finished"

write-host `nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads `(file not found`): $notFoundErrors`nTotal: $md5Errors
echo "`nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads (file not found): $notFoundErrors`nTotal: $md5Errors" | Out-File $logAll -append
echo "`nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads (file not found): $notFoundErrors`nTotal: $md5Errors" | Out-File $logError -append

pause
