/*
PoE Kingsmarch Dust Calculator
Copyright (c) 2026 TeeraThew

This software is released under the MIT License.
https://opensource.org/licenses/MIT
*/

#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================
; CONFIG
; =========================
UPDATE_INTERVAL_HOURS := 24
MIN_EXPECTED_ROWS := 100

; A_ScriptDir is "...\PoE-Dust-Calculator\src"
; We go one level up to get the Project Root
PROJECT_ROOT := RegExReplace(A_ScriptDir, "\\[^\\]+$") 

; Define folders
DATA_DIR := PROJECT_ROOT "\data"
LOG_DIR  := PROJECT_ROOT "\logs" ; Optional: Separate logs folder

; Create folders if they don't exist
if !DirExist(DATA_DIR)
    DirCreate(DATA_DIR)

FilePATH := DATA_DIR "\dust_values.data"
MetaPATH := DATA_DIR "\dust_meta.ini"
LogPATH  := DATA_DIR "\dust_log.txt"

LogMsg(msg) {
    try FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " - " msg "`n", LogPATH, "UTF-8")
}

; =========================
; INIT
; =========================
InitData()
DustMap := LoadDustMap(FilePATH)
LogMsg("Final Map Count: " DustMap.Count " items.")

; =========================
; Dust Multiplier Function 
; =========================
GetDustMultiplier(lvl) {
    ; lvl. 84 - 100
    if (lvl >= 84)
        return 2500
    
    ; lvl. 69 - 83 (The linear scaling up to 84)
    if (lvl >= 69)
        return 500 + 125 * (lvl - 68)
    
    ; lvl. 47 - 68: Case-by-case mapping
    if (lvl >= 47) {
        switch lvl {
            case 47: return 260
            case 48: return 270
            case 49: return 280
            case 50: return 295
            case 51: return 305
            case 52: return 315
            case 53: return 325
            case 54: return 340
            case 55: return 350
            case 56: return 360
            case 57: return 375
            case 58: return 385
            case 59: return 395
            case 60: return 405
            case 61: return 420
            case 62: return 430
            case 63: return 440
            case 64: return 450
            case 65: return 465
            case 66: return 475
            case 67: return 485
            case 68: return 500
        }
    }
    
    ; lvl. 1 - 46
    return 250
}

; =========================
; HOTKEY (F4)
; =========================
F4:: {
    A_Clipboard := ""
    ; ; Default to Advanced Description (Ctrl+Alt+C) for better parsing 
    ; Send("^!c") ; Path of Exile Advanced Description (Ctrl+Alt+C)
    Send("^c") ; Path of Exile Advanced Description (Ctrl+C)

    if !ClipWait(1.5) {
        return
    }

    text := A_Clipboard
    lines := StrSplit(text, "`n", "`r")
    
    ItemName := ""
    ItemQuality := 0
    ItemLevel := 0
    isUnique := false

    ; Improved Name and Data Parsing
    for i, line in lines {
        if InStr(line, "Rarity: Unique") {
            isUnique := true
            if lines.Has(i + 1)
                ItemName := Trim(lines[i+1])
        }
        if RegExMatch(line, "Quality: \+(\d+)%", &m)
            ItemQuality := Number(m[1])
        if RegExMatch(line, "Item Level: (\d+)", &m)
            ItemLevel := Number(m[1])
    }

    if (!isUnique || ItemName = "")
        return

    ; Strip "Foulborn " prefix
    ItemName := RegExReplace(ItemName, "^Foulborn\s+", "")

    if !DustMap.Has(ItemName) {
        LogMsg("Item not found in Map: [" ItemName "]")
        ; Show a small warning so you know it was triggered
        ToolTip("Item not in database: " ItemName)
        SetTimer(() => ToolTip(), 2000)
        return
    }
    
    ; --- CORRUPTION AND INFLUENCE ---
    CorruptCount := 0
    StrReplace(text, "Corruption Implicit Modifier", , , &CorruptCount)
    isCorrupt := InStr(text, "Corrupted")

    influences := ["Elder","Shaper","Crusader","Redeemer","Hunter","Warlord"]
    TotalInf := 0
    ActiveInfluences := ""
    for inf in influences {
        if InStr(text, inf " Item") {
            TotalInf++
            ActiveInfluences .= (ActiveInfluences ? " | " : "") inf
        }
    }

    ; --- CALCULATIONS ---
    BaseValue := DustMap[ItemName]
    LevelMultiplier := GetDustMultiplier(ItemLevel)
    
    ; 1. Calculate Base Dust Total
    BaseDustTotal := Floor(BaseValue * LevelMultiplier)
    
    ; 2. Define Multipliers
    ; Quality: 1% = 0.02 multiplier
    ; Influence: +50% per influence (0.50)
    ; Corruption: +50% per implicit (0.50)
    QualityBonus := ItemQuality * 0.02
    Q20Bonus     := 0.40
    InfBonus := TotalInf * 0.50
    CorruptBonus := CorruptCount * 0.50
    
    ; Calculate Final Values
    BonusNormal := 1 + QualityBonus + InfBonus + CorruptBonus
    BonusQ20 := 1 + Q20Bonus + InfBonus + CorruptBonus
    
    FinalNormal := Floor(BaseDustTotal * BonusNormal)
    FinalQ20 := Floor(BaseDustTotal * BonusQ20)
    Gain := FinalQ20 - FinalNormal

    ShowGui(ItemName, FormatNumber(FinalNormal), FormatNumber(FinalQ20), FormatNumber(Gain), ItemLevel, ItemQuality, ActiveInfluences, isCorrupt, CorruptCount)
}

