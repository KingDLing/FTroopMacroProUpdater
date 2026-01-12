#NoEnv
#SingleInstance Force
CoordMode, Mouse, Screen

; ═══════════════════════════════════════════════════════════
; FTroop Macro Pro - Unit Builder
; ═══════════════════════════════════════════════════════════

global bases := Object()
global isRecording := false
global arrowKeys := Object()
global building := false
global restartCycle := false
global resourceDelay := 0
global gameWindowClass := ""  ; Will be auto-detected
global maxWaitTime := 120000  ; Maximum wait time in ms (2 minutes)

; Update Configuration
global SCRIPT_VERSION := "4.0"
global UPDATE_URL := "https://raw.githubusercontent.com/KingDLing/FTroopMacroProUpdater/main/FTroopMacroPro.ahk"
global VERSION_CHECK_URL := "https://raw.githubusercontent.com/KingDLing/FTroopMacroProUpdater/main/Version.txt"
global SCRIPT_NAME := "FTroopMacroPro.ahk"

; ─────────────────────────────────────────────
; GUI
; ─────────────────────────────────────────────
Gui, Color, 0F0F0F
Gui, Font, s13 Bold cFFD700
Gui, Add, Text, Center w600 y15, FTroop Macro Pro v%SCRIPT_VERSION%

Gui, Font, s9 cEEEEEE Normal
Gui, Add, Button, xm y+20 w580 h45 gBtnExecute, Execute Build (F11)
Gui, Add, Button, xm y+10 w580 h40 gBtnClear, Clear All Bases
Gui, Add, Button, xm y+5 w580 h40 gBtnUpdate, Check for Updates
Gui, Add, Button, xm y+5 w580 h40 gBtnExit, Exit

; Separator line
Gui, Add, Text, xm y+15 w600 h2 0x10 Background404040

Gui, Font, s10 Bold cFFD700
Gui, Add, Text, xm y+15 w600, Base Configuration

Gui, Font, s9 cBlack Normal
Gui, Add, ListView, xm y+10 w600 h150 vBaseListView -Multi Grid BackgroundWhite cBlack, Base #|Units|Delay (s)|Arrows|Remaining
LV_ModifyCol(1, 100, "Base #")
LV_ModifyCol(2, 100, "Units")
LV_ModifyCol(3, 110, "Delay (s)")
LV_ModifyCol(4, 100, "Arrows")
LV_ModifyCol(5, 120, "Remaining")

; Separator line
Gui, Add, Text, xm y+10 w600 h2 0x10 Background404040

Gui, Font, s9 c00BFFF Italic
Gui, Add, Text, xm y+10 w600 vStatusText Center, Press F10 to record bases

Gui, Show, w620, FTroop Macro Pro v%SCRIPT_VERSION%
Gosub, UpdateGUI
return

; ─────────────────────────────────────────────
; Hotkeys
; ─────────────────────────────────────────────

F10::Gosub, BtnRecordBase
F11::Gosub, BtnExecute
Esc::ExitApp
^!F::Gosub, ForceGameFocus  ; Ctrl+Alt+F to force game focus

