#NoEnv
#NoTrayIcon
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
#SingleInstance Force
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
CoordMode, Pixel, Screen

global CLOUDFLARE_WORKER_URL := "https://withered-sun-752b.jimsmithmi001.workers.dev"
global MAX_ATTEMPTS := 3
global SCRIPT_NAME_SEC := "FTroop Macro Pro SEC v1.1"

ValidatePasswordWithServer(userPassword) {
    global CLOUDFLARE_WORKER_URL
    
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", CLOUDFLARE_WORKER_URL, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        
        jsonData := "{""password"":""" . userPassword . """}"
        whr.Send(jsonData)
        whr.WaitForResponse(10)
        
        if (whr.Status = 200) {
            response := whr.ResponseText
            
            if (InStr(response, """valid"":true")) {
                RegExMatch(response, """expiryDate"":""([^""]+)""", match)
                expiryDate := match1
                
                RegExMatch(response, """message"":""([^""]+)""", match)
                customMessage := match1
                
                return expiryDate "|" customMessage
            }
        }
        
        return "INVALID"
    } catch e {
        return "ERROR"
    }
}

SplashTextOn, 400, 130, %SCRIPT_NAME_SEC%, Checking license access...`n`nPlease wait...
Sleep, 500
SplashTextOff

attempts := 0
success := false
expiryDate := ""
customMessage := ""

Loop
{
    inputMessage := "FTroop Macro Pro SEC v1.1`n`nEnter access password:"
    
    InputBox, userInput, %SCRIPT_NAME_SEC%, %inputMessage%, HIDE, 480, 220
    
    if ErrorLevel
    {
        MsgBox, 36, Exit Confirmation, Are you sure you want to exit?
        IfMsgBox Yes
            ExitApp
        else
            continue
    }
    
    SplashTextOn, 400, 100, Validating..., Checking your password...`n`nPlease wait...
    result := ValidatePasswordWithServer(userInput)
    SplashTextOff
    
    if (result = "ERROR")
    {
        MsgBox, 48, Connection Failed, Cannot connect to license server!`n`n1. Check your internet connection`n2. Try again later`n`nIf problem continues, contact support.
        continue
    }
    
    if (result != "INVALID")
    {
        parts := StrSplit(result, "|")
        expiryDate := Trim(parts[1])
        customMessage := (parts.Length() >= 2) ? Trim(parts[2]) : ""
        
        FormatTime, currentDate,, yyyy-MM-dd
        if (currentDate > expiryDate)
        {
            MsgBox, 48, License Expired, Your FTroop Macro Pro SEC license has expired!`n`nExpiration date: %expiryDate%`nCurrent date: %currentDate%`n`nPlease renew your license to continue.
            ExitApp
        }
        
        success := true
        break
    }
    
    attempts++
    remaining := MAX_ATTEMPTS - attempts
    
    if (attempts >= MAX_ATTEMPTS)
    {
        MsgBox, 16, Access Denied, Maximum attempts reached!`n`nAccess permanently locked.`nContact support for a password reset.
        ExitApp
    }
    
    MsgBox, 48, Invalid Password, Incorrect password!`n`nAttempts used: %attempts%`nRemaining attempts: %remaining%`n`nTry again or contact support.
}

if (!success)
    ExitApp

welcomeMsg := "FTroop Macro Pro SEC v1.1`n------------------------`nAccess granted!`n`nLicense valid until: " . expiryDate
if (customMessage != "")
    welcomeMsg .= "`n`n" . customMessage

MsgBox, 64, Welcome, %welcomeMsg%`n`nClick OK to start the application.
Sleep, 500

global bases := Object()
global isRecording := false
global arrowKeys := Object()
global building := false
global isPaused := false
global restartCycle := false
global resourceDelay := 0
global gameWindowClass := ""
global maxWaitTime := 120000
global beepTimerActive := false
global beepTimerInterval := 10000
global lastClickedBase := 0
global lastClickedX := 0
global lastClickedY := 0
global captchaDetectedAtBase := 0
global SCRIPT_VERSION := "1.1"
global UPDATE_URL := "https://raw.githubusercontent.com/KingDLing/FTroopMacroProUpdater/main/FTroopMacroPro.ahk"
global VERSION_CHECK_URL := "https://raw.githubusercontent.com/KingDLing/FTroopMacroProUpdater/main/Version.txt"
global SCRIPT_NAME := "FTroopMacroPro.ahk"
global CONFIG_DIR := A_ScriptDir . "\FTroopConfigs"

