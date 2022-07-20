#Requires -Version 3.0
### HB DRM-Free bulk downloader 0.4.2 by https://github.com/mmarcincin
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
#default _simpleauth_sess cookie text
$authSessCookie = "none"
#0 means if preferred label is set and not found at specific book/game, it'll download first label/extension in the list, 1 means pref labels only
$strictSwitch = 0
#1 means it'll download the first labels/extension found in the list, 0 means it'll download all labels/extensions in the list
$prefSwitch = 1
#0 means it follows $includeDownPlatforms and $excludeDownPlatforms, 1 means it ignores both
$allDownPlatforms = 0
$includeDownPlatformsD = "windows,audio,video,ebook,others | "
$includeDownPlatforms = $includeDownPlatformsD
$excludeDownPlatforms = ""
#md5 hash check of files enabled
$md5Switch = 1
#md5 hash check of previously stored/downloaded files enabled
$md5sSwitch = 1
#1 downloads the file itself, 0 is for bittorent file
$directDownloadSwitch = 1
#0 means the downloads will save to fully qualified name for bundles, 1 means bundle name is represented by key value from purchase link
$saveForkBundleSwitch = 0
#if $fileLimitLengthCheck is 0 conditional filename shortening is disabled
$folderTitleLengthCheck = 0
$fileLimitLengthCheck = 0
#not implemented - for future use
$genListSwitch = 0
###

$bundleLog = 0
$titleLog = 0
$bundleErrorLog = 0
$titleErrorLog = 0
$md5Errors = 0
$notFoundErrors = 0

write-host HB DRM-Free bulk downloader 0.4.2 by https://github.com/mmarcincin
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
$authCheck = Get-Content $links | Where {$_.indexOf("^") -eq "0"} | Measure-Object -Line | Select -ExpandProperty Lines
$authSampleCheck = Get-Content $links | Where {$_.indexOf("^Override") -eq "0"} | Measure-Object -Line | Select -ExpandProperty Lines

if ($emptyCheck -eq 0) { echo "^<Override this with your '_simpleauth_sess' cookie from your browser. More info in README.>" | Out-File $links -append }
if ($downloadCount -eq 0 -and ($authCheck -eq 0 -or $authSampleCheck -gt 0)) { 
	write-host "`nIn order to access your DRM-free files you have to save '_simpleauth_sess' cookie from your browser."
	write-host "a) developer console option"
	write-host "   1. navigate to humblebundle.com in your browser, open developer console using shift+i/shift+c"
	write-host "   2. at the top you can see tabs like Elements, Console, ... open application tab (if not visible click on >>)"
	write-host "   3. select cookies and then humblebundle.com, filter cookies by '_simpleauth_sess'"
	write-host "   4. click on it and copy Cookie Value shown below into links.txt (best entered as first line) in format: ^text`n"
	write-host "b) browser settings option"
	write-host "   1. copy this link into browser:"
	write-host "     For Opera: opera://settings/cookies/detail?site=humblebundle.com"
	write-host "     For Google Chrome: chrome://settings/cookies/detail?site=humblebundle.com"
	write-host "   2. find _simpleauth_sess cookie and copy the cookie text in field Content into links.txt (best entered as first line) in format: ^text"
	write-host "`nIf you'd like to navigate to cookies yourself, check out README file.`n"
}

Get-Content $links | Foreach-Object {
	if ($_.indexOf("https://www.humblebundle.com/downloads?key=") -eq "0") {
		$currentDownload++
		$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount
		
		$requestUri = $_.trim()
		
		$requestLink = $requestUri.split("#")[0]
		$prefLabel = $requestUri.split("#")[1]
		if ($prefLabel.length -eq 0) { $prefLabel = $prefGLabels}
		if (($prefLabel.length -eq 0) -and ($prefGLabels.length -eq 0)) { $prefLabel = "none" }
		$prefLabels = $prefLabel.split(",")
		write-host `nlink: $requestLink
		if ($prefSwitch -eq "1") { write-host preferred labels: $prefLabel } else { if ($prefSwitch -eq "0") { write-host download labels: $prefLabel }}
		if ($strictSwitch -eq "0") { write-host strict mode: disabled } else { if ($strictSwitch -eq "1") { write-host strict mode: enabled }}
		if ($md5Switch -eq "1") { write-host MD5 file check: enabled } else { if ($md5Switch -eq "0") { write-host MD5 file check: disabled }}
		if ($md5Switch -eq "1") { if ($md5sSwitch -eq "1") { write-host MD5 stored file check: enabled } else { if ($md5sSwitch -eq "0") { write-host MD5 stored file check: disabled }}}
		if ($directDownloadSwitch -eq "1") { write-host download method: direct } else { write-host download method: bittorent file }
		if ($saveForkBundleSwitch -eq "0") { write-host bundle name folder: full name } else { write-host bundle name folder: key value from purchase link }
		if ($fileLimitLengthCheck -eq "0") { write-host "conditional filename shortening: disabled" } else { write-host "conditional filename shortening:`nif title length is longer than $folderTitleLengthCheck, shorten filename length including extension to $fileLimitLengthCheck" }
		if ($allDownPlatforms -ne "1") { write-host "included sections: $($includeDownPlatforms)" } else { write-host "included sections: all sections" }
		if ($allDownPlatforms -ne "1") { write-host "excluded sections: $($excludeDownPlatforms)" } else { write-host "excluded sections: disabled" }
		
		
		#Start-Sleep -Seconds 1
		#pause
		
		$bundleInfoLink = "https://www.humblebundle.com/api/v1/order/" + $requestLink.substring($requestLink.indexOf("?key=") + 5)
		#$bundleInfoLink = "https://www.humblebundle.com/api/v1/order/PVSAUaSVvFds23Px"
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession    
		$cookie = New-Object System.Net.Cookie 
		
		$cookie.Name = "_simpleauth_sess"
		$cookie.Value = $authSessCookie
		$cookie.Domain = "humblebundle.com"
		
		$session.Cookies.Add($cookie);

		try
		{
			$bundleInfo = Invoke-WebRequest $bundleInfoLink -WebSession $session -TimeoutSec 900
			# This will only execute if the Invoke-WebRequest is successful.
			$statusCode = $bundleInfo.StatusCode
		}
		catch
		{
			$statusCode = $_.Exception.Response.StatusCode.value__
		}
		#$statusCode
		
		if ($statusCode -eq 200) {
			$bundleInfoJson = $bundleInfo | ConvertFrom-Json
			if ($saveForkBundleSwitch -eq 0) {
				$bundleName = $bundleInfoJson.product.human_name 
				$bundleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($bundleName))
				$bundleTitle = $bundleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
				$bundleTitle = $bundleTitle -replace '/', '_'
			} else {
				$bundleTitle = $bundleInfoJson.gamekey
			}
			$bundleTitle = $bundleTitle.trim()
		} else {
			$bundleInfo = ""
			$bundleInfoJson = ""
			if ($statusCode -eq 401) {
				$bundleTitle = "You are currently using no '_simpleauth_sess' cookie or the purchase link is not associated with your account."
			} else {
				if ($statusCode -eq 404) {
					$bundleTitle = "Humble Bundle purchase link you provided is not valid, check for copy/typing errors."
				}
			}
		}
		
		$hiddenDRMFreeEntries = 0
		if ($bundleInfoJson.subproducts.length -gt 0) {
			for ($i = 0; $i -lt $bundleInfoJson.subproducts.length; $i++) {
				if ($bundleInfoJson.subproducts[$i].library_family_name -eq "hidden") {
					$hiddenDRMFreeEntries++
				}
			}
		}
		#$hiddenDRMFreeEntries
		
		write-host ==============================================================
		write-host $currentDownload "/" $downloadCount - $bundleTitle
		write-host $requestLink
		write-host --------------------------------------------------------------
		$bundleLog = 0
		$bundleErrorLog = 0
		
		if (($statusCode -eq 200) -and (($bundleInfoJson.subproducts.length -eq 0) -or ($hiddenDRMFreeEntries -eq $bundleInfoJson.subproducts.length))) {
			write-host "`nNo DRM-Free content detected for this bundle.`n"
		}
		if ($statusCode -eq 401) {
			write-host "`nIn order to access your DRM-free files you have to save '_simpleauth_sess' cookie from your browser."
			write-host "a) developer console option"
			write-host "   1. navigate to humblebundle.com in your browser, open developer console using shift+i/shift+c"
			write-host "   2. at the top you can see tabs like Elements, Console, ... open application tab (if not visible click on >>)"
			write-host "   3. select cookies and then humblebundle.com, filter cookies by '_simpleauth_sess'"
			write-host "   4. click on it and copy Cookie Value shown below into links.txt (best entered as first line) in format: ^text`n"
			write-host "b) browser settings option"
			write-host "   1. copy this link into browser:"
			write-host "     For Opera: opera://settings/cookies/detail?site=humblebundle.com"
			write-host "     For Google Chrome: chrome://settings/cookies/detail?site=humblebundle.com"
			write-host "   2. find _simpleauth_sess cookie and copy the cookie text in field Content into links.txt (best entered as first line) in format: ^text"
			write-host "`nIf you'd like to navigate to cookies yourself, check out README file.`n"
			write-host "Press ESC if you want to add/edit the '_simpleauth_sess' cookie (close the script)."
			write-host "Press any key except ESC if you want to continue without adding '_simpleauth_sess cookie' (continue the script)."
			$key = [console]::ReadKey()
			if ($key.key -eq [ConsoleKey]::Escape) { Exit}
		}

		$titleList = New-Object System.Collections.ArrayList
		$downTitleList = New-Object System.Collections.ArrayList
		$downLinkList = New-Object System.Collections.ArrayList
		$curLabelList = New-Object System.Collections.ArrayList
		$md5List = New-Object System.Collections.ArrayList
		$publisherList = New-Object System.Collections.ArrayList
		
		### link collection section
		$hbCounter = 0
		$hb = $bundleInfoJson.subproducts
		for ($i = 0; $i -lt $hb.length; $i++) {
			$curTitle = $hb[$i]
			$humbleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($curTitle.human_name))
			$humbleTitle = $humbleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
			$humbleTitle = $humbleTitle -replace '/', '_'
			$humbleTitle = $humbleTitle.trim()
			#$humblePublisher = $curTitle.getElementsByClassName("subtitle")[0].getElementsByTagName("a")[0].innerText
			
			$titleList.Add($humbleTitle) > $null
			#$publisherList.Add($humblePublisher) > $null
			
			$downloadsArray = $curTitle.downloads
			for ($s = 0; $s -lt $downloadsArray.length; $s++) {
				if (($allDownPlatforms -eq 1) -or (($includeDownPlatforms.indexOf($downloadsArray[$s].platform) -ne -1) -and ($excludeDownPlatforms.indexOf($downloadsArray[$s].platform) -eq -1))) {
					$downAlready = -1
					if ($downloadsArray[$s].download_struct.url.web.length -gt 0) {
						$downLabels = $downloadsArray[$s].download_struct
						$downLabelsLength = $downloadsArray[$s].download_struct.length; if ($downLabelsLength -eq $null) { $downLabelsLength = 1 }
						for ($j = 0; $j -lt $prefLabels.length; $j++) {
							for ($k = $downLabelsLength-1; $k -ge 0; $k--) {
								if (($downAlready -eq "1") -and ($prefSwitch -eq "1") -and ($prefLabels[0].ToLower().trim() -ne "none")) { break; }
								$curLabel = $downLabels[$k].name
								if (($curLabel.ToLower() -eq $prefLabels[$j].ToLower().trim()) -or ($prefLabels[0].ToLower().trim() -eq "none")) {
									$downAlready = 1
									
									if ($directDownloadSwitch -eq 1) {$downLink = $downLabels[$k].url.web} else {$downLink = $downLabels[$k].url.bittorrent}
									$md5c = $downLabels[$k].md5
									$md5ct = $md5c.trim()
									$downName = $downLink.split("?")[0].split("/")
									$downTitle = $downName[$downName.length-1].trim()
									if (($fileLimitLengthCheck -gt 0) -and ($folderTitleLengthCheck -ge 0) -and ($humbleTitle.length -gt $folderTitleLengthCheck)) {
										$downTitleExt = $downTitle.substring($downTitle.lastIndexOf("."))
										$downTitle = $downTitle.substring(0, $downTitle.lastIndexOf("."))
										if (($downTitle.length + $downTitleExt.length) -gt $fileLimitLengthCheck) {
											$downTitle = $downTitle.substring(0, $fileLimitLengthCheck - $downTitleExt.length) + $downTitleExt
										}
									}
									
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
							$curLabel = $downLabels[$downLabelsLength-1].name
							if ($directDownloadSwitch -eq 1) { $downLink = $downLabels[$downLabelsLength-1].url.web } else { $downLink = $downLabels[$downLabelsLength-1].url.bittorrent }
							$md5c = $downLabels[$downLabelsLength-1].md5
							$md5ct = $md5c.trim()
							$downName = $downLink.split("?")[0].split("/")
							$downTitle = $downName[$downName.length-1].trim()
							if (($fileLimitLengthCheck -gt 0) -and ($folderTitleLengthCheck -gt 0) -and ($humbleTitle.length -gt $folderTitleLengthCheck)) {
								$downTitleExt = $downTitle.substring($downTitle.lastIndexOf("."))
								$downTitle = $downTitle.substring(0, $downTitle.lastIndexOf("."))
								if (($downTitle.length + $downTitleExt.length) -gt $fileLimitLengthCheck) {
									$downTitle = $downTitle.substring(0, $fileLimitLengthCheck - $downTitleExt.length) + $downTitleExt
								}
							}
							
							$downTitleList.Add($downTitle) > $null
							$downLinkList.Add($downLink) > $null
							$curLabelList.Add($curLabel) > $null
							$md5List.Add($md5ct) > $null
						}
					}
				}
			}
			if ($curTitle.downloads.download_struct.url.web.length -gt 0) {
				$downTitleList.Add($hbCounter) > $null
				$downLinkList.Add($hbCounter) > $null
				$curLabelList.Add($hbCounter) > $null
				$md5List.Add($hbCounter) > $null
				$hbCounter++
			}
		}
	
		#$downTitleList
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
					if (($md5Switch -eq 1 -or !(Test-Path $downDest)) -and $directDownloadSwitch -eq 1) {
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
					if ($md5Switch -eq 1 -and $md5sSwitch -eq 1 -and $directDownloadSwitch -eq 1) {
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
			if ($_.indexOf("+") -eq "1") {
				$includeDownPlatforms = $includeDownPlatformsD + $_.split("+")[1].toLower().trim()
			} else {
				if ($_.indexOf("-") -eq "1") {
					$excludeDownPlatforms = $_.split("-")[1].toLower().trim()
				} else {
					$includeDownPlatformsCheck = $_.split("@")[1].toLower().trim()
					switch ($includeDownPlatformsCheck) {
						"all" {$allDownPlatforms = 1; break}
						"all-" {$allDownPlatforms = 0; break}
						default {$includeDownPlatforms = $includeDownPlatformsCheck; break}
					}
				}
			}
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
			$directDown = $_.split("*")[1].split(",")
			for ($i = 0; $i -lt $directDown.length; $i++) {
			switch ($directDown[$i].toLower().trim()) {
				"direct" {$directDownloadSwitch = 1; break}
				"bittorrent" {$directDownloadSwitch = 0; break}
			}
			}
		}
		if ($_.indexOf("^") -eq "0") {
			$authSessCookie = $_.split("^")[1].trim()
		}
		if ($_.indexOf(";") -eq "0") {
		}
		if ($_.indexOf("~") -eq "0") {
			$saveFork = $_.split("~")[1].split(",")
			for ($i = 0; $i -lt $saveFork.length; $i++) {
				$saveFork[$i] = $saveFork[$i].toLower().trim()
				if (($saveFork[$i].indexOf("if_title-") -eq 0) -and ($saveFork[$i].indexOf("_file-") -ne -1)) {
					$folderTitleLengthCheck = $($saveFork[$i].split("_")[1].split("-")[1])/1
					$fileLimitLengthCheck = $($saveFork[$i].split("_")[2].split("-")[1])/1
				}
			switch ($saveFork[$i]) {
				"fullbundle" {$saveForkBundleSwitch = 0; break}
				"keybundle" {$saveForkBundleSwitch = 1; break}
			}
			}
		}
	}
}
$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount +" `| Finished"

write-host `nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads `(file not found`): $notFoundErrors`nTotal: $md5Errors
echo "`nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads (file not found): $notFoundErrors`nTotal: $md5Errors" | Out-File $logAll -append
echo "`nError Summary:`n----------------------`nFailed file integrity `(MD5`) checks: $($md5Errors-$notFoundErrors)`nUnsuccessful downloads (file not found): $notFoundErrors`nTotal: $md5Errors" | Out-File $logError -append

Write-Host "Press Enter to Exit..."
Do {
	$Key = [Console]::ReadKey($True)	
} While ( $Key.Key -NE [ConsoleKey]::Enter )
