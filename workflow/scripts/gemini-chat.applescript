property geminiAppName : "Gemini"
property geminiProcessName : "Web App"
property geminiWindowTitle : "Gemini"
property logPath : ((path to home folder as text) & "Library:Logs:alfred-gemini.log")
property lockPath : "/tmp/alfred-gemini.lock"
property temporaryButtonCachePath : "/tmp/alfred-gemini-temporary-button-cache"

on run argv
	set hasLock to false
	try
		set hasLock to my acquireLock()
		if hasLock is false then return
		
		set modeName to "normal"
		if (count of argv) > 0 then set modeName to item 1 of argv
		set newChatLabel to string id {21457, 36215, 26032, 23545, 35805}
		set temporaryChatLabel to string id {20020, 26102, 23545, 35805}
		
		my logMessage("start mode=" & modeName)
		my activateGemini()
		my openNewChat()
		
		if modeName is "temporary" then
			set geminiWindow to my waitForGeminiWindow(3)
			if my clickTemporaryChatFromCache(geminiWindow) is false then
				my clickNamedElement(geminiWindow, temporaryChatLabel, "AXButton", 3, true)
			end if
		end if
		my logMessage("done mode=" & modeName)
		my releaseLock()
	on error errMsg number errNum
		my logMessage("error " & errNum & ": " & errMsg)
		if hasLock then my releaseLock()
		display notification errMsg with title "Alfred Gemini"
		error errMsg number errNum
	end try
end run

on activateGemini()
	tell application geminiAppName to activate
	delay 0.25
end activateGemini

on openNewChat()
	tell application "System Events"
		tell application process geminiProcessName
			keystroke "o" using {command down, shift down}
		end tell
	end tell
	my logMessage("shortcut new_chat")
	delay 0.2
end openNewChat

on clickTemporaryChatFromCache(geminiWindow)
	try
		set cachedOffset to my readTemporaryButtonCache()
		if cachedOffset is missing value then
			my logMessage("temporary_chat cache miss")
			return false
		end if
		
		tell application "System Events"
			set windowPosition to position of geminiWindow
			set clickX to (item 1 of windowPosition) + (item 1 of cachedOffset)
			set clickY to (item 2 of windowPosition) + (item 2 of cachedOffset)
			click at {clickX, clickY}
		end tell
		my logMessage("cached temporary_chat click")
		delay 0.25
		if my temporaryChatButtonStillVisible(geminiWindow) is false then return true
		my logMessage("cached temporary_chat still visible; fallback")
	on error errMsg
		my logMessage("cached temporary_chat failed: " & errMsg)
	end try
	return false
end clickTemporaryChatFromCache

on isTemporaryChatOpenFast()
	tell application "System Events"
		try
			set geminiProcess to my findGeminiProcess()
			if geminiProcess is missing value then return false
			set geminiWindow to my findGeminiWindow(geminiProcess)
			if geminiWindow is missing value then return false
			set windowTitle to title of geminiWindow as text
			if windowTitle is geminiWindowTitle then return true
		end try
	end tell
	return false
end isTemporaryChatOpenFast

on temporaryChatButtonStillVisible(geminiWindow)
	set temporaryChatLabel to string id {20020, 26102, 23545, 35805}
	tell application "System Events"
		try
			set matches to UI elements of (entire contents of geminiWindow) whose role is "AXButton" and (name is temporaryChatLabel or description is temporaryChatLabel)
			if (count of matches) > 0 then return true
		end try
	end tell
	return false
end temporaryChatButtonStillVisible

on waitForGeminiWindow(timeoutSeconds)
	set deadline to (current date) + timeoutSeconds
	repeat
		tell application "System Events"
			set geminiProcess to my findGeminiProcess()
			if geminiProcess is not missing value then
				set frontmost of geminiProcess to true
				set geminiWindow to my findGeminiWindow(geminiProcess)
				if geminiWindow is not missing value then return geminiWindow
			end if
		end tell
		
		if (current date) > deadline then error "Could not find Gemini window"
		delay 0.1
	end repeat
end waitForGeminiWindow

on clickNamedElement(geminiWindow, targetName, targetRole, timeoutSeconds, shouldCacheTemporaryButton)
	set deadline to (current date) + timeoutSeconds
	repeat
		tell application "System Events"
			set targetElement to my findElementFast(geminiWindow, targetName, targetRole)
			if targetElement is missing value then set targetElement to my findElement(geminiWindow, targetName, targetRole)
			if targetElement is not missing value then
				if shouldCacheTemporaryButton then my cacheTemporaryButtonPosition(geminiWindow, targetElement)
				my logMessage("click role=" & targetRole & " control=" & my logControlName(targetName))
				click targetElement
				delay 0.25
				return
			end if
		end tell
		
		if (current date) > deadline then error "Could not find Gemini control: " & my logControlName(targetName)
		delay 0.1
	end repeat
end clickNamedElement