FileCreateDir, %CONFIG_DIR%

Gui, Color, 0F0F0F
Gui, Font, s13 Bold cFFD700
Gui, Add, Text, Center w600 y15, FTroop Macro Pro v%SCRIPT_VERSION%

Menu, FileMenu, Add, Save Configuration, BtnSaveConfig
Menu, FileMenu, Add, Load Configuration, BtnLoadConfig
Menu, FileMenu, Add, Delete Configuration, BtnDeleteConfig
Menu, FileMenu, Add
Menu, FileMenu, Add, Exit, BtnExit

Menu, ToolsMenu, Add, Check for Updates, BtnUpdate

Menu, HelpMenu, Add, Help / Instructions, BtnHelp

Menu, MainMenuBar, Add, &File, :FileMenu
Menu, MainMenuBar, Add, &Tools, :ToolsMenu
Menu, MainMenuBar, Add, &Help, :HelpMenu

Gui, Menu, MainMenuBar

Gui, Font, s10 cEEEEEE Normal
Gui, Add, Button, xm y+20 w280 h35 gBtnExecute, Execute Build (F11)
Gui, Add, Button, x+20 yp w280 h35 gBtnClear, Clear All Bases

Gui, Add, Text, xm y+10 w600 h2 0x10 Background404040
Gui, Font, s10 Bold cFFD700
Gui, Add, Text, xm y+15 w600, Base Configuration

Gui, Font, s9 cBlack Normal
Gui, Add, ListView, xm y+10 w600 h280 vBaseListView -Multi Grid BackgroundWhite cBlack gBaseListView, Base #|Units|Delay (s)|Arrows|Remaining
LV_ModifyCol(1, 100, "Base #")
LV_ModifyCol(2, 100, "Units")
LV_ModifyCol(3, 110, "Delay (s)")
LV_ModifyCol(4, 100, "Arrows")
LV_ModifyCol(5, 120, "Remaining")

Gui, Add, Text, xm y+10 w600 h2 0x10 Background404040

Gui, Font, s9 cEEEEEE Normal
Gui, Add, GroupBox, xm y+10 w600 h120, Quick Edit (While Paused)
Gui, Add, Text, xp+10 yp+25, Base #:
Gui, Font, s9 c000000 Normal
Gui, Add, Edit, x+5 yp-3 w50 vEditBaseNumber BackgroundWhite, 1
Gui, Font, s9 cEEEEEE Normal
Gui, Add, Text, x+15, Units:
Gui, Font, s9 c000000 Normal
Gui, Add, Edit, x+5 yp-3 w70 vEditUnits BackgroundWhite
Gui, Font, s9 cEEEEEE Normal
Gui, Add, Text, x+15, Delay (s):
Gui, Font, s9 c000000 Normal
Gui, Add, Edit, x+5 yp-3 w70 vEditDelay BackgroundWhite
Gui, Font, s9 cEEEEEE Normal
Gui, Add, Button, x+15 yp-3 w80 h25 gBtnUpdateBase, Update Base

Gui, Add, Text, xm+10 y+15, Resource Delay (s):
Gui, Font, s9 c000000 Normal
Gui, Add, Edit, x+5 yp-3 w100 vEditResourceDelay BackgroundWhite, 0
Gui, Font, s9 cEEEEEE Normal
Gui, Add, Button, x+10 yp-3 w120 h25 gBtnUpdateResourceDelay, Update Delay
Gui, Add, Button, x+10 yp w80 h25 gBtnRefreshList, Refresh List

Gui, Add, Text, xm y+10 w600 vStatusText Center, Go to Base 1, Press F10 over the unit you want to build

