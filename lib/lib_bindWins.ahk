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

    ; Try to convert to integer - if it fails, skip
    try {
      n := Integer(sectionValue)
    } catch {
      continue
    }

    if (!winsInfos.Has(n))
      initWinsInfos(n)

    try {
      infosKeys := IniRead(winsInfosRecorderPath, sectionValue)
    } catch {
      continue
    }

    keyArr := StrSplit(infosKeys, "`n")
    tempData := Map("class", Map(), "exe", Map(), "id", Map())

    for keyValue in keyArr {
      val := StrSplit(keyValue, "=")
      if (val.Length < 2)
        continue

      k := val[1]
      v := val[2]

      if (k == "bindType") {
        try {
          winsInfos[n]["bindType"] := Integer(v)
        }
      } else {
        parts := StrSplit(k, "_")
        if (parts.Length == 2) {
          type := parts[1]
          if (tempData.Has(type)) {
            idx := Integer(parts[2]) + 1
            tempData[type][idx] := v
          }
        }
      }
    }

    ; Populate arrays in order
    for type, indices in tempData {
      maxIdx := 0
      for i, _ in indices {
        if (i > maxIdx)
          maxIdx := i
      }
      Loop maxIdx {
        val := indices.Has(A_Index) ? indices[A_Index] : ""
        winsInfos[n][type].Push(val)
      }
    }
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
        try IniDelete(winsInfosRecorderPath, btnx, "class_" . i)
        try IniDelete(winsInfosRecorderPath, btnx, "exe_" . i)
        try IniDelete(winsInfosRecorderPath, btnx, "id_" . i)
        i++
      }
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
    }
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
    getWinInfo(winBtnx, tTapTimesx)
  }

  tapTimes[winBtnx] := 0
  tapTimes["btn"] := -1
  gettingWinInfo := 0
}

RemoveToolTip() {
    CLTheme_HideToast()
}
