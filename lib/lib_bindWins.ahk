; lib_bindWins.ahk - V2 Refactor
; Handles Window Binding (CapsLock + Alt + 1-9)

global winsInfos := Map()
global tapTimes := Map()
; Initialize tapTimes for keys 1-20 and 'btn'
Loop 20 {
  tapTimes[A_Index] := 0
}
tapTimes["btn"] := -1

global winTapedX := -1 ; Used to determine which key was just used for switching
global lastActiveWinId := 0
global gettingWinInfo := 0
global winsInfosRecorderPath := "CapsLock+winsInfosRecorder.ini"

; Initialize info structure for a specific key index
initWinsInfos(n) {
  global winsInfos
  winsInfos[n] := Map()
  winsInfos[n]["class"] := []
  winsInfos[n]["exe"] := []
  winsInfos[n]["id"] := []
  winsInfos[n]["bindType"] := 0
}

bindWinsInit() {
  global winsInfos, winsInfosRecorderPath, tapTimes

  if !FileExist(winsInfosRecorderPath) {
    try FileAppend("", winsInfosRecorderPath, "UTF-16")
  }

  ; Initialize maps for 1-20
  Loop 20 {
    initWinsInfos(A_Index)
  }

  try {
    infosSections := IniRead(winsInfosRecorderPath)
  } catch {
    infosSections := ""
  }

  sectionArr := StrSplit(infosSections, "`n")

  for sectionValue in sectionArr {
    if (sectionValue == "")
      continue

    try {
      infosKeys := IniRead(winsInfosRecorderPath, sectionValue)
    } catch {
      continue
    }

    ; sectionValue is the key index (e.g. "1", "2")
    ; But code below uses sectionValue as index.
    if (!IsInteger(sectionValue))
      continue

    n := Integer(sectionValue)
    if (!winsInfos.Has(n))
      initWinsInfos(n)

    keyArr := StrSplit(infosKeys, "`n")

    for keyValue in keyArr {
      val := StrSplit(keyValue, "=")
      if (val.Length < 2)
        continue

      k := val[1]
      v := val[2]

      if (k == "bindType") {
        winsInfos[n]["bindType"] := Integer(v)
      } else {
        ; format: class_0, exe_1, id_0
        parts := StrSplit(k, "_")
        if (parts.Length == 2) {
          type := parts[1] ; class, exe, id
          idx := Integer(parts[2]) + 1 ; V1 0-based -> V2 1-based logic

          if (type == "class" || type == "exe" || type == "id") {
            ; Ensure array is large enough?
            ; V2 arrays handle inserts, but better to just push or set direct if index known.
            ; Since ini might not be ordered, direct assignment is safer if we pre-fill?
            ; Let's just use direct assignment but be careful of gaps.
            ; V1 code used pseudo-arrays.
            ; To match V1 logic: "index" in ini is 0-based.

            ; Adjust array size if needed (simplistic approach: direct set allowed in Map, but here it's Array)
            ; Arrays in V2 are strictly indexed 1..Length.
            ; If we get "id_5" before "id_0", simply setting arr[6] throws if length < 5.
            ; So we should parse everything first or just use a temporary Map then convert to Array?
            ; Or just use Map for these internals?
            ; winsInfos[n][type] is [] (Array).

            ; Let's assume sequential reading mostly, but better to use Map for temporary loading if indices are sparse (unlikely for valid data).
            ; Actually, let's use the .Push() approach if indices are 0, 1, 2... sorted.
            ; But IniRead order isn't guaranteed.

            ; Re-read specific keys by expected index might be safer than iterating keys.
            ; But iterating keys is faster.

            ; Let's try to set it.
            if (winsInfos[n][type].Length < idx) {
              winsInfos[n][type].Length := idx
            }
            winsInfos[n][type][idx] := v
          }
        }
      }
    }

    ; Filter out empty slots if any?
  }
}

getWinInfo(btnx, bindType) {
  global winsInfos, winsInfosRecorderPath

  winId := WinExist("A")
  if (!winId)
    return

  winClass := WinGetClass("ahk_id " . winId)
  winExe := WinGetProcessPath("ahk_id " . winId)

  infosGx := winsInfos[btnx]

  if (bindType == 1) ; Single Window
  {
    infosGx["bindType"] := 1
    infosGx["id"] := [winId]
    infosGx["class"] := [winClass]
    infosGx["exe"] := [winExe]

    if FileExist(winsInfosRecorderPath) {
      IniWrite(1, winsInfosRecorderPath, btnx, "bindType")
      IniWrite(winClass, winsInfosRecorderPath, btnx, "class_0")
      IniWrite(winExe, winsInfosRecorderPath, btnx, "exe_0")
      IniWrite(winId, winsInfosRecorderPath, btnx, "id_0")

      ; Clean up old entries (1 to ...)
      i := 1
      Loop {
        if (i > 100) ; Safety break
          break
        ; Check if key exists to delete? brute force delete safe enough
        ; IniDelete doesn't error if key missing usually? V2 docs: "If the value cannot be written... Error"
        ; IniDelete: "deletes a value".
        try IniDelete(winsInfosRecorderPath, btnx, "class_" . i)
        try IniDelete(winsInfosRecorderPath, btnx, "exe_" . i)
        try IniDelete(winsInfosRecorderPath, btnx, "id_" . i)
        
        i++
      }
        ; We don't know how many there were, so this loop is heuristic.
        ; A better way is to read all keys and delete them, but AHK V2 IniDelete section is easier?
        ; But we want to keep bindType? No, bindType is overwritten.
        ; Wait, if we assume 1 index, we only need to write _0.
        ; The V1 code loop: "loop, % infosGx.id.MaxIndex()" (removes others).

        ; Let's just delete the section and rewrite for cleanliness?
        ; But we just wrote key_0.
        ; Ideally: Delete section, Write new.
      ; Implementation choice: Delete section first, then write.
    }
    else {
      MsgBox("WIR ini missing")
      return
    }
  }
  else if (bindType == 2) ; Multi Window (Group)
  {
    if (infosGx["bindType"] == 3) { ; If was App mode, reset
      infosGx["bindType"] := 1
      infosGx["class"] := [winClass]
      infosGx["exe"] := [winExe]
      infosGx["id"] := [winId]

      ; Overwrite section
      IniDelete(winsInfosRecorderPath, btnx)
      IniWrite(1, winsInfosRecorderPath, btnx, "bindType")
      IniWrite(winClass, winsInfosRecorderPath, btnx, "class_0")
      IniWrite(winExe, winsInfosRecorderPath, btnx, "exe_0")
      IniWrite(winId, winsInfosRecorderPath, btnx, "id_0")
    }
    else {
      ; Check duplicates
      for existingId in infosGx["id"] {
        if (existingId == winId)
          return
      }

      infosGx["class"].Push(winClass)
      infosGx["exe"].Push(winExe)
      infosGx["id"].Push(winId)

      idx := infosGx["id"].Length - 1 ; 0-based for INI

      IniWrite(winClass, winsInfosRecorderPath, btnx, "class_" . idx)
      IniWrite(winExe, winsInfosRecorderPath, btnx, "exe_" . idx)
      IniWrite(winId, winsInfosRecorderPath, btnx, "id_" . idx)
      IniWrite(2, winsInfosRecorderPath, btnx, "bindType")
      infosGx["bindType"] := 2
    }
  }
  else if (bindType == 3) ; App Group
  {
    infosGx["bindType"] := 3
    ids := WinGetList("ahk_class " . winClass . " ahk_exe " . winExe)

    infosGx["class"] := [winClass]
    infosGx["exe"] := [winExe]
    infosGx["id"] := []

    ; Reset section
    IniDelete(winsInfosRecorderPath, btnx)
    IniWrite(3, winsInfosRecorderPath, btnx, "bindType")
    IniWrite(winClass, winsInfosRecorderPath, btnx, "class_0")
    IniWrite(winExe, winsInfosRecorderPath, btnx, "exe_0")

    Loop ids.Length {
      id := ids[A_Index]
      infosGx["id"].Push(id)
      IniWrite(id, winsInfosRecorderPath, btnx, "id_" . (A_Index - 1))
    }
  }
}

activateWinAction(btnx) {
  global winsInfos, winsInfosRecorderPath, gettingWinInfo, lastActiveWinId, winTapedX

  if (gettingWinInfo)
    doGetWinInfo()

  if (!winsInfos.Has(btnx))
    return

  infosGx := winsInfos[btnx]

  ; Check if uninitialized
  if (!infosGx.Has("bindType") || infosGx["bindType"] == 0)
    return

  bindType := infosGx["bindType"]

  if (bindType == 1) ; Single
  {
    if (infosGx["id"].Length == 0)
      return

    tempId := infosGx["id"][1]

    if !WinExist("ahk_id " . tempId)
    {
      tempClass := infosGx["class"][1]
      tempExe := infosGx["exe"][1]

      ; Try to find another window of same type
      try {
        tempId := WinGetID("ahk_class " . tempClass . " ahk_exe " . tempExe)
        if (tempId) {
          infosGx["id"][1] := tempId
          IniWrite(tempId, winsInfosRecorderPath, btnx, "id_0")
        }
      } catch {
        tempId := 0
      }

      if (!tempId) {
        if FileExist(tempExe) {
          try Run(tempExe)
        }
        return
      }
    }

    if WinActive("ahk_id " . tempId) {
      WinMinimize("ahk_id " . tempId)
      if (lastActiveWinId && WinExist("ahk_id " . lastActiveWinId) && lastActiveWinId != tempId) {
        try WinActivate("ahk_id " . lastActiveWinId)
      }
      return
    }

    lastActiveWinId := WinExist("A")
    WinActivate("ahk_id " . tempId)
    return
  }
  else if (bindType == 2) ; Group
  {
    winTapedX := btnx

    ; Remove closed windows
    i := infosGx["id"].Length
    while (i > 0) {
      if !WinExist("ahk_id " . infosGx["id"][i]) {
        infosGx["class"].RemoveAt(i)
        infosGx["exe"].RemoveAt(i)
        infosGx["id"].RemoveAt(i)

        idx := i - 1 ; 0-based for INI
        try IniDelete(winsInfosRecorderPath, btnx, "class_" . idx)
        try IniDelete(winsInfosRecorderPath, btnx, "exe_" . idx)
        try IniDelete(winsInfosRecorderPath, btnx, "id_" . idx)
      }
      i--
    }

    if (infosGx["id"].Length == 0) {
      ; All gone
      return
    }
    else if (infosGx["id"].Length == 1) {
      ; Downgrade to Type 1
      infosGx["bindType"] := 1
      IniWrite(1, winsInfosRecorderPath, btnx, "bindType")
      activateWinAction(btnx) ; Recurse as Type 1
      return
    }

    ; Cycle Logic
    actWinId := WinExist("A")
    found := false
    Loop infosGx["id"].Length {
      if (infosGx["id"][A_Index] == actWinId) {
        nextIdx := A_Index + 1
        if (nextIdx > infosGx["id"].Length)
          nextIdx := 1

        WinActivate("ahk_id " . infosGx["id"][nextIdx])
        found := true
        break
      }
    }

    if (!found) {
      WinActivate("ahk_id " . infosGx["id"][1])
    }
    return
  }
  else if (bindType == 3) ; App Group
  {
    winTapedX := btnx
    tempClass := infosGx["class"][1]
    tempExe := infosGx["exe"][1]

    ; Refresh List
    ids := WinGetList("ahk_class " . tempClass . " ahk_exe " . tempExe)
    if (ids.Length == 0) {
      if FileExist(tempExe) {
        Run(tempExe)
      }
      return
    }

    infosGx["id"] := []
    Loop ids.Length {
      infosGx["id"].Push(ids[A_Index])
    }

    ; Cycle Logic (Same as Type 2 basically)
    actWinId := WinExist("A")
    found := false
    Loop infosGx["id"].Length {
      if (infosGx["id"][A_Index] == actWinId) {
        nextIdx := A_Index + 1
        if (nextIdx > infosGx["id"].Length)
          nextIdx := 1

        WinActivate("ahk_id " . infosGx["id"][nextIdx])
        found := true
        break
      }
    }

    if (!found) {
      WinActivate("ahk_id " . infosGx["id"][1])
    }
  }
}

winsSort(btnx) {
  global winsInfos
  if (!winsInfos.Has(btnx))
    return

  infosGx := winsInfos[btnx]
  actWinId := WinExist("A")

  if (infosGx.Has("id") && infosGx["id"].Length > 0) {
    Loop infosGx["id"].Length {
      if (infosGx["id"][A_Index] == actWinId) {
        val := infosGx["id"].RemoveAt(A_Index)
        infosGx["id"].InsertAt(1, val)
        break
      }
    }
  }
  global winTapedX := -1
}

; Function to handle key taps
tapTimesFunc(btnx) {
  global tapTimes, gettingWinInfo

  gettingWinInfo := 1
  SetTimer(doGetWinInfo, -500)

  if IsInteger(btnx)
      btnx := Integer(btnx)

  tapTimes["btn"] := btnx

  if (tapTimes[btnx] < 1)
    tapTimes[btnx] := 1

  ; Check for rapid taps
  if (A_ThisHotkey == A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
    if (tapTimes[btnx] < 2) {
      tapTimes[btnx] := 2
    } else {
      tapTimes[btnx] := 3
      ; ToolTip("Tap: 3 (App Mode) - Btn: " . btnx)
      ; Trigger immediately on 3rd tap? V1 commented out gosub.
    }
  } else {
     ; if (tapTimes[btnx] == 1)
        ; ToolTip("Tap: 1 (Single) - Btn: " . btnx)
     ; else if (tapTimes[btnx] == 2)
        ; ToolTip("Tap: 2 (Group) - Btn: " . btnx)
  }
}

doGetWinInfo() {
  global tapTimes, gettingWinInfo
  SetTimer(doGetWinInfo, 0) ; Off

  winBtnx := tapTimes["btn"]
  if (winBtnx == -1) {
    gettingWinInfo := 0
    return
  }

  if !tapTimes.Has(winBtnx) {
      gettingWinInfo := 0
      tapTimes["btn"] := -1
      return
  }

  tTapTimesx := tapTimes[winBtnx]

  if (tTapTimesx > 0 && winBtnx > -1) {
    ; ToolTip("Executing Bind: Btn " . winBtnx . ", Type " . tTapTimesx)
    getWinInfo(winBtnx, tTapTimesx)
    ; SetTimer(RemoveToolTip, -1000)
  }

  tapTimes[winBtnx] := 0
  tapTimes["btn"] := -1
  gettingWinInfo := 0
}

RemoveToolTip() {
    ToolTip()
}