Gui, Show, w620, FTroop Macro Pro v%SCRIPT_VERSION%
Gosub, UpdateGUI
return

F10::Gosub, BtnRecordBase
F11::Gosub, BtnExecute
F12::Gosub, TogglePause
F9::Gosub, RestartCycle
Esc::ExitApp
^!F::Gosub, ForceGameFocus

Up::
Down::
Left::
Right::
    if (isPaused)
        return
    if isRecording
    {
        EnsureGameFocus()
        Sleep, 50
        
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

CompleteReset() {
    global building, isPaused, restartCycle, isRecording
    global bases, arrowKeys, resourceDelay
    global lastBuildTime, remaining
    global beepTimerActive, lastClickedBase, lastClickedX, lastClickedY
    global captchaDetectedAtBase
    
    building := false
    isPaused := false
    restartCycle := false
    isRecording := false
    beepTimerActive := false
    
    SetTimer, RepeatBeepAlert, Off
    
    bases := Object()
    arrowKeys := Object()
    lastBuildTime := Object()
    remaining := Object()
    
    resourceDelay := 0
    GuiControl,, EditResourceDelay, 0
    
    lastClickedBase := 0
    lastClickedX := 0
    lastClickedY := 0
    captchaDetectedAtBase := 0
    
    ToolTip
    
    Gosub, UpdateGUI
}

BtnUpdateResourceDelay:
    Gui, Submit, NoHide
    newDelay := EditResourceDelay
    
    if (newDelay = "")
    {
        MsgBox, Please enter a valid delay value.
        return
    }
    
    if (newDelay < 0)
    {
        MsgBox, Delay cannot be negative.
        GuiControl,, EditResourceDelay, %resourceDelay%
        return
    }
    
    resourceDelay := newDelay
    UpdateStatus("Resource delay updated to " . resourceDelay . " seconds")
    Gosub, UpdateGUI
return

BtnSaveConfig:
    total := bases.MaxIndex()
    if total is not number
        total := 0
    
    if (total = 0)
    {
        MsgBox, No bases to save! Record bases first.
        return
    }
    
    InputBox, configName, Save Configuration, Enter a name for this configuration:, , 400, 150
    
    if ErrorLevel
        return
    
    if (configName = "")
    {
        MsgBox, Configuration name cannot be empty!
        return
    }
    
    configName := RegExReplace(configName, "[\\/:*?""<>|]", "_")
    
    configFile := CONFIG_DIR . "\" . configName . ".ini"
    
    IfExist, %configFile%
    {
        MsgBox, 4, Overwrite?, Configuration "%configName%" already exists. Overwrite?
        IfMsgBox No
            return
    }
    
    IniWrite, %resourceDelay%, %configFile%, Settings, ResourceDelay
    IniWrite, %total%, %configFile%, Settings, TotalBases
    
    Loop, %total%
    {
        baseObj := bases[A_Index]
        section := "Base" . A_Index
        
        IniWrite, % baseObj.x, %configFile%, %section%, X
        IniWrite, % baseObj.y, %configFile%, %section%, Y
        IniWrite, % baseObj.units, %configFile%, %section%, Units
        IniWrite, % baseObj.delay, %configFile%, %section%, Delay
        
        arrowCount := baseObj.arrows.MaxIndex()
        if arrowCount is not number
            arrowCount := 0
        
        IniWrite, %arrowCount%, %configFile%, %section%, ArrowCount
        
        Loop, %arrowCount%
        {
            arrowKey := "Arrow" . A_Index
            arrowVal := baseObj.arrows[A_Index]
            IniWrite, %arrowVal%, %configFile%, %section%, %arrowKey%
        }
    }
    
    MsgBox, 64, Success, Configuration "%configName%" saved successfully!`n`nTotal bases: %total%`nResource delay: %resourceDelay%s
    UpdateStatus("Configuration saved: " . configName)
return

BtnLoadConfig:
    if building
    {
        MsgBox, Cannot load while building!
        return
    }
    
    configs := []
    configList := ""
    
    Loop, %CONFIG_DIR%\*.ini
    {
        SplitPath, A_LoopFileName, , , , nameNoExt
        configs.Push(nameNoExt)
        configList .= nameNoExt . "|"
    }
    
    if (configs.MaxIndex() = "" || configs.MaxIndex() = 0)
    {
        MsgBox, No saved configurations found!
        return
    }
    
    Gui, LoadConfig:New
    Gui, LoadConfig:Color, 0F0F0F
    Gui, LoadConfig:Font, s10 Bold cFFD700
    Gui, LoadConfig:Add, Text, w300, Select Configuration to Load:
    Gui, LoadConfig:Font, s9 cBlack Normal
    Gui, LoadConfig:Add, ListBox, w300 h200 vSelectedConfig, %configList%
    Gui, LoadConfig:Font, s9 cEEEEEE Normal
    Gui, LoadConfig:Add, Button, w145 h30 gLoadConfigOK Default, Load
    Gui, LoadConfig:Add, Button, x+10 yp w145 h30 gLoadConfigCancel, Cancel
    Gui, LoadConfig:Show, , Load Configuration
return

LoadConfigOK:
    Gui, LoadConfig:Submit
    
    if (SelectedConfig = "")
    {
        MsgBox, Please select a configuration!
        return
    }
    
    Gui, LoadConfig:Destroy
    
    configFile := CONFIG_DIR . "\" . SelectedConfig . ".ini"
    
    IniRead, loadedResourceDelay, %configFile%, Settings, ResourceDelay, 0
    IniRead, totalBases, %configFile%, Settings, TotalBases, 0
    
    if (totalBases = 0)
    {
        MsgBox, Invalid configuration file!
        return
    }
    
    CompleteReset()
    
    bases := Object()
    
    Loop, %totalBases%
    {
        section := "Base" . A_Index
        
        IniRead, bx, %configFile%, %section%, X
        IniRead, by, %configFile%, %section%, Y
        IniRead, units, %configFile%, %section%, Units
        IniRead, delay, %configFile%, %section%, Delay
        IniRead, arrowCount, %configFile%, %section%, ArrowCount, 0
        
        newBase := Object()
        newBase.x := bx
        newBase.y := by
        newBase.units := units
        newBase.delay := delay
        newBase.remaining := units
        newBase.arrows := Object()
        
        Loop, %arrowCount%
        {
            arrowKey := "Arrow" . A_Index
            IniRead, arrowVal, %configFile%, %section%, %arrowKey%
            newBase.arrows[A_Index] := arrowVal
        }
        
        bases[A_Index] := newBase
    }
    
    resourceDelay := loadedResourceDelay
    GuiControl,, EditResourceDelay, %resourceDelay%
    
    Gosub, UpdateGUI
    
    MsgBox, 64, Success, Configuration "%SelectedConfig%" loaded successfully!`n`nBases loaded: %totalBases%`nResource delay: %resourceDelay%s`n`nReady to execute!
    UpdateStatus("Configuration loaded: " . SelectedConfig)
return

LoadConfigCancel:
    Gui, LoadConfig:Destroy
return

BtnDeleteConfig:
    configs := []
    configList := ""
    
    Loop, %CONFIG_DIR%\*.ini
    {
        SplitPath, A_LoopFileName, , , , nameNoExt
        configs.Push(nameNoExt)
        configList .= nameNoExt . "|"
    }
    
    if (configs.MaxIndex() = "" || configs.MaxIndex() = 0)
    {
        MsgBox, No saved configurations found!
        return
    }
    
    Gui, DeleteConfig:New
    Gui, DeleteConfig:Color, 0F0F0F
    Gui, DeleteConfig:Font, s10 Bold cFFD700
    Gui, DeleteConfig:Add, Text, w300, Select Configuration to Delete:
    Gui, DeleteConfig:Font, s9 cBlack Normal
    Gui, DeleteConfig:Add, ListBox, w300 h200 vSelectedConfigDelete, %configList%
    Gui, DeleteConfig:Font, s9 cEEEEEE Normal
    Gui, DeleteConfig:Add, Button, w145 h30 gDeleteConfigOK, Delete
    Gui, DeleteConfig:Add, Button, x+10 yp w145 h30 gDeleteConfigCancel, Cancel
    Gui, DeleteConfig:Show, , Delete Configuration
return

DeleteConfigOK:
    Gui, DeleteConfig:Submit
    
    if (SelectedConfigDelete = "")
    {
        MsgBox, Please select a configuration!
        return
    }
    
    Gui, DeleteConfig:Destroy
    
    MsgBox, 4, Confirm Delete, Are you sure you want to delete "%SelectedConfigDelete%"?
    IfMsgBox No
        return
    
    configFile := CONFIG_DIR . "\" . SelectedConfigDelete . ".ini"
    FileDelete, %configFile%
    
    MsgBox, 64, Deleted, Configuration "%SelectedConfigDelete%" has been deleted.
    UpdateStatus("Configuration deleted: " . SelectedConfigDelete)
return

DeleteConfigCancel:
    Gui, DeleteConfig:Destroy
return

CheckForDarkScreen() {
    SysGet, screenWidth, 0
    SysGet, screenHeight, 1
    
    darkPoints := 0
    
    Loop, 5 {
        x := screenWidth // 2
        y := screenHeight // 3 + (A_Index - 1) * (screenHeight // 12)
        
        PixelGetColor, color, %x%, %y%, RGB
        red := (color >> 16) & 0xFF
        green := (color >> 8) & 0xFF
        blue := color & 0xFF
        brightness := (red + green + blue) / 3
        
        if (brightness < 40)
            darkPoints++
    }
    
    if (darkPoints >= 4)
        return true
    
    return false
}

TogglePause:
    if (!building)
    {
        ShowTooltip("Nothing to pause - not building")
        Sleep, 1500
        ToolTip
        return
    }
    
    if (isPaused)
    {
        if (captchaDetectedAtBase > 0 && lastClickedBase > 0 && lastClickedX > 0 && lastClickedY > 0)
        {
            UpdateStatus("Redoing last click at Base " . lastClickedBase . "...")
            ShowTooltip("Redoing last click...")
            Sleep, 1000
            
            EnsureGameFocus()
            Sleep, 200
            
            MouseMove, lastClickedX + 5, lastClickedY + 5, 0
            Sleep, 50
            MouseMove, lastClickedX, lastClickedY, 0
            Sleep, 150
            
            Click
            Sleep, 2000
            
            lastBuildTime[captchaDetectedAtBase] := A_TickCount
            captchaDetectedAtBase := 0
            UpdateStatus("Timer reset for Base " . lastClickedBase . " after CAPTCHA", true)
            
            lastClickedBase := 0
            lastClickedX := 0
            lastClickedY := 0
        }
        
        isPaused := false
        UpdateStatus("Resuming build...")
        ShowTooltip("Resuming...")
        Sleep, 1000
        ToolTip
    }
    else
    {
        isPaused := true
        UpdateStatus("PAUSED - Press F12 to resume")
        ShowTooltip("PAUSED`n`nPress F12 to resume`nPress ESC to exit")
    }
return

BaseListView:
    if (A_GuiEvent = "Normal")
    {
        row := A_EventInfo
        if (row > 0)
        {
            LV_GetText(baseNum, row, 1)
            LV_GetText(units, row, 2)
            LV_GetText(delay, row, 3)
            
            GuiControl,, EditBaseNumber, %baseNum%
            GuiControl,, EditUnits, %units%
            GuiControl,, EditDelay, %delay%
        }
    }
return

RepeatBeepAlert:
    if (beepTimerActive && isPaused) {
        SoundPlay, %A_WinDir%\Media\Windows Notify.wav
        Sleep, 200
        SoundBeep, 750, 400
        Sleep, 200
        SoundBeep, 650, 400
        
        ShowTooltip("CAPTCHA DETECTED!`n`nScript PAUSED automatically.`n`n1. Solve the CAPTCHA`n2. Press F12 to resume`n`nNext alert in 10 seconds...")
    } else {
        SetTimer, RepeatBeepAlert, Off
    }
return

ShowTooltip(message) {
    MouseGetPos, mX, mY
    ToolTip, %message%, mX + 200, mY + 100
}

KeepScreenAwake(delaySeconds) {
    if (delaySeconds < 60)
        return false
    return true
}

PerformScreenJiggle() {
    MouseGetPos, origX, origY
    MouseMove, 5, 5, 0
    Sleep, 50
    MouseMove, 10, 10, 0
    Sleep, 50
    MouseMove, origX, origY, 0
}

SmoothMouseMove(targetX, targetY, speed := 10) {
    MouseGetPos, startX, startY
    deltaX := targetX - startX
    deltaY := targetY - startY
    distance := Sqrt(deltaX**2 + deltaY**2)
    
    if (distance < 2)
        return
    
    steps := Max(10, Floor(distance / (speed * 5)))
    curveAmount := Random(-10, 10)
    
    Loop, %steps%
    {
        progress := A_Index / steps
        t := progress
        eased := t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        
        currentX := startX + (deltaX * eased)
        currentY := startY + (deltaY * eased) + (curveAmount * Sin(progress * 3.14159))
        
        MouseMove, %currentX%, %currentY%, 0
        Sleep, % Random(5, 15)
    }
    
    MouseMove, %targetX%, %targetY%, 0
}

Random(min, max) {
    Random, rand, %min%, %max%
    return rand
}

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
Automates unit building across multiple bases.
Records base positions and navigation paths, then automatically cycles through bases to build units.

HOTKEYS:
F9       - Restart cycle (return to Base 1)
F10      - Record unit position on screen
F11      - Execute building cycle 
F12      - Pause/Resume build cycle
ESC      - Exit program

CAPTCHA DETECTION:
 Automatically checks for CAPTCHA after each build
 Pauses script and plays alert if CAPTCHA detected
 User solves CAPTCHA manually, then presses F12 to resume

QUICK START:
1. Start at base 1
2. Press F10 over the unit you want to build
3. Enter unit count and delay time between builds
4. Use arrow keys to navigate to next base
5. Press F10 over each new unit at subsequent bases 
6. When finished click no to adding another base
7. Press F11 to start building

SAVE/LOAD CONFIGURATIONS:
- Save and load configs from File menu

FEATURES:
- Multiple base support
- Custom build delays
- Resource refill delay
- Auto-return to Base 1
- Real-time status updates
- Auto-update capability
- Game window focus management
- CAPTCHA Detection
- Pause-time base editing
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
        
        LV_GetText(selectedRow, 1, 1)
        if (selectedRow = "")
            LV_Modify(1, "Select")
    }
    
    if (total = 0)
        GuiControl,, StatusText, Press F10 over the unit you want to build
    else if (building)
        GuiControl,, StatusText, Building in progress...
    else
    {
        resDelayText := ""
        if (resourceDelay > 0)
            resDelayText := " | Resource delay: " resourceDelay "s"
        GuiControl,, StatusText, %total% base(s) recorded%resDelayText% - Press F11 to execute
    }
    
    GuiControl,, EditResourceDelay, %resourceDelay%
