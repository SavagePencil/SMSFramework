.STRUCT ApplicationMode
    OnVideoInterrupt    DW      ; The video interrupt handler
    OnNMI               DW      ; Called when a non-maskable interrupt (NMI) comes in.
    OnEnter             DW      ; Called when this mode is entered.
    OnExit              DW      ; Called when exited
    OnUpdate            DW      ; Called when the application wants to update
    OnRender            DW      ; Called when the application is about to render
    OnEvent             DW      ; Called when a generic event occurs
.ENDST

.DEFINE MODEMANAGER_MAX_MODE_DEPTH 4    ; Max #/modes allowed
.STRUCT ModeManagerDefinition
    ModeManager_CurrMode        DW                              ; Pointer to current mode
    ModeManager_CurrModeIndex   DB                              ; Depth of stack
    ModeManager_Stack           DSW MODEMANAGER_MAX_MODE_DEPTH  ; Stack entires
.ENDST

.RAMSECTION "Mode Manager" SLOT 3
    gModeManager INSTANCEOF ModeManagerDefinition
.ENDS 