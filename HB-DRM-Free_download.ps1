### HB DRM-Free bulk downloader 0.3.1 by https://github.com/mmarcincin
#$links = "links.txt"
$invocation = (Get-Variable MyInvocation).Value
$DownloadDirectory = Split-Path $invocation.MyCommand.Path
### expansion for 260+ length paths \\?\
	$DownloadDirectory = "\\?\"+"$DownloadDirectory"
$links = "$($DownloadDirectory)\links.txt"
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
###

write-host HB DRM-Free bulk downloader 0.3.1 by https://github.com/mmarcincin
write-host `nDownload directory`: $DownloadDirectory`n

$ConCountr1=0
### Test Internet connection
While (!(Test-Connection -ComputerName humblebundle.com -count 1 -Quiet -ErrorAction SilentlyContinue )) {
	Write-Host -ForegroundColor Red "Waiting for internet connection to continue..."
	Start-Sleep -Seconds 10
	$ConCountr1 +=1
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

$currentDownload = 0
$downloadCount = Get-Content $links | Where {$_.indexOf("https://www.humblebundle.com/downloads?key=") -eq "0"} | Measure-Object -Line | Select -ExpandProperty Lines

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

		#$ie.visible = $true
		$ie.silent = $true
		$ie.navigate($requestLink)
		#while($ie.Busy) { Start-Sleep -Milliseconds 100 }
		while($ie.Busy -or $ie.ReadyState -ne "4") { Start-Sleep -Milliseconds 100 }
		
		while (($ie.Document.getElementsByClassName("whitebox-redux").length -eq "0") -or ($ie.Document.getElementsByClassName("whitebox-redux")[0].innerText.length -eq "0") -or ($ie.Document.getElementsByClassName("icn").length -eq "0") -or ($ie.Document.getElementsByClassName("icn")[0].innerText.length -eq "0")) { Start-Sleep -Milliseconds 100 }
		Start-Sleep -Seconds 1
		
		$doc = $ie.Document
		$docTitle = $doc.getElementsByTagName("title")[0].innerText.trim()
		$bundleName = $docTitle.substring(0, $docTitle.lastIndexOf("(") - 1)
		$bundleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($bundleName))
		$bundleTitle = $bundleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
		$bundleTitle = $bundleTitle -replace '/', '_'
		write-host ==============================================================
		write-host $currentDownload "/" $downloadCount - $bundleTitle
		write-host $requestLink
		write-host --------------------------------------------------------------

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
		
		### link collection section
		
		$hb = $doc.getElementsByClassName("icn")
		for ($i = 0; $i -lt $hb.length; $i++) {
			$curTitle = $hb[$i].parentNode
			$humbleName = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($curTitle.getAttribute("data-human-name")))
			$humbleTitle = $humbleName -replace '[^a-zA-Z0-9/_/''/\-/ ]', '_'
			$humbleTitle = $humbleTitle -replace '/', '_'
			
			$titleList.Add($humbleTitle) > $null
			
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
							$downName = $downLink.split("?")[0].split("/")
							$downTitle = $downName[$downName.length-1]
							
							$downTitleList.Add($downTitle) > $null
							$downLinkList.Add($downLink) > $null
							$curLabelList.Add($curLabel) > $null
						}
					}
				}
				
				### if preferred label is not found, it'll download the first label unless %strict global switch is applied
			if (($downAlready -eq "-1") -and ($strictSwitch -eq "0")) {
				write-host `-`- Preferred label not found`, downloading first label `-`-
				$curLabel = $downLabels[$downLabels.length-1].innerHTML
				$downLink = $downLabels[$downLabels.length-1].parentNode.getElementsByClassName("a")[0].href
				$downName = $downLink.split("?")[0].split("/")
				$downTitle = $downName[$downName.length-1]
				
				$downTitleList.Add($downTitle) > $null
				$downLinkList.Add($downLink) > $null
				$curLabelList.Add($curLabel) > $null
			}
			
			$downTitleList.Add($i) > $null
			$downLinkList.Add($i) > $null
			$curLabelList.Add($i) > $null
			}
		}
		$ie.quit()
		
		### download section
		$downIndex = 0
		for ($i = 0; $i -lt $titleList.Count; $i++) {
			$humbleTitle = $titleList[$i]
			$chunkLength = $titleList.Count
			$chunkNumber = $i+1
			$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount +" `| "+ $chunkNumber + "/" + $chunkLength
			
			write-host `n$chunkNumber / $chunkLength - $humbleTitle
			
			for ($j = $downIndex; $j -lt $downTitleList.Count; $j++) {
				if ($downTitleList[$j] -eq $i) { $downIndex = $j + 1; break; }
				
				$downTitle = $downTitleList[$j]
				$downLink = $downLinkList[$j]
				$curLabel = $curLabelList[$j]
				
				write-host $curLabel - $downTitle

				$downDest = "$temp\$bundleTitle\$humbleTitle\$downTitle"

				If (!(Test-Path $DownloadDirectory\$bundleTitle\$humbleTitle\$downTitle)){
					#$wc.DownloadFile($downLink, $downDest)
					If (!(Test-Path $temp\$bundleTitle\$humbleTitle)){ New-Item -ItemType directory -Path $temp\$bundleTitle\$humbleTitle | Out-Null }
						downFile $downLink $downDest
					} else {
						write-host File downloaded already, skipping...
					}
			
			If (!(Test-Path $DownloadDirectory\$bundleTitle\$humbleTitle)){
			New-Item -ItemType directory -Path $DownloadDirectory\$bundleTitle\$humbleTitle | Out-Null
			}
			Move-Item -Path $temp\$bundleTitle\$humbleTitle\* -Destination $DownloadDirectory\$bundleTitle\$humbleTitle
			}
		}
		
	Remove-Item "$temp\*" -Recurse
	write-host ==============================================================
	
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
	}
}
$host.ui.RawUI.WindowTitle = "D: " + $currentDownload + "/" + $downloadCount +" `| Finished"
pause