return

BtnUpdateBase:
    if (!isPaused || !building)
    {
        MsgBox, You can only edit bases while the script is PAUSED and BUILDING.
        return
    }
    
    Gui, Submit, NoHide
    
    baseNum := EditBaseNumber
    newUnits := EditUnits
    newDelay := EditDelay
    
    if (baseNum = "" || newUnits = "" || newDelay = "")
    {
        MsgBox, Please fill in all fields.
        return
    }
    
    total := bases.MaxIndex()
    if (baseNum < 1 || baseNum > total)
    {
        MsgBox, Invalid base number. Must be between 1 and %total%.
        return
    }
    
    if (newUnits <= 0)
    {
        MsgBox, Units must be greater than 0.
        return
    }
    
    if (newDelay < 0)
    {
        MsgBox, Delay cannot be negative.
        return
    }
    
    baseObj := bases[baseNum]
    oldUnits := baseObj.units
    baseObj.units := newUnits
    
    if (baseObj.haskey("remaining") && building)
    {
        oldRemaining := baseObj.remaining
        diff := newUnits - oldUnits
        baseObj.remaining := Max(0, oldRemaining + diff)
    }
    else
    {
        baseObj.remaining := newUnits
    }
    
    baseObj.delay := newDelay
    
    Gosub, UpdateGUI
    UpdateStatus("Base " . baseNum . " updated: " . newUnits . " units, " . newDelay . "s delay")
    
    GuiControl,, EditUnits,
    GuiControl,, EditDelay,