; =========================
; DATA SCRAPER
; =========================
DownloadDustValues(path) {
    URL := "https://poedb.tw/us/Kingsmarch"
    LogMsg("Connecting to PoeDB...")
    
    try {
        Http := ComObject("WinHttp.WinHttpRequest.5.1")
        Http.Open("GET", URL, true)
        Http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        Http.Send()
        Http.WaitForResponse()
        html := Http.ResponseText
    } catch {
        LogMsg("Network Error: Could not reach website.")
        return false
    }

    tempFile := path ".tmp"
    if FileExist(tempFile)
        FileDelete(tempFile)

    count := 0
    ; Specific Regex for the HTML <tr> structure you provided
    pos := 1
    while pos := RegExMatch(html, 's)<td><a[^>]*>([^<]+)</a></td><td>([\d\.]+)</td>', &m, pos) {
        itemName := m[1]
        itemVal  := m[2]
        
        ; Clean HTML entities (e.g. &#39; to ')
        itemName := StrReplace(itemName, "&#39;", "'")
        itemName := StrReplace(itemName, "&amp;", "&")
        
        FileAppend(itemName "," itemVal "`n", tempFile, "UTF-8")
        pos += m.Len
        count++
    }

    if (count < MIN_EXPECTED_ROWS) {
        LogMsg("Scrape failed: Too few items found (" count ").")
        return false
    }

    if FileExist(path)
        FileDelete(path)
    FileMove(tempFile, path)
    LogMsg("Scrape Success: Found " count " items.")
    return true
}

; =========================
; DATA LOADER
; =========================
LoadDustMap(path) {
    dm := Map()
    if !FileExist(path)
        return dm
    
    try {
        fileContent := FileRead(path, "UTF-8")
        loop parse fileContent, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line = "" || !InStr(line, ","))
                continue
            
            parts := StrSplit(line, ",")
            if (parts.Length >= 2) {
                name := Trim(parts[1])
                val := Trim(parts[2])
                if (name != "" && IsNumber(val))
                    dm[name] := Float(val)
            }
        }
    } catch Error as e {
        LogMsg("Error reading file: " e.Message)
    }
    return dm
}

InitData() {
    if !FileExist(FilePATH) || ShouldUpdateData() {
        if !DownloadDustValues(FilePATH) {
            LogMsg("Using existing data (if any) because update failed.")
        } else {
            SaveUpdateTimestamp()
        }
    }
}