on readTemporaryButtonCache()
	try
		set cacheText to do shell script "cat " & quoted form of temporaryButtonCachePath
		set oldDelimiters to AppleScript's text item delimiters
		set AppleScript's text item delimiters to ","
		set offsetX to item 1 of text items of cacheText as integer
		set offsetY to item 2 of text items of cacheText as integer
		set AppleScript's text item delimiters to oldDelimiters
		return {offsetX, offsetY}
	on error
		try
			set AppleScript's text item delimiters to oldDelimiters
		end try
		return missing value
	end try
end readTemporaryButtonCache

on cacheTemporaryButtonPosition(geminiWindow, temporaryButton)
	try
		tell application "System Events"
			set windowPosition to position of geminiWindow
			set buttonPosition to position of temporaryButton
			set buttonSize to size of temporaryButton
			set offsetX to ((item 1 of buttonPosition) - (item 1 of windowPosition)) + ((item 1 of buttonSize) div 2)
			set offsetY to ((item 2 of buttonPosition) - (item 2 of windowPosition)) + ((item 2 of buttonSize) div 2)
		end tell
		do shell script "printf %s " & quoted form of ((offsetX as text) & "," & (offsetY as text)) & " > " & quoted form of temporaryButtonCachePath
		my logMessage("cache temporary_chat offset=" & offsetX & "," & offsetY)
	end try
end cacheTemporaryButtonPosition

on findGeminiProcess()
	tell application "System Events"
		try
			repeat with candidateProcess in application processes whose name is geminiProcessName
				if my findGeminiWindow(candidateProcess) is not missing value then return candidateProcess
			end repeat
		end try
	end tell
	return missing value
end findGeminiProcess

on findGeminiWindow(candidateProcess)
	tell application "System Events"
		try
			repeat with candidateWindow in windows of candidateProcess
				try
					set windowTitle to title of candidateWindow as text
				on error
					try
						set windowTitle to name of candidateWindow as text
					on error
						set windowTitle to ""
					end try
				end try
				if windowTitle contains geminiWindowTitle and my isUsableGeminiWindow(candidateWindow) then return candidateWindow
			end repeat
		end try
	end tell
	return missing value
end findGeminiWindow

on isUsableGeminiWindow(candidateWindow)
	tell application "System Events"
		try
			set windowSize to size of candidateWindow
			if (item 1 of windowSize) > 600 and (item 2 of windowSize) > 400 then return true
		end try
	end tell
	return false
end isUsableGeminiWindow

on findElementFast(rootElement, targetName, targetRole)
	tell application "System Events"
		try
			set matches to UI elements of rootElement whose role is targetRole and (name is targetName or description is targetName)
			if (count of matches) > 0 then return item 1 of matches
		end try
		
		try
			set matches to UI elements of (entire contents of rootElement) whose role is targetRole and (name is targetName or description is targetName)
			if (count of matches) > 0 then return item 1 of matches
		end try
	end tell
	return missing value
end findElementFast

on findElement(rootElement, targetName, targetRole)
	tell application "System Events"
		try
			set elementRole to role of rootElement as text
		on error
			set elementRole to ""
		end try
		
		try
			set elementName to name of rootElement as text
		on error
			set elementName to ""
		end try
		
		try
			set elementDescription to description of rootElement as text
		on error
			set elementDescription to ""
		end try
		
		if elementRole is targetRole and (elementName is targetName or elementDescription is targetName) then
			return rootElement
		end if
		
		try
			repeat with childElement in UI elements of rootElement
				set foundElement to my findElement(childElement, targetName, targetRole)
				if foundElement is not missing value then return foundElement
			end repeat
		end try
	end tell
	
	return missing value
end findElement

on logControlName(targetName)
	if targetName is (string id {21457, 36215, 26032, 23545, 35805}) then return "new_chat"
	if targetName is (string id {20020, 26102, 23545, 35805}) then return "temporary_chat"
	return "unknown"
end logControlName

on logMessage(messageText)
	set logLine to ((current date) as text) & " " & messageText & linefeed
	try
		set logFile to open for access file logPath with write permission
		write logLine to logFile starting at eof
		close access logFile
	on error
		try
			close access file logPath
		end try
	end try
end logMessage

on acquireLock()
	try
		do shell script "if [ -d " & quoted form of lockPath & " ]; then now=$(date +%s); mtime=$(stat -f %m " & quoted form of lockPath & " 2>/dev/null || echo 0); if [ $((now-mtime)) -gt 20 ]; then rmdir " & quoted form of lockPath & " 2>/dev/null || true; fi; fi; mkdir " & quoted form of lockPath
		my logMessage("lock acquired")
		return true
	on error
		my logMessage("skip because another run is active")
		return false
	end try
end acquireLock

on releaseLock()
	try
		do shell script "rmdir " & quoted form of lockPath & " 2>/dev/null || true"
		my logMessage("lock released")
	end try
end releaseLock
