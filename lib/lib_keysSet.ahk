
; Lib_keysSet.ahk - V2 Refactored (Map Iteration)

keysInit() {
    global keyset, CLSets
    
    if (CLSets.Has("Keys"))
        keyset := CLSets["Keys"] 
    else {
        CLSets["Keys"] := Map()
        keyset := CLSets["Keys"]
    }

    if(!CLSets["Global"].Has("default_hotkey_scheme"))
        CLSets["Global"]["default_hotkey_scheme"] := "capslox"

    if(CLSets["Global"]["default_hotkey_scheme"] == "capslock_plus") {
        keySchemeInit_capslockPlus()
    } else {
        keySchemeInit_capslox()
    }
}

keySchemeInit_capslockPlus() {
    keySchemeInit_capslox()
}

keySchemeInit_capslox(){
    global keyset
    
    ; Define defaults in a Map
    defaults := Map(
        "press_caps", "keyFunc_toggleCapsLock",
        "caps_a", "keyFunc_moveWordLeft",
        "caps_b", "keyFunc_moveDown(10)",
        "caps_c", "keyFunc_copy_1",
        "caps_d", "keyFunc_moveDown",
        "caps_e", "keyFunc_moveUp",
        "caps_f", "keyFunc_moveRight",
        "caps_g", "keyFunc_moveWordRight",
        "caps_h", "keyFunc_selectWordLeft",
        "caps_i", "keyFunc_selectUp",
        "caps_j", "keyFunc_selectLeft",
        "caps_k", "keyFunc_selectDown",
        "caps_l", "keyFunc_selectRight",
        "caps_m", "keyFunc_selectWordRight",
        "caps_n", "keyFunc_selectDown(10)",
        "caps_o", "keyFunc_selectEnd",
        "caps_p", "keyFunc_home",
        "caps_q", "keyFunc_qbar",
        "caps_r", "keyFunc_delete",
        "caps_s", "keyFunc_moveLeft",
        "caps_t", "keyFunc_doNothing",
        "caps_u", "keyFunc_selectHome",
        "caps_v", "keyFunc_paste_1",
        "caps_w", "keyFunc_backspace",
        "caps_x", "keyFunc_cut_1",
        "caps_y", "keyFunc_selectUp(10)",
        "caps_z", "keyFunc_doNothing"
    )

    defaults.Set(
        "caps_backquote", "keyFunc_doNothing",
        "caps_1", "keyFunc_winbind_activate(1)",
        "caps_2", "keyFunc_winbind_activate(2)",
        "caps_3", "keyFunc_winbind_activate(3)",
        "caps_4", "keyFunc_winbind_activate(4)",
        "caps_5", "keyFunc_winbind_activate(5)",
        "caps_6", "keyFunc_winbind_activate(6)",
        "caps_7", "keyFunc_winbind_activate(7)",
        "caps_8", "keyFunc_winbind_activate(8)",
        "caps_9", "keyFunc_winbind_activate(9)",
        "caps_0", "keyFunc_winbind_activate(10)",
        "caps_minus", "keyFunc_qbar_upperFolderPath",
        "caps_equal", "keyFunc_qbar_lowerFolderPath",
        "caps_backspace", "keyFunc_deleteLine",
        "caps_tab", "keyFunc_tabScript",
        "caps_leftSquareBracket", "keyFunc_deleteToLineBeginning",
        "caps_rightSquareBracket", "keyFunc_doNothing",
        "caps_backslash", "keyFunc_doNothing",
        "caps_semicolon", "keyFunc_end",
        "caps_quote", "keyFunc_doNothing",
        "caps_enter", "keyFunc_enterWherever",
        "caps_comma", "keyFunc_selectCurrentWord",
        "caps_dot", "keyFunc_selectWordRight",
        "caps_slash", "keyFunc_deleteToLineEnd",
        "caps_space", "keyFunc_enter",
        "caps_ralt", "keyFunc_doNothing"
    )

    defaults.Set(
        "caps_f1", "keyFunc_openCpasDocs",
        "caps_f2", "keyFunc_mathBoard",
        "caps_f3", "keyFunc_translate",
        "caps_f4", "keyFunc_winTransparent",
        "caps_f5", "keyFunc_reload",
        "caps_f6", "keyFunc_winPin",
        "caps_f7", "keyFunc_doNothing",
        "caps_f8", "keyFunc_getJSEvalString",
        "caps_f9", "keyFunc_doNothing",
        "caps_f10", "keyFunc_doNothing",
        "caps_f11", "keyFunc_doNothing",
        "caps_f12", "keyFunc_switchClipboard"
    )

    defaults.Set(
        "caps_lalt_a", "keyFunc_moveWordLeft(3)",
        "caps_lalt_b", "keyFunc_moveDown(30)",
        "caps_lalt_c", "keyFunc_copy_2",
        "caps_lalt_d", "keyFunc_moveDown(3)",
        "caps_lalt_e", "keyFunc_moveUp(3)",
        "caps_lalt_f", "keyFunc_moveRight(5)",
        "caps_lalt_g", "keyFunc_moveWordRight(3)",
        "caps_lalt_h", "keyFunc_selectWordLeft(3)",
        "caps_lalt_i", "keyFunc_selectUp(3)",
        "caps_lalt_j", "keyFunc_selectLeft(5)",
        "caps_lalt_k", "keyFunc_selectDown(3)",
        "caps_lalt_l", "keyFunc_selectRight(5)",
        "caps_lalt_m", "keyFunc_selectWordRight(3)",
        "caps_lalt_n", "keyFunc_selectDown(30)",
        "caps_lalt_o", "keyFunc_selectToPageEnd",
        "caps_lalt_p", "keyFunc_moveToPageBeginning",
        "caps_lalt_q", "keyFunc_doNothing",
        "caps_lalt_r", "keyFunc_forwardDeleteWord",
        "caps_lalt_s", "keyFunc_moveLeft(5)",
        "caps_lalt_t", "keyFunc_moveUp(30)",
        "caps_lalt_u", "keyFunc_selectToPageBeginning",
        "caps_lalt_v", "keyFunc_paste_2",
        "caps_lalt_w", "keyFunc_deleteWord",
        "caps_lalt_x", "keyFunc_cut_2",
        "caps_lalt_y", "keyFunc_selectUp(30)",
        "caps_lalt_z", "keyFunc_doNothing"
    )

    defaults.Set(
        "caps_lalt_backquote", "keyFunc_doNothing",
        "caps_lalt_1", "keyFunc_winbind_binding(1)",
        "caps_lalt_2", "keyFunc_winbind_binding(2)",
        "caps_lalt_3", "keyFunc_winbind_binding(3)",
        "caps_lalt_4", "keyFunc_winbind_binding(4)",
        "caps_lalt_5", "keyFunc_winbind_binding(5)",
        "caps_lalt_6", "keyFunc_winbind_binding(6)",
        "caps_lalt_7", "keyFunc_winbind_binding(7)",
        "caps_lalt_8", "keyFunc_winbind_binding(8)",
        "caps_lalt_9", "keyFunc_winbind_binding(9)",
        "caps_lalt_0", "keyFunc_winbind_binding(10)",
        "caps_lalt_minus", "keyFunc_jumpPageTop",
        "caps_lalt_equal", "keyFunc_jumpPageBottom",
        "caps_lalt_backspace", "keyFunc_deleteAll",
        "caps_lalt_tab", "keyFunc_doNothing",
        "caps_lalt_leftSquareBracket", "keyFunc_deleteToPageBeginning",
        "caps_lalt_rightSquareBracket", "keyFunc_doNothing",
        "caps_lalt_backslash", "keyFunc_doNothing",
        "caps_lalt_semicolon", "keyFunc_moveToPageEnd",
        "caps_lalt_quote", "keyFunc_doNothing",
        "caps_lalt_enter", "keyFunc_doNothing",
        "caps_lalt_comma", "keyFunc_selectCurrentLine",
        "caps_lalt_dot", "keyFunc_selectWordRight(3)",
        "caps_lalt_slash", "keyFunc_deleteToPageEnd",
        "caps_lalt_space", "keyFunc_doNothing",
        "caps_lalt_ralt", "keyFunc_doNothing",
        "caps_lalt_wheelUp", "keyFunc_mouseSpeedIncrease",
        "caps_lalt_wheelDown", "keyFunc_mouseSpeedDecrease",
        "caps_lwin_1", "keyFunc_winbind_binding(1)",
        "caps_lwin_2", "keyFunc_winbind_binding(2)",
        "caps_lwin_3", "keyFunc_winbind_binding(3)",
        "caps_lwin_4", "keyFunc_winbind_binding(4)",
        "caps_lwin_5", "keyFunc_winbind_binding(5)",
        "caps_lwin_6", "keyFunc_winbind_binding(6)",
        "caps_lwin_7", "keyFunc_winbind_binding(7)",
        "caps_lwin_8", "keyFunc_winbind_binding(8)",
        "caps_lwin_9", "keyFunc_winbind_binding(9)",
        "caps_lwin_0", "keyFunc_winbind_binding(10)"
    )

    for k, v in defaults
        if !keyset.Has(k)
            keyset[k] := v
}