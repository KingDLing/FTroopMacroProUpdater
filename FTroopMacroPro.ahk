#NoEnv
#SingleInstance Force
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; ═══════════════════════════════════════════════════════════
; FTroop Macro Pro - Unit Builder
; ═══════════════════════════════════════════════════════════

global bases := Object()
global isRecording := false
global arrowKeys := Object()
global building := false
global isPaused := false  
global restartCycle := false
global resourceDelay := 0
global gameWindowClass := ""
global maxWaitTime := 120000

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
Gui, Add, Button, xm y+5 w580 h40 gBtnHelp, Help / Instructions
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
F12::Gosub, TogglePause  
F9::Gosub, RestartCycle
Esc::ExitApp
^!F::Gosub, ForceGameFocus

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
        
        ShowTooltip("Recording arrows: " . count . " keys pressed`nPress F10 when at base")
    }
    Send, {%A_ThisHotkey%}
return

; ═══════════════════════════════════════════════════════════
; PAUSE/RESUME FUNCTIONALITY
; ═══════════════════════════════════════════════════════════
TogglePause:
    if (!building)
    {
        ShowTooltip("Nothing to pause - not building")
        Sleep, 1500
        ToolTip
        return
    }
    
    isPaused := !isPaused
    
    if (isPaused)
    {
        UpdateStatus(" PAUSED - Press F12 to resume")
        ShowTooltip(" PAUSED`n`nPress F12 to resume`nPress ESC to exit")
    }
    else
    {
        UpdateStatus(" Resuming build...")
        ShowTooltip(" Resuming...")
        Sleep, 1000
        ToolTip
    }
return

; ═══════════════════════════════════════════════════════════
; TOOLTIP POSITIONING 
; ═══════════════════════════════════════════════════════════
ShowTooltip(message) {
    ; Position tooltip offset from mouse pointer
    MouseGetPos, mX, mY
    ToolTip, %message%, mX + 200, mY + 100
}

; ═══════════════════════════════════════════════════════════
; KEEP SCREEN AWAKE FOR LONG DELAYS
; ═══════════════════════════════════════════════════════════
KeepScreenAwake(delaySeconds) {
    ; Only needed for delays longer than 1 minute
    if (delaySeconds < 60)
        return false
    
    ; Jiggle interval: every 30 seconds
    jiggleInterval := 30000  ; 30 seconds in ms
    return true
}

PerformScreenJiggle() {
    ; Subtle mouse jiggle in safe corner to prevent sleep
    MouseGetPos, origX, origY
    
    ; Move to top-left corner (safe area)
    MouseMove, 5, 5, 0
    Sleep, 50
    MouseMove, 10, 10, 0
    Sleep, 50
    
    ; Return to original position
    MouseMove, origX, origY, 0
}

; ═══════════════════════════════════════════════════════════
; HUMAN-LIKE MOUSE MOVEMENT
; ═══════════════════════════════════════════════════════════
SmoothMouseMove(targetX, targetY, speed := 10) {
    ; Get current position
    MouseGetPos, startX, startY
    
    ; Calculate distance
    deltaX := targetX - startX
    deltaY := targetY - startY
    distance := Sqrt(deltaX**2 + deltaY**2)
    
    ; If already at target, no need to move
    if (distance < 2)
        return
    
    ; Calculate number of steps based on distance and speed
    ; Speed: 1=slowest, 5=fastest
    steps := Max(10, Floor(distance / (speed * 5)))
    
    ; Add slight curve to movement (more natural)
    curveAmount := Random(-10, 10)
    
    Loop, %steps%
    {
        progress := A_Index / steps
        
        ; Ease-in-out function for smooth acceleration/deceleration
        t := progress
        eased := t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        
        ; Calculate position with slight curve
        currentX := startX + (deltaX * eased)
        currentY := startY + (deltaY * eased) + (curveAmount * Sin(progress * 3.14159))
        
        MouseMove, %currentX%, %currentY%, 0
        
        ; Variable delay for more natural movement
        Sleep, % Random(5, 15)
    }
    
    ; Ensure we end exactly at target
    MouseMove, %targetX%, %targetY%, 0
}

Random(min, max) {
    Random, rand, %min%, %max%
    return rand
}

; ═══════════════════════════════════════════════════════════
; AUTO-UPDATE SYSTEM
; ═══════════════════════════════════════════════════════════

BtnUpdate:
    if building
    {
        MsgBox, Cannot update while building!
        return
    }
    
    GuiControl,, StatusText, Checking for updates...
    
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
    
    MsgBox, 4, Update Available, New version %latestVersion% is available!`n`nCurrent version: %SCRIPT_VERSION%`nLatest version: %latestVersion%`n`nUpdate now?
    
    IfMsgBox No
    {
        GuiControl,, StatusText, Update cancelled
        return
    }
    
    GuiControl,, StatusText, Downloading update...
    
    if (DownloadUpdate())
    {
        MsgBox, 4, Update Complete, Update downloaded successfully!`n`nThe script needs to restart to apply the update. Restart now?
        
        IfMsgBox Yes
        {
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

BtnHelp:
    helpText = 
    (
FTROOP MACRO PRO v%SCRIPT_VERSION%

WHAT THIS SCRIPT DOES:
Automates unit building across multiple bases in Combat Siege.
Records base positions and navigation paths, then automatically cycles
through bases to build units.

HOTKEYS:
F10      - Record unit position on screen
F11      - Execute building cycle 
F12      - Pause/Resume build cycle (NEW!)
ESC      - Exit program

QUICK START:
1. Start at base 1
2. Hover mouse over unit you want to build and press F10
3. Enter unit count and delay time between builds
4. Use arrow keys to navigate to next base
5. Press F10 over each new unit at subsequent bases 
6. Press F11 to start building

NEW FEATURES v4.1:
✓ Pause/Resume with F12
✓ Screen stays awake during long delays

FEATURES:
 Multiple base support
 Custom build delays
 Resource refill delay
 Auto-return to Base 1
 Real-time status updates
 Auto-update capability
 Game window focus management

IMPORTANT:
 Don't move map during execution
 Game must remain visible
    )
    
    MsgBox, %helpText%
return

CheckForUpdates() {
    global VERSION_CHECK_URL
    
    try {
        cacheBusterURL := VERSION_CHECK_URL . "?t=" . A_Now
        
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", cacheBusterURL, true)
        whr.Send()
        whr.WaitForResponse()
        
        versionText := whr.ResponseText
        whr := ""
        
        versionText := RegExReplace(versionText, "[^\d\.]", "")
        versionText := Trim(versionText, ".")
        
        if (versionText = "")
            return "ERROR"
        
        return versionText
    }
    catch {
        return "ERROR"
    }
}

DownloadUpdate() {
    global UPDATE_URL, SCRIPT_NAME
    
    try {
        scriptDir := A_ScriptDir
        tempFile := scriptDir . "\" . SCRIPT_NAME . ".new"
        backupFile := scriptDir . "\" . SCRIPT_NAME . ".backup"
        
        cacheBusterURL := UPDATE_URL . "?t=" . A_Now
        
        URLDownloadToFile, %cacheBusterURL%, %tempFile%
        
        FileGetSize, fileSize, %tempFile%
        if (fileSize < 1000)
        {
            FileDelete, %tempFile%
            return false
        }
        
        FileCopy, %A_ScriptFullPath%, %backupFile%, 1
        FileCopy, %tempFile%, %A_ScriptFullPath%, 1
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
    
    if (gameWindowClass = "") {
        WinGet, currentActive, ID, A
        WinGetClass, currentClass, ahk_id %currentActive%
        
        if (currentClass != "AutoHotkeyGUI") {
            gameWindowClass := currentClass
        } else {
            WinGet, windowList, List
            Loop, %windowList%
            {
                windowID := windowList%A_Index%
                WinGetClass, windowClass, ahk_id %windowID%
                WinGetTitle, windowTitle, ahk_id %windowID%
                
                if (windowClass = "AutoHotkeyGUI" || windowTitle = "")
                    continue
                    
                if (InStr(windowTitle, "FTroop") || InStr(windowTitle, "Game") || InStr(windowTitle, "Troop")) {
                    gameWindowClass := windowClass
                    break
                }
            }
        }
    }
    
    if (gameWindowClass != "") {
        IfWinNotActive, ahk_class %gameWindowClass%
        {
            WinActivate, ahk_class %gameWindowClass%
            WinWaitActive, ahk_class %gameWindowClass%, , 1.5
            Sleep, 150
            return true
        }
    }
    return false
}

UpdateStatus(message, isCritical := false) {
    static lastUpdate := 0
    static minUpdateInterval := 250
    
    currentTime := A_TickCount
    
    if (isCritical && (currentTime - lastUpdate < minUpdateInterval)) {
        ShowTooltip(message)
        return
    }
    
    GuiControl,, StatusText, %message%
    ShowTooltip(message)
    lastUpdate := currentTime
}

ForceGameFocus:
    EnsureGameFocus()
    ShowTooltip("Game focus restored")
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
    
    if isRecording
    {
        isRecording := false
        ToolTip
    }
    
    MouseGetPos, bx, by
    
    baseNum := bases.MaxIndex()
    if baseNum is not number
        baseNum := 0
    baseNum := baseNum + 1
    
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
    
    newBase := Object()
    newBase.x := bx
    newBase.y := by
    newBase.units := units
    newBase.delay := delay
    newBase.remaining := units
    newBase.arrows := Object()
    
    maxIdx := arrowKeys.MaxIndex()
    if maxIdx is number
    {
        Loop, %maxIdx%
        {
            newBase.arrows[A_Index] := arrowKeys[A_Index]
        }
    }
    
    bases[baseNum] := newBase
    
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
        
        Click, %bx%, %by%, 0
        Sleep, 200
        
        MsgBox, From Base %baseNum%, use arrow keys to navigate to Base %nextBase%.`nPress F10 when you arrive.
    }
    else
    {
        arrowKeys := Object()
        
        if (baseNum > 1)
        {
            resMsg := ""
            if (resourceDelay > 0)
                resMsg := "`nResource refill delay: " resourceDelay " seconds"
            
            MsgBox, Recording complete!`n`n%total% bases recorded.%resMsg%`n`nReturning to Base 1 automatically...
            Sleep, 1000
            
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
; EXECUTE (F11) - WITH PAUSE SUPPORT
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
    
    UpdateStatus("Starting macro in 3...")
    ShowTooltip("Starting macro in 3...")
    Sleep, 1000
    
    UpdateStatus("Starting macro in 2...")
    ShowTooltip("Starting macro in 2...")
    Sleep, 1000
    
    UpdateStatus("Starting macro in 1...")
    ShowTooltip("Starting macro in 1...")
    Sleep, 1000
    
    UpdateStatus("Starting now! Remove mouse...")
    ShowTooltip("Starting now! Remove mouse...")
    Sleep, 500
    
    ToolTip
    
    building := true
    isPaused := false
    restartCycle := false
    
    remaining := Object()
    lastBuildTime := Object()
    
    Loop, %total%
    {
        baseObj := bases[A_Index]
        remaining[A_Index] := baseObj.units
        lastBuildTime[A_Index] := 0
    }
    
    ; Main build loop
    Loop
    {
        ; Check for pause
        while (isPaused)
        {
            Sleep, 100
        }
        
        if (restartCycle)
        {
            restartCycle := false
            UpdateStatus("Restarting cycle...")
            ShowTooltip("Restarting cycle - returning to Base 1...")
            Sleep, 1000
            
            if (lastBuildTime[1] > 0)
            {
                base1Obj := bases[1]
                buildTimeMs := base1Obj.delay * 1000
                
                currentTime := A_TickCount
                timeSinceLastBuild := currentTime - lastBuildTime[1]
                
                if (timeSinceLastBuild < 0)
                    timeSinceLastBuild := (4294967295 - lastBuildTime[1]) + currentTime
                
                timeLeft := buildTimeMs - timeSinceLastBuild
                
                if (timeLeft > (buildTimeMs + 10000) || timeLeft < 0)
                    timeLeft := 0
                
                if (timeLeft > 0)
                {
                    secondsLeft := Round(timeLeft / 1000)
                    UpdateStatus("Waiting for Base 1: " . secondsLeft . "s")
                    
                    startTime := A_TickCount
                    targetTime := startTime + timeLeft
                    lastDisplayed := secondsLeft
                    
                    while (A_TickCount < targetTime && !restartCycle && !isPaused)
                    {
                        currentTime := A_TickCount
                        timeRemaining := targetTime - currentTime
                        
                        if (timeRemaining > 0)
                        {
                            secondsRemaining := Round(timeRemaining / 1000)
                            
                            if (secondsRemaining != lastDisplayed)
                            {
                                UpdateStatus("Waiting for Base 1: " . secondsRemaining . "s")
                                lastDisplayed := secondsRemaining
                            }
                        }
                        
                        Sleep, 100
                        
                        if (restartCycle || isPaused)
                            break
                    }
                    
                    if (!restartCycle && !isPaused)
                        UpdateStatus("Base 1 ready!")
                }
            }
            
            UpdateStatus("Restarting cycle...")
            ShowTooltip("Base 1 ready! Restarting cycle...")
            Sleep, 1000
            continue
        }
        
        done := true
        Loop, %total%
        {
            if (remaining[A_Index] > 0)
                done := false
        }
        
        if done
            break
        
        if (remaining[1] > 0)
        {
            currentTime := A_TickCount
            if (lastBuildTime[1] > 0)
            {
                base1Obj := bases[1]
                buildTimeMs := base1Obj.delay * 1000
                
                timeSinceLastBuild := currentTime - lastBuildTime[1]
                if (timeSinceLastBuild < 0)
                {
                    timeSinceLastBuild := (4294967295 - lastBuildTime[1]) + currentTime
                }
                
                if (timeSinceLastBuild < buildTimeMs)
                {
                    timeLeft := buildTimeMs - timeSinceLastBuild
                    
                    if (timeLeft > (buildTimeMs + 10000) || timeLeft < 0)
                    {
                        lastBuildTime[1] := currentTime
                        UpdateStatus("Timer adjusted - continuing", true)
                        Sleep, 500
                        continue
                    }
                    
                    if (timeLeft > maxWaitTime)
                        timeLeft := maxWaitTime
                    
                    secondsLeft := Round(timeLeft / 1000)
                    
                    if (secondsLeft > 0)
                    {
                        UpdateStatus("Waiting for Base 1: " . secondsLeft . "s", true)
                        
                        startTime := A_TickCount
                        targetTime := startTime + timeLeft
                        lastDisplayedSecond := secondsLeft
                        lastJiggle := startTime
                        
                        while (A_TickCount < targetTime && !restartCycle && !isPaused)
                        {
                            currentTime := A_TickCount
                            timeRemaining := targetTime - currentTime
                            
                            ; Screen awake jiggle for long waits
                            if (secondsLeft >= 60 && (currentTime - lastJiggle) > 30000)
                            {
                                PerformScreenJiggle()
                                lastJiggle := currentTime
                            }
                            
                            if (timeRemaining > 0)
                            {
                                secondsRemaining := Round(timeRemaining / 1000)
                                
                                if (secondsRemaining != lastDisplayedSecond)
                                {
                                    UpdateStatus("Waiting for Base 1: " . secondsRemaining . "s", true)
                                    lastDisplayedSecond := secondsRemaining
                                }
                            }
                            
                            Sleep, 100
                            
                            if (restartCycle || isPaused)
                            {
                                UpdateStatus("Wait interrupted...")
                                break
                            }
                        }
                        
                        if (!restartCycle && !isPaused)
                            UpdateStatus("Base 1 ready!", true)
                        
                        if (restartCycle || isPaused)
                            continue
                    }
                    continue
                }
            }
        }
        
        ; Go through bases
        Loop, %total%
        {
            ; Check for pause at start of each base
            while (isPaused)
            {
                Sleep, 100
            }
            
            i := A_Index
            baseObj := bases[i]
            
            if (remaining[i] <= 0)
                continue
            
            if (i > 1)
            {
                UpdateStatus("Going to Base " . i, true)
                
                EnsureGameFocus()
                Sleep, 150
                
                maxArrows := baseObj.arrows.MaxIndex()
                if maxArrows is number
                {
                    Loop, %maxArrows%
                    {
                        arrow := baseObj.arrows[A_Index]
                        
                        if (Mod(A_Index, 3) = 0)
                            EnsureGameFocus()
                        
                        SendInput, {%arrow%}
                        Sleep, 100
                    }
                }
                
                Sleep, 500
            }
            
                       remCount := remaining[i]
            UpdateStatus("Building at Base " . i . " - Remaining: " . remCount, true)
            
            EnsureGameFocus()
            Sleep, 200
            
            ; Simple mouse wiggle that worked in the old version
            MouseMove, baseObj.x + 5, baseObj.y + 5, 0
            Sleep, 50
            MouseMove, baseObj.x, baseObj.y, 0
            Sleep, 100
            
            EnsureGameFocus()
            Click
            
            remaining[i] := remaining[i] - 1
            lastBuildTime[i] := A_TickCount
            
            baseObj.remaining := remaining[i]
            if (Mod(i, 2) = 0 || i = 1)
                Gosub, UpdateGUI
            
            Sleep, 2000
        }
        
        UpdateStatus("Returning to Base 1...", true)
        EnsureGameFocus()
        Sleep, 200
        
        Loop, %total%
        {
            reverseIdx := total - A_Index + 1
            
            if (reverseIdx < 1)
                break
            
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
        
        Sleep, 500
        
        ; Resource refill with screen awake
        if (resourceDelay > 0)
        {
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
                
                if (delayMs > maxWaitTime)
                    delayMs := maxWaitTime
                
                UpdateStatus("Waiting for resources (" . resourceDelay . "s)...")
                
                needsJiggle := KeepScreenAwake(resourceDelay)
                
                startTime := A_TickCount
                targetTime := startTime + delayMs
                lastDisplayed := resourceDelay
                lastJiggle := startTime
                
                while (A_TickCount < targetTime && !restartCycle && !isPaused)
                {
                    currentTime := A_TickCount
                    timeRemaining := targetTime - currentTime
                    
                    ; Perform screen jiggle every 30 seconds for long delays
                    if (needsJiggle && (currentTime - lastJiggle) > 30000)
                    {
                        PerformScreenJiggle()
                        lastJiggle := currentTime
                    }
                    
                    if (timeRemaining > 0)
                    {
                        secondsRemaining := Round(timeRemaining / 1000)
                        
                        if (secondsRemaining != lastDisplayed)
                        {
                            UpdateStatus("Resources in: " . secondsRemaining . "s")
                            lastDisplayed := secondsRemaining
                        }
                    }
                    
                    Sleep, 100
                    
                    if (restartCycle || isPaused)
                    {
                        UpdateStatus("Resource wait interrupted...")
                        break
                    }
                }
                
                if (!restartCycle && !isPaused)
                {
                    EnsureGameFocus()
                    Sleep, 200
                    
                    UpdateStatus("Resources ready - continuing...")
                    Sleep, 500
                }
            }
        }
        
        if (!restartCycle && !isPaused)
            Gosub, UpdateGUI
    }
    
    building := false
    isPaused := false
    UpdateStatus("Build complete! All units finished.")
    ToolTip
    MsgBox, All units completed at %total% bases!
return

; ═══════════════════════════════════════════════════════════
; RESTART CYCLE
; ═══════════════════════════════════════════════════════════
RestartCycle:
    if (building)
    {
        restartCycle := true
        ShowTooltip("Cycle restart requested...")
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