; Arrow key recording
Up::
Down::
Left::
Right::
    if isRecording
    {
        lastIdx := arrowKeys.MaxIndex()
        if lastIdx is not number
            lastIdx := 0
        arrowKeys[lastIdx + 1] := A_ThisHotkey
        
        count := arrowKeys.MaxIndex()
        if count is not number
            count := 0
        
        ToolTip, Recording arrows: %count% keys pressed`nPress F10 when at base
    }
    Send, {%A_ThisHotkey%}
return

; ═══════════════════════════════════════════════════════════
; AUTO-UPDATE SYSTEM - WITH CACHE BUSTING
; ═══════════════════════════════════════════════════════════

BtnUpdate:
    if building
    {
        MsgBox, Cannot update while building!
        return
    }
    
    GuiControl,, StatusText, Checking for updates...
    
    ; Check for updates
    latestVersion := CheckForUpdates()
    
    if (latestVersion = "ERROR")
    {
        MsgBox, Could not check for updates. Check your internet connection.
        GuiControl,, StatusText, Update check failed
        return
    }
    
    if (latestVersion = SCRIPT_VERSION)
    {
        MsgBox, You have the latest version (%SCRIPT_VERSION%)!
        GuiControl,, StatusText, Already up to date
        return
    }
    
    ; New version available
    MsgBox, 4, Update Available, New version %latestVersion% is available!`n`nCurrent version: %SCRIPT_VERSION%`nLatest version: %latestVersion%`n`nUpdate now?
    
    IfMsgBox No
    {
        GuiControl,, StatusText, Update cancelled
        return
    }
    
    ; Download and update
    GuiControl,, StatusText, Downloading update...
    
    if (DownloadUpdate())
    {
        MsgBox, 4, Update Complete, Update downloaded successfully!`n`nThe script needs to restart to apply the update. Restart now?
        
        IfMsgBox Yes
        {
            ; Restart the script
            Run, %A_ScriptFullPath%
            ExitApp
        }
    }
    else
    {
        MsgBox, Update failed! Please download manually.
        GuiControl,, StatusText, Update failed
    }
return

CheckForUpdates() {
    global VERSION_CHECK_URL
    
    try {
        ; Add timestamp to prevent GitHub caching
        cacheBusterURL := VERSION_CHECK_URL . "?t=" . A_Now
        
        ; Create HTTP request object
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", cacheBusterURL, true)
        whr.Send()
        whr.WaitForResponse()
        
        ; Get response
        versionText := whr.ResponseText
        whr := ""  ; Release object
        
        ; ===== SIMPLE EXTRACTION =====
        ; Remove all non-numeric/dot characters
        versionText := RegExReplace(versionText, "[^\d\.]", "")
        
        ; Trim leading/trailing dots
        versionText := Trim(versionText, ".")
        
        ; If empty, return ERROR
        if (versionText = "")
            return "ERROR"
        
        return versionText
        ; =============================
    }
    catch {
        return "ERROR"
    }
}

DownloadUpdate() {
    global UPDATE_URL, SCRIPT_NAME
    
    try {
        ; Get the script's directory
        scriptDir := A_ScriptDir
        tempFile := scriptDir . "\" . SCRIPT_NAME . ".new"
        backupFile := scriptDir . "\" . SCRIPT_NAME . ".backup"
        
        ; ===== ADD CACHE BUSTER =====
        ; Add timestamp to prevent GitHub caching
        cacheBusterURL := UPDATE_URL . "?t=" . A_Now
        ; ============================
        
        ; Download the updated script WITH cache buster
        URLDownloadToFile, %cacheBusterURL%, %tempFile%
        
        ; Check if download was successful
        FileGetSize, fileSize, %tempFile%
        if (fileSize < 1000) ; Arbitrary minimum size
        {
            FileDelete, %tempFile%
            return false
        }
        
        ; Create backup of current script
        FileCopy, %A_ScriptFullPath%, %backupFile%, 1
        
        ; Replace current script with new one
        FileCopy, %tempFile%, %A_ScriptFullPath%, 1
        
        ; Clean up temp file
        FileDelete, %tempFile%
        
        return true
    }
    catch {
        return false
    }
}

; ═══════════════════════════════════════════════════════════
; UTILITY FUNCTIONS
; ═══════════════════════════════════════════════════════════

EnsureGameFocus() {
    global gameWindowClass
    
    ; If we haven't detected the game window yet, try to detect it
    if (gameWindowClass = "") {
        ; Store current window
        WinGet, currentActive, ID, A
        WinGetClass, currentClass, ahk_id %currentActive%
        
        ; If current window is not our GUI, assume it's the game
        if (currentClass != "AutoHotkeyGUI") {
            gameWindowClass := currentClass
        } else {
            ; Our GUI is active, try to find game window
            WinGet, windowList, List
            Loop, %windowList%
            {
                windowID := windowList%A_Index%
                WinGetClass, windowClass, ahk_id %windowID%
                WinGetTitle, windowTitle, ahk_id %windowID%
                
                ; Skip our own GUI and empty titles
                if (windowClass = "AutoHotkeyGUI" || windowTitle = "")
                    continue
                    
                ; Look for common game window indicators
                if (InStr(windowTitle, "FTroop") || InStr(windowTitle, "Game") || InStr(windowTitle, "Troop")) {
                    gameWindowClass := windowClass
                    break
                }
            }
        }
    }
    
    ; If we have a game window class, ensure it's active
    if (gameWindowClass != "") {
        IfWinNotActive, ahk_class %gameWindowClass%
        {
            WinActivate, ahk_class %gameWindowClass%
            WinWaitActive, ahk_class %gameWindowClass%, , 1.5
            Sleep, 150  ; Allow window to fully activate
            return true  ; Focus was restored
        }
    }
    return false  ; Already had focus or unknown window
}

UpdateStatus(message, isCritical := false) {
    static lastUpdate := 0
    static minUpdateInterval := 250  ; Don't update GUI more than every 250ms
    
    ; Store current time
    currentTime := A_TickCount
    
    ; For critical operations, skip GUI if too recent to avoid timing issues
    if (isCritical && (currentTime - lastUpdate < minUpdateInterval)) {
        ; Use ToolTip only for immediate feedback during critical ops
        ToolTip, %message%
        return
    }
    
    ; Update GUI status (non-critical or enough time has passed)
    GuiControl,, StatusText, %message%
    ToolTip, %message%
    lastUpdate := currentTime
}

ForceGameFocus:
    EnsureGameFocus()
    ToolTip, Game focus restored
    Sleep, 1000
    ToolTip
return

; ═══════════════════════════════════════════════════════════
; UPDATE GUI DISPLAY
; ═══════════════════════════════════════════════════════════
UpdateGUI:
    Gui, 1:Default
    Gui, ListView, BaseListView
    
    LV_Delete()
    
    total := bases.MaxIndex()
    if total is not number
        total := 0
    
    if (total > 0)
    {
        Loop, %total%
        {
            idx := A_Index
            baseObj := bases[idx]
            
            arrowCnt := baseObj.arrows.MaxIndex()
            if arrowCnt is not number
                arrowCnt := 0
            
            unitsVal := baseObj.units
            delayVal := baseObj.delay
            rem := unitsVal
            
            if baseObj.haskey("remaining")
                rem := baseObj.remaining
            
            LV_Add("", idx, unitsVal, delayVal, arrowCnt, rem)
        }
    }
    
    if (total = 0)
        GuiControl,, StatusText, Press F10 to record bases
    else if (building)
        GuiControl,, StatusText, Building in progress...
    else
    {
        resDelayText := ""
        if (resourceDelay > 0)
            resDelayText := " | Resource delay: " resourceDelay "s"
        GuiControl,, StatusText, %total% base(s) recorded%resDelayText% - Press F11 to execute
    }
return

; ═══════════════════════════════════════════════════════════
; RECORD BASE (F10)
; ═══════════════════════════════════════════════════════════
BtnRecordBase:
    if building
    {
        MsgBox, Cannot record while building!
        return
    }
    
    ; Stop arrow recording if active
    if isRecording
    {
        isRecording := false
        ToolTip
    }
    
    ; Get build position
    MouseGetPos, bx, by
    
    ; Count existing bases
    baseNum := bases.MaxIndex()
    if baseNum is not number
        baseNum := 0
    baseNum := baseNum + 1
    
    ; Ask about resource refill delay for Base 1 only
    if (baseNum = 1)
    {
        MsgBox, 4, Resource Refill, Do you need a resource refill delay?`n`nThis will make the script wait at Base 1 after each full cycle through all bases to allow resources to replenish.
        
        IfMsgBox Yes
        {
            InputBox, resourceDelay, Resource Refill Delay, Enter delay in seconds to wait for resources to refill after each full cycle:, , 350, 180, , , , , 0
            if ErrorLevel
            {
                resourceDelay := 0
            }
            else if (resourceDelay < 0)
            {
                MsgBox, Invalid delay - setting to 0
                resourceDelay := 0
            }
        }
        else
        {
            resourceDelay := 0
        }
    }
    
    ; Get units
    InputBox, units, Base %baseNum%, How many units to build at Base %baseNum%?
    if ErrorLevel
    {
        arrowKeys := Object()
        MsgBox, Cancelled
        return
    }
    if (units <= 0)
    {
        arrowKeys := Object()
        MsgBox, Invalid number
        return
    }
    
    ; Get delay
    InputBox, delay, Base %baseNum%, Delay between builds (seconds)?
    if ErrorLevel
    {
        arrowKeys := Object()
        MsgBox, Cancelled
        return
    }
    if (delay < 0)
    {
        arrowKeys := Object()
        MsgBox, Invalid delay
        return
    }
    
    ; Create base object
    newBase := Object()
    newBase.x := bx
    newBase.y := by
    newBase.units := units
    newBase.delay := delay
    newBase.remaining := units
    newBase.arrows := Object()
    
    ; Copy arrow keys
    maxIdx := arrowKeys.MaxIndex()
    if maxIdx is number
    {
        Loop, %maxIdx%
        {
            newBase.arrows[A_Index] := arrowKeys[A_Index]
        }
    }
    
    bases[baseNum] := newBase
    
    ; Update GUI
    Gosub, UpdateGUI
    
    total := bases.MaxIndex()
    if total is not number
        total := 0
    
    arrowCount := newBase.arrows.MaxIndex()
    if arrowCount is not number
        arrowCount := 0
    
    if (baseNum = 1)
    {
        MsgBox, 4, Base 1 Recorded, Base 1 (Starting Position) recorded!`n`nUnits: %units%`nDelay: %delay%s`n`nThis is your HOME BASE.`n`nAdd another base?
        
        IfMsgBox Yes
        {
            arrowKeys := Object()
            isRecording := true
            nextBase := baseNum + 1
            
            ; Click on game screen to restore focus
            Click, %bx%, %by%, 0
            Sleep, 200
            
            MsgBox, From Base %baseNum%, use arrow keys to navigate to Base %nextBase%.`nPress F10 when you arrive.
        }
        else
        {
            arrowKeys := Object()
            MsgBox, Recording complete!`n`n1 base recorded.`n`nPress F11 to start building.
        }
        return
    }
    else
    {
        MsgBox, 4, Base Recorded, Base %baseNum% recorded!`n`nArrows from previous base: %arrowCount%`nUnits: %units%`nDelay: %delay%s`n`nTotal bases: %total%`n`nAdd another base?
    }
    
    IfMsgBox Yes
    {
        arrowKeys := Object()
        isRecording := true
        nextBase := baseNum + 1
        
        ; Click on game screen to restore focus
        Click, %bx%, %by%, 0
        Sleep, 200
        
        MsgBox, From Base %baseNum%, use arrow keys to navigate to Base %nextBase%.`nPress F10 when you arrive.
    }
    else
    {
        arrowKeys := Object()
        
        ; Auto-return to Base 1 by reversing all recorded arrows
        if (baseNum > 1)
        {
            resMsg := ""
            if (resourceDelay > 0)
                resMsg := "`nResource refill delay: " resourceDelay " seconds"
            
            MsgBox, Recording complete!`n`n%total% bases recorded.%resMsg%`n`nReturning to Base 1 automatically...
            Sleep, 1000
            
            ; Reverse arrows from all bases to get back to Base 1
            Loop, %total%
            {
                reverseIdx := total - A_Index + 1
                if (reverseIdx > 0)
                {
                    baseToReverse := bases[reverseIdx]
                    maxArrows := baseToReverse.arrows.MaxIndex()
                    
                    if maxArrows is number
                    {
                        Loop, %maxArrows%
                        {
                            arrowIdx := maxArrows - A_Index + 1
                            arrow := baseToReverse.arrows[arrowIdx]
                            
                            if (arrow = "Up")
                                rev := "Down"
                            else if (arrow = "Down")
                                rev := "Up"
                            else if (arrow = "Left")
                                rev := "Right"
                            else if (arrow = "Right")
                                rev := "Left"
                            
                            SendInput, {%rev%}
                            Sleep, 100
                        }
                    }
                }
            }
            
            Sleep, 500
            MsgBox, Returned to Base 1!`n`nPress F11 to start building.
        }
        else
        {
            MsgBox, Recording complete!`n`n%total% base recorded.`n`nPress F11 to start building.
        }
    }