ShouldUpdateData() {
    if !FileExist(MetaPATH)
        return true
    lastUpdate := IniRead(MetaPATH, "meta", "last_update", 0)
    try return DateDiff(A_Now, lastUpdate, "Hours") >= UPDATE_INTERVAL_HOURS
    catch
        return true
}

SaveUpdateTimestamp() {
    IniWrite(A_Now, MetaPATH, "meta", "last_update")
}

FormatNumber(num) {
    return RegExReplace(Round(num), "\d(?=(\d{3})+$)", "$0,")
}

; =========================
; GUI 
; =========================

; GLOBAL GUI TRACKER
global DustGuiObj := 0

; =========================
; GUI FUNCTION
; =========================
ShowGui(name, current, q20, gain, lvl, quality, inf, isCorrupt, cCount := 0) {
    global DustGuiObj
    
    ; If a GUI is already open, destroy it first
    if DustGuiObj
        DustGuiObj.Destroy()

    ; Create new GUI
    DustGuiObj := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    DustGuiObj.BackColor := "1A1A1A"

    ; Set styling (Item Name)
    DustGuiObj.SetFont("s12 w700 cFF9900")
    DustGuiObj.AddText("x15 y10 w270", name)

    ; Current Dust Value
    DustGuiObj.SetFont("s14 cFFFFFF")
    DustGuiObj.AddText("x15 y+5", "Dust:")
    DustGuiObj.SetFont("s14 w700 cfff022")
    DustGuiObj.AddText("x+10", current)

    ; Quality Bonus Info
    if (quality < 20) {
        DustGuiObj.SetFont("s11 c0dff00")
        DustGuiObj.AddText("x15 y+5", "At Q20%:")
        DustGuiObj.AddText("x+5", q20 " (+" gain ")")
    }

    ; --- TAGS CONSTRUCTION (Lvl | Quality | Influence | Corruption) ---
    ; 1. Level (White)
    DustGuiObj.SetFont("s8 cffffff")
    DustGuiObj.AddText("x15 y+10", "Lvl. " lvl)

    ; 2. Quality (Greenish)
    if (quality) {
        DustGuiObj.SetFont("s8 c666666") ; Separator color
        DustGuiObj.AddText("x+5", "|")
        DustGuiObj.SetFont("s8 c2fff44")
        DustGuiObj.AddText("x+5", "Q: " quality "%")
    }

    ; 3. Influence (Cyan)
    if (inf) {
        DustGuiObj.SetFont("s8 c666666") ; Separator
        DustGuiObj.AddText("x+5", "|")
        DustGuiObj.SetFont("s8 c65f0f0")
        DustGuiObj.AddText("x+5", inf)
    }

    ; 4. Corruption (Red)
    if (isCorrupt || cCount > 0) {
        DustGuiObj.SetFont("s8 c666666") ; Separator
        DustGuiObj.AddText("x+5", "|")
        DustGuiObj.SetFont("s8 cff0000")
        
        cText := (cCount == 1) ? "1 Corrupted Implicit" 
               : (cCount >= 2) ? cCount " Corrupted Implicits" 
               : "Corrupted"
        
        DustGuiObj.AddText("x+5", cText)
    }

    ; --- POSITIONING AND SHOW ---
    DustGuiObj.Show("Hide")
    DustGuiObj.GetPos(,, &guiW, &guiH)
    MouseGetPos(&mx, &my)
    
    offset := 20
    posX := (mx + offset + guiW > A_ScreenWidth) ? (mx - guiW - offset) : (mx + offset)
    posY := (my + offset + guiH > A_ScreenHeight) ? (my - guiH - offset) : (my + offset)

    DustGuiObj.Show("x" posX " y" posY " NoActivate")
    WinSetTransparent(235, DustGuiObj.Hwnd)
    
    ; Auto-close after 2 second
    SetTimer(CloseDustGui, -2000)
}

; Function to close and reset
CloseDustGui() {
    global DustGuiObj
    if DustGuiObj {
        DustGuiObj.Destroy()
        DustGuiObj := 0
    }
}

; =========================
; CLICK TO CLOSE
; =========================
#HotIf DustGuiObj 
~LButton::
~RButton:: {
    CloseDustGui()
}
#HotIf