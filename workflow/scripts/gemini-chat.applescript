property geminiAppName : "Gemini"
property geminiProcessName : "Gemini"
property logPath : ((path to home folder as text) & "Library:Logs:alfred-gemini.log")
property lockPath : "/tmp/alfred-gemini.lock"

on run argv
	set hasLock to false
	try
		set hasLock to my acquireLock()
		if hasLock is false then return
		
		set modeName to "normal"
		if (count of argv) > 0 then set modeName to item 1 of argv
		
		my logMessage("start mode=" & modeName)
		my activateGemini()
		
		if modeName is "temporary" then
			my openTemporaryChat()
		else
			my openNewChat()
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
	my waitForGeminiProcess(3)
	delay 0.1
end activateGemini

on openNewChat()
	tell application "System Events"
		tell application process geminiProcessName
			set frontmost to true
			keystroke "n" using {command down}
		end tell
	end tell
	my logMessage("shortcut new_chat")
end openNewChat

on openTemporaryChat()
	tell application "System Events"
		tell application process geminiProcessName
			set frontmost to true
			keystroke "n" using {command down, shift down}
		end tell
	end tell
	my logMessage("shortcut temporary_chat")
end openTemporaryChat

on waitForGeminiProcess(timeoutSeconds)
	set deadline to (current date) + timeoutSeconds
	repeat
		tell application "System Events"
			if exists application process geminiProcessName then return
		end tell
		
		if (current date) > deadline then error "Could not find Gemini process"
		delay 0.1
	end repeat
end waitForGeminiProcess

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