return

; ═══════════════════════════════════════════════════════════
; EXECUTE (F11) - WITH 3-2-1 COUNTDOWN
; ═══════════════════════════════════════════════════════════
BtnExecute:
    total := bases.MaxIndex()
    if total is not number
        total := 0
    
    if (total = 0)
    {
        MsgBox, No bases recorded!
        return
    }
    
    ; Show summary
    summary := "`nEXECUTION SUMMARY`n`n`n"
    
    Loop, %total%
    {
        baseObj := bases[A_Index]
        arrowCnt := baseObj.arrows.MaxIndex()
        if arrowCnt is not number
            arrowCnt := 0
        summary .= "Base " A_Index ": " baseObj.units " units (" baseObj.delay "s, " arrowCnt " arrows)`n"
    }
    
    summary .= "`n"
    if (resourceDelay > 0)
        summary .= "Resource Refill Delay: " resourceDelay " seconds`n"
    
    summary .= "`nYou should be at Base 1 (starting position).`n`nBegin building?"
    
    MsgBox, 4, Execute, %summary%
    IfMsgBox No
        return
    
    ; Add 3-2-1 countdown to give user time to remove hand from mouse
    UpdateStatus("Starting macro in 3...")
    ToolTip, Starting macro in 3...
    Sleep, 1000
    
    UpdateStatus("Starting macro in 2...")
    ToolTip, Starting macro in 2...
    Sleep, 1000
    
    UpdateStatus("Starting macro in 1...")
    ToolTip, Starting macro in 1...
    Sleep, 1000
    
    ; Brief pause to ensure mouse is clear
    UpdateStatus("Starting now! Remove mouse...")
    ToolTip, Starting now! Remove mouse...
    Sleep, 500
    
    ToolTip  ; Clear tooltip
    
    building := true
    restartCycle := false
    
    ; Track remaining units and last build time for each base
    remaining := Object()
    lastBuildTime := Object()
    
    Loop, %total%
    {
        baseObj := bases[A_Index]
        remaining[A_Index] := baseObj.units
        lastBuildTime[A_Index] := 0
    }
    
    ; Main build loop - continuous cycles through all bases
    Loop
    {
        ; Check for restart request
        if (restartCycle)
        {
            restartCycle := false
            UpdateStatus("Restarting cycle...")
            ToolTip, Restarting cycle - returning to Base 1...
            Sleep, 1000
            
            ; Force wait for Base 1 timer before continuing
            if (lastBuildTime[1] > 0)
            {
                base1Obj := bases[1]
                buildTimeMs := base1Obj.delay * 1000
                
                ; Calculate wait time with wrap-around protection
                currentTime := A_TickCount
                timeSinceLastBuild := currentTime - lastBuildTime[1]
                
                ; Handle A_TickCount wrap-around
                if (timeSinceLastBuild < 0)
                    timeSinceLastBuild := (4294967295 - lastBuildTime[1]) + currentTime
                
                timeLeft := buildTimeMs - timeSinceLastBuild
                
                ; Safety check - if timeLeft is unreasonable, don't wait
                if (timeLeft > (buildTimeMs + 10000) || timeLeft < 0)
                    timeLeft := 0
                
                if (timeLeft > 0)
                {
                    secondsLeft := Round(timeLeft / 1000)
                    UpdateStatus("Waiting for Base 1: " . secondsLeft . "s")
                    
                    ; Real-time countdown
                    startTime := A_TickCount
                    targetTime := startTime + timeLeft
                    lastDisplayed := secondsLeft
                    
                    while (A_TickCount < targetTime && !restartCycle)
                    {
                        currentTime := A_TickCount
                        timeRemaining := targetTime - currentTime
                        
                        if (timeRemaining > 0)
                        {
                            secondsRemaining := Round(timeRemaining / 1000)
                            
                            ; Update only when second count changes
                            if (secondsRemaining != lastDisplayed)
                            {
                                UpdateStatus("Waiting for Base 1: " . secondsRemaining . "s")
                                lastDisplayed := secondsRemaining
                            }
                        }
                        
                        Sleep, 100  ; Short sleep for responsiveness
                        
                        if (restartCycle)
                            break
                    }
                    
                    if (!restartCycle)
                        UpdateStatus("Base 1 ready!")
                }
            }
            
            UpdateStatus("Restarting cycle...")
            ToolTip, Base 1 ready! Restarting cycle...
            Sleep, 1000
            continue
        }
        
        ; Check if all done
        done := true
        Loop, %total%
        {
            if (remaining[A_Index] > 0)
                done := false
        }
        
        if done
            break
        
        ; Check if Base 1 is ready (this gates the entire cycle)
        if (remaining[1] > 0)
        {
            currentTime := A_TickCount
            if (lastBuildTime[1] > 0)
            {
                base1Obj := bases[1]
                buildTimeMs := base1Obj.delay * 1000
                
                ; Handle A_TickCount wrap-around properly
                timeSinceLastBuild := currentTime - lastBuildTime[1]
                if (timeSinceLastBuild < 0)
                {
                    ; A_TickCount has wrapped (happens every ~49.7 days)
                    ; Recalculate using maximum DWORD value
                    timeSinceLastBuild := (4294967295 - lastBuildTime[1]) + currentTime
                }
                
                if (timeSinceLastBuild < buildTimeMs)
                {
                    ; Base 1 not ready, wait
                    timeLeft := buildTimeMs - timeSinceLastBuild
                    
                    ; Safety check - if timeLeft is unreasonable, reset timer
                    if (timeLeft > (buildTimeMs + 10000) || timeLeft < 0)  ; More than 10 seconds over expected or negative
                    {
                        ; Timing calculation error - reset and continue
                        lastBuildTime[1] := currentTime
                        UpdateStatus("Timer adjusted - continuing", true)
                        Sleep, 500
                        continue
                    }
                    
                    ; Cap the wait time to maximum allowed
                    if (timeLeft > maxWaitTime)
                        timeLeft := maxWaitTime
                    
                    secondsLeft := Round(timeLeft / 1000)
                    
                    if (secondsLeft > 0)
                    {
                        UpdateStatus("Waiting for Base 1: " . secondsLeft . "s", true)
                        
                        ; Real-time countdown with 1-second updates
                        startTime := A_TickCount
                        targetTime := startTime + timeLeft
                        lastDisplayedSecond := secondsLeft
                        
                        while (A_TickCount < targetTime && !restartCycle)
                        {
                            ; Calculate remaining time
                            currentTime := A_TickCount
                            timeRemaining := targetTime - currentTime
                            
                            ; Update every second or if significant time change
                            if (timeRemaining > 0)
                            {
                                secondsRemaining := Round(timeRemaining / 1000)
                                
                                ; Only update if the second count changed
                                if (secondsRemaining != lastDisplayedSecond)
                                {
                                    UpdateStatus("Waiting for Base 1: " . secondsRemaining . "s", true)
                                    lastDisplayedSecond := secondsRemaining
                                }
                            }
                            
                            ; Sleep for a short time but check frequently
                            Sleep, 100  ; Check 10 times per second
                            
                            ; Quick check for restart request
                            if (restartCycle)
                            {
                                UpdateStatus("Restart requested...")
                                break
                            }
                        }
                        
                        ; Final update when done
                        if (!restartCycle)
                            UpdateStatus("Base 1 ready!", true)
                        
                        ; If restart was requested during wait, handle it
                        if (restartCycle)
                            continue
                    }
                    continue
                }
            }
        }
        
        ; Go through bases sequentially: 1 → 2 → 3 → ... → N
        Loop, %total%
        {
            i := A_Index
            baseObj := bases[i]
            
            ; Skip if no units left at this base
            if (remaining[i] <= 0)
                continue
            
            ; Navigate to base (all bases except Base 1)
            if (i > 1)
            {
                UpdateStatus("Going to Base " . i, true)
                
                ; Ensure game has focus before navigation
                EnsureGameFocus()
                Sleep, 150  ; Reduced consistent delay
                
                ; Send arrow keys FROM PREVIOUS BASE
                maxArrows := baseObj.arrows.MaxIndex()
                if maxArrows is number
                {
                    Loop, %maxArrows%
                    {
                        arrow := baseObj.arrows[A_Index]
                        
                        ; Quick focus check every few keys
                        if (Mod(A_Index, 3) = 0)
                            EnsureGameFocus()
                        
                        SendInput, {%arrow%}
                        Sleep, 100  ; Keep consistent timing
                    }
                }
                
                Sleep, 500  ; Reduced consistent delay
            }
            
            ; Build with wiggle
            remCount := remaining[i]
            UpdateStatus("Building at Base " . i . " - Remaining: " . remCount, true)
            
            ; Ensure focus before clicking
            EnsureGameFocus()
            
            ; Wiggle mouse to activate build window
            MouseMove, baseObj.x + 5, baseObj.y + 5, 0
            Sleep, 50
            MouseMove, baseObj.x, baseObj.y, 0
            Sleep, 100
            
            ; Final focus check right before click
            EnsureGameFocus()
            Click
            
            ; Mark as built
            remaining[i] := remaining[i] - 1
            lastBuildTime[i] := A_TickCount
            
            ; Update GUI (non-critical timing)
            baseObj.remaining := remaining[i]
            if (Mod(i, 2) = 0 || i = 1)  ; Update every other base to reduce GUI overhead
                Gosub, UpdateGUI
            
            ; Wait 2 seconds after initiating build
            Sleep, 2000
        }
        
        ; After reaching last base, return to Base 1 by reversing all paths
        UpdateStatus("Returning to Base 1...", true)
        EnsureGameFocus()
        Sleep, 200  ; Reduced delay
        
        ; Reverse from last base back through all bases to Base 1
        Loop, %total%
        {
            reverseIdx := total - A_Index + 1
            
            if (reverseIdx < 1)
                break
            
            ; Don't reverse Base 1 (it has no arrows)
            if (reverseIdx = 1)
                break
            
            baseToReverse := bases[reverseIdx]
            maxArrows := baseToReverse.arrows.MaxIndex()
            
            if maxArrows is number
            {
                Loop, %maxArrows%
                {
                    arrowIdx := maxArrows - A_Index + 1
                    arrow := baseToReverse.arrows[arrowIdx]
                    
                    if (arrow = "Up")
                        rev := "Down"
                    else if (arrow = "Down")
                        rev := "Up"
                    else if (arrow = "Left")
                        rev := "Right"
                    else if (arrow = "Right")
                        rev := "Left"
                    
                    SendInput, {%rev%}
                    Sleep, 100
                }
            }
            
            Sleep, 500
        }
        
        Sleep, 500  ; Reduced consistent delay
        
        ; Resource refill delay (after returning to Base 1, if more units remain)
        if (resourceDelay > 0)
        {
            ; Check if more units remaining
            moreUnits := false
            Loop, %total%
            {
                if (remaining[A_Index] > 0)
                {
                    moreUnits := true
                    break
                }
            }
            
            if (moreUnits)
            {
                delayMs := resourceDelay * 1000
                
                ; Cap resource delay to reasonable maximum
                if (delayMs > maxWaitTime)
                    delayMs := maxWaitTime
                
                ; Single status update
                UpdateStatus("Waiting for resources (" . resourceDelay . "s)...")
                
                ; Real-time countdown for resource delay
                startTime := A_TickCount
                targetTime := startTime + delayMs
                lastDisplayed := resourceDelay
                
                while (A_TickCount < targetTime && !restartCycle)
                {
                    currentTime := A_TickCount
                    timeRemaining := targetTime - currentTime
                    
                    if (timeRemaining > 0)
                    {
                        secondsRemaining := Round(timeRemaining / 1000)
                        
                        ; Update only when second count changes
                        if (secondsRemaining != lastDisplayed)
                        {
                            UpdateStatus("Resources in: " . secondsRemaining . "s")
                            lastDisplayed := secondsRemaining
                        }
                    }
                    
                    Sleep, 100  ; Short sleep for responsiveness
                    
                    if (restartCycle)
                    {
                        UpdateStatus("Restart during resource wait...")
                        break
                    }
                }
                
                ; If not restarting, brief focus check before continuing
                if (!restartCycle)
                {
                    EnsureGameFocus()
                    Sleep, 200
                    
                    ; Update status to show ready
                    UpdateStatus("Resources ready - continuing...")
                    Sleep, 500
                }
            }
        }
        
        ; Update GUI at end of cycle (non-critical timing)
        if (!restartCycle)
            Gosub, UpdateGUI
    }
    
    building := false
    UpdateStatus("Build complete! All units finished.")
    ToolTip
    MsgBox, All units completed at %total% bases!
return

; ═══════════════════════════════════════════════════════════
; RESTART CYCLE (F9 during building)
; ═══════════════════════════════════════════════════════════
F9::  ; Added hotkey definition
    if (building)
    {
        restartCycle := true
        ToolTip, Cycle restart requested...
        Sleep, 1000
        ToolTip
    }
return

; ═══════════════════════════════════════════════════════════
; CLEAR
; ═══════════════════════════════════════════════════════════
BtnClear:
    if building
    {
        MsgBox, Cannot clear while building!
        return
    }
    
    MsgBox, 4, Clear, Clear all bases?
    IfMsgBox Yes
    {
        bases := Object()
        isRecording := false
        arrowKeys := Object()
        resourceDelay := 0
        Gosub, UpdateGUI
        MsgBox, Cleared!
    }
return

; ═══════════════════════════════════════════════════════════
; EXIT
; ═══════════════════════════════════════════════════════════
BtnExit:
GuiClose:
    ExitApp
return
