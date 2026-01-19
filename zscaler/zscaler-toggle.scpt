-- Zscaler Toggle Script
-- One-click toggle for both Private Access (ZPA) and Internet Security (ZIA)

tell application "System Events"
	-- Check if Zscaler is running
	if not (exists process "Zscaler") then
		display notification "Zscaler is not running" with title "Zscaler Toggle"
		return
	end if
	
	tell process "Zscaler"
		-- Open Zscaler window via menu bar
		click menu bar item 1 of menu bar 2
		delay 0.3
		click menu item "Open Zscaler" of menu 1 of menu bar item 1 of menu bar 2
		delay 0.5
		
		set zpaAction to ""
		set ziaAction to ""
		
		tell window "Zscaler Client Connector"
			-- Toggle Private Access (ZPA) - Button 4
			click button 4
			delay 0.3
		end tell
		
		-- Private Access uses scroll area 1
		tell scroll area 1 of window "Zscaler Client Connector"
			set allButtons to every button
			repeat with btn in allButtons
				set btnName to name of btn
				if btnName is "TURN ON" or btnName is "TURN OFF" then
					click btn
					set zpaAction to btnName
					exit repeat
				end if
			end repeat
		end tell
		
		delay 0.8
		
		-- Handle confirmation popup if it appears (check for sheet or new buttons)
		try
			tell window "Zscaler Client Connector"
				-- Try common confirmation button names
				if exists sheet 1 then
					tell sheet 1
						if exists button "OK" then click button "OK"
						if exists button "Yes" then click button "Yes"
						if exists button "Confirm" then click button "Confirm"
						if exists button "Continue" then click button "Continue"
					end tell
				end if
			end tell
		end try
		
		-- Also check for buttons directly in the window (some popups use this)
		try
			tell window "Zscaler Client Connector"
				set allBtns to every button
				repeat with btn in allBtns
					set btnName to name of btn
					if btnName is "OK" or btnName is "Yes" or btnName is "Confirm" or btnName is "Continue" then
						click btn
						exit repeat
					end if
				end repeat
			end tell
		end try
		
		delay 0.3
		
		tell window "Zscaler Client Connector"
			-- Toggle Internet Security (ZIA) - Button 5
			click button 5
			delay 0.3
		end tell
		
		-- Internet Security uses group 1
		tell group 1 of window "Zscaler Client Connector"
			set allButtons to every button
			repeat with btn in allButtons
				set btnName to name of btn
				if btnName is "TURN ON" or btnName is "TURN OFF" then
					click btn
					set ziaAction to btnName
					exit repeat
				end if
			end repeat
		end tell
		
		delay 0.8
		
		-- Handle confirmation popup for ZIA too
		try
			tell window "Zscaler Client Connector"
				if exists sheet 1 then
					tell sheet 1
						if exists button "OK" then click button "OK"
						if exists button "Yes" then click button "Yes"
						if exists button "Confirm" then click button "Confirm"
						if exists button "Continue" then click button "Continue"
					end tell
				end if
			end tell
		end try
		
		try
			tell window "Zscaler Client Connector"
				set allBtns to every button
				repeat with btn in allBtns
					set btnName to name of btn
					if btnName is "OK" or btnName is "Yes" or btnName is "Confirm" or btnName is "Continue" then
						click btn
						exit repeat
					end if
				end repeat
			end tell
		end try
		
		-- Notify user
		if zpaAction is "TURN ON" then
			display notification "Turned Zscaler ON (ZPA + ZIA)" with title "Zscaler Toggle"
		else
			display notification "Turned Zscaler OFF (ZPA + ZIA)" with title "Zscaler Toggle"
		end if
	end tell
end tell