return

BtnRefreshList:
    Gosub, UpdateGUI
    UpdateStatus("Base list refreshed")
return

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
                resourceDelay := 0
            else if (resourceDelay < 0)
            {
                MsgBox, Invalid delay - setting to 0
                resourceDelay := 0
            }
            GuiControl,, EditResourceDelay, %resourceDelay%
        }
        else
        {
            resourceDelay := 0
            GuiControl,, EditResourceDelay, 0
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
            newBase.arrows[A_Index] := arrowKeys[A_Index]
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
            MsgBox, Recording complete!`n`n1 base recorded.`n`nPress F11 to start building, or save this configuration for later use.
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
                            Sleep, 200
                        }
                    }
                }
            }
            
            Sleep, 500
            MsgBox, 4, Ready!, Returned to Base 1!`n`nPress F11 to start building, or save this configuration?`n`nYes = Save configuration`nNo = Continue without saving
            
            IfMsgBox Yes
                Gosub, BtnSaveConfig
        }
        else
            MsgBox, Recording complete!`n`n%total% base recorded.`n`nPress F11 to start building, or save this configuration for later use.
    }
return

BtnExecute:
    total := bases.MaxIndex()
    if total is not number
        total := 0
    
    if (total = 0)
    {
        MsgBox, No bases recorded!`n`nYou can either:`n1. Record new bases with F10`n2. Load a saved configuration
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
    Sleep, 1000
    UpdateStatus("Starting macro in 2...")
    Sleep, 1000
    UpdateStatus("Starting macro in 1...")
    Sleep, 1000
    UpdateStatus("Starting now! Remove mouse...")
    Sleep, 500
    ToolTip
    
    building := true
    isPaused := false
    restartCycle := false
    captchaDetectedAtBase := 0
    
    remaining := Object()
    lastBuildTime := Object()
    
    Loop, %total%
    {
        baseObj := bases[A_Index]
        remaining[A_Index] := baseObj.units
        lastBuildTime[A_Index] := 0
    }
    
    Loop
    {
        while (isPaused)
            Sleep, 100
        
        if (!building)
            break
        
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
                    
                    while (A_TickCount < targetTime && !restartCycle && !isPaused && building)
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
                        
                        if (restartCycle || isPaused || !building)
                            break
                    }
                    
                    if (!restartCycle && !isPaused && building)
                        UpdateStatus("Base 1 ready!")
                }
            }
            
            if (!building)
                break
            
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
                    timeSinceLastBuild := (4294967295 - lastBuildTime[1]) + currentTime
                
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
                        
                        while (A_TickCount < targetTime && !restartCycle && !isPaused && building)
                        {
                            currentTime := A_TickCount
                            timeRemaining := targetTime - currentTime
                            
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
                            
                            if (restartCycle || isPaused || !building)
                            {
                                UpdateStatus("Wait interrupted...")
                                break
                            }
                        }
                        
                        if (!restartCycle && !isPaused && building)
                            UpdateStatus("Base 1 ready!", true)
                        
                        if (restartCycle || isPaused || !building)
                            continue
                    }
                    continue
                }
            }
        }
        
        if (!building)
            break
        
        Loop, %total%
        {
            while (isPaused && building)
                Sleep, 100
            
            if (!building)
                break
            
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
                        if (!building)
                            break
                        
                        arrow := baseObj.arrows[A_Index]
                        
                        if (Mod(A_Index, 3) = 0)
                            EnsureGameFocus()
                        
                        SendInput, {%arrow%}
                        Sleep, 200
                    }
                }
                
                if (!building)
                    break
                
                Sleep, 1000
            }
            
            if (!building)
                break
            
            remCount := remaining[i]
            UpdateStatus("Building at Base " . i . " - Remaining: " . remCount, true)
            EnsureGameFocus()
            Sleep, 200
            
            MouseMove, baseObj.x + 5, baseObj.y + 5, 0
            Sleep, 50
            MouseMove, baseObj.x, baseObj.y, 0
            Sleep, 150
            
            lastClickedBase := i
            lastClickedX := baseObj.x
            lastClickedY := baseObj.y
            
            EnsureGameFocus()
            Sleep, 100
            Click
            Sleep, 100
            Click
            Sleep, 100
            
            remaining[i] := remaining[i] - 1
            lastBuildTime[i] := A_TickCount
            
            baseObj.remaining := remaining[i]
            if (Mod(i, 2) = 0 || i = 1)
                Gosub, UpdateGUI
            
            Sleep, 2000
            
            if (!building)
                break
            
            if (CheckForDarkScreen()) {
                isPaused := true
                beepTimerActive := true
                captchaDetectedAtBase := i
                UpdateStatus("CAPTCHA DETECTED - Script PAUSED", true)
                
                SoundPlay, %A_WinDir%\Media\Windows Notify.wav
                Sleep, 300
                SoundBeep, 800, 500
                Sleep, 300
                SoundBeep, 600, 500
                
                ShowTooltip("CAPTCHA DETECTED!`n`nScript PAUSED automatically.`n`n1. Solve the CAPTCHA`n2. Press F12 to resume`n`nBeep will repeat every 10 seconds")
                
                SetTimer, RepeatBeepAlert, %beepTimerInterval%
                
                while (isPaused && building)
                    Sleep, 100
                
                SetTimer, RepeatBeepAlert, Off
                beepTimerActive := false
                
                if (!building)
                    break
                
                UpdateStatus("Resuming after CAPTCHA...")
                ShowTooltip("Resuming...")
                Sleep, 1000
                ToolTip
            }
        }
        
        if (!building)
            break
        
        UpdateStatus("Returning to Base 1...", true)
        EnsureGameFocus()
        Sleep, 200
        
        Loop, %total%
        {
            if (!building)
                break
            
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
                    if (!building)
                        break
                    
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
                    Sleep, 200
                }
            }
            
            Sleep, 500
        }
        
        if (!building)
            break
        
        Sleep, 500
        
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
                
                while (A_TickCount < targetTime && !restartCycle && !isPaused && building)
                {
                    currentTime := A_TickCount
                    timeRemaining := targetTime - currentTime
                    
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
                    
                    if (restartCycle || isPaused || !building)
                    {
                        UpdateStatus("Resource wait interrupted...")
                        break
                    }
                }
                
                if (!restartCycle && !isPaused && building)
                {
                    EnsureGameFocus()
                    Sleep, 200
                    UpdateStatus("Resources ready - continuing...")
                    Sleep, 500
                }
            }
        }
        
        if (!building)
            break
        
        if (!restartCycle && !isPaused)
            Gosub, UpdateGUI
    }
    
    building := false
    isPaused := false
    UpdateStatus("Build complete! All units finished.")
    ToolTip
    
    if (building = false)
        MsgBox, All units completed at %total% bases!
return

RestartCycle:
    if (building)
    {
        restartCycle := true
        ShowTooltip("Cycle restart requested...")
        Sleep, 1000
        ToolTip
    }
return

BtnClear:
    if building
    {
        MsgBox, 4, Stop Building?, This will IMMEDIATELY STOP the current build cycle and clear all bases.`n`nAre you sure?
        IfMsgBox No
            return
        
        CompleteReset()
        
        UpdateStatus("Build stopped - all bases cleared")
        MsgBox, 64, Build Stopped, Build cycle stopped immediately!`n`nAll bases have been cleared.`nAll timers reset.`n`nReady to record a new sequence.
        return
    }
    else
    {
        MsgBox, 4, Clear, Clear all bases?
        IfMsgBox No
            return
    }
    
    CompleteReset()
    UpdateStatus("All bases cleared - ready to record new sequence")
    MsgBox, Cleared!
return

BtnExit:
GuiClose:
    ExitApp
