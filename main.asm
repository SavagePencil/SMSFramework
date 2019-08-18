.include "boot.asm"
.include "interrupts.asm"
.include "FSM.asm"
.include "vdp.asm"


.SECTION "Application Bootstrap" FREE
; This routine sets up an initial state as part of the bootstrapping.
; It should set a mode for the initial program.
Application_Bootstrap:
    ; Setup the VDP
    call    VDPManager_Init

    ; Set our initial mode
    ld      de, Mode1
    call    ModeManager_Init

; Mode Testing
_Application_Bootstrap_ModeTesting:
    ld      de, Mode2
    call    ModeManager_PushMode

    call    ModeManager_PopMode
    call    ModeManager_OnUpdate

; FSM Testing
_Application_Bootstrap_FSMTesting:
    ld      ix, gMyFSM
    ld      hl, MyFSM_State1
    call    FSM_Init
    call    FSM_OnUpdate
    ld      hl, MyFSM_State4
    call    FSM_ChangeState
    ret
.ENDS

.SECTION "Mode Manager Test" FREE
.DSTRUCT Mode1 INSTANCEOF ApplicationMode VALUES
    VideoInterruptJumpTarget:   .dw ModeDefaultHandler
    OnNMI:                      .dw ModeDefaultHandler
    OnActive:                   .dw Mode1ActiveHandler
    OnInactive:                 .dw Mode1InactiveHandler
    OnUpdate:                   .dw Mode1UpdateHandler
    OnRender:                   .dw ModeDefaultHandler
    OnEvent:                    .dw ModeDefaultHandler  
.ENDST
.DSTRUCT Mode2 INSTANCEOF ApplicationMode VALUES
    VideoInterruptJumpTarget:   .dw ModeDefaultHandler
    OnNMI:                      .dw ModeDefaultHandler
    OnActive:                   .dw Mode2ActiveHandler
    OnInactive:                 .dw Mode2InactiveHandler
    OnUpdate:                   .dw ModeDefaultHandler
    OnRender:                   .dw ModeDefaultHandler
    OnEvent:                    .dw ModeDefaultHandler  
.ENDST

ModeDefaultHandler:
    ret

Mode1ActiveHandler:
    ret

Mode1UpdateHandler:
    ret

Mode1InactiveHandler:
    ret

Mode2ActiveHandler:
    ret

Mode2InactiveHandler:
    ret

.ENDS

.RAMSECTION "My FSM" SLOT 3
    gMyFSM INSTANCEOF FSM
.ENDS

.SECTION "FSM Test" FREE
State_NULL:
    and a       ; Clear carry.
    ret

State1_OnEnter:
    ld  hl, MyFSM_State2
    scf         ; Indicate transition
    ret

State2_OnUpdate:
    ld  hl, MyFSM_State3
    scf         ; Indicate transition
    ret

State4_OnEnter:
    ld  hl, MyFSM_State5
    scf         ; Indicate transition
    ret

.DSTRUCT MyFSM_State1 INSTANCEOF State VALUES
    OnUpdate:   .dw State_NULL      
    OnEvent:    .dw State_NULL 
    OnEnter:    .dw State1_OnEnter 
    OnExit:     .dw State_NULL
.ENDST  
.DSTRUCT MyFSM_State2 INSTANCEOF State VALUES
    OnUpdate:   .dw State2_OnUpdate      
    OnEvent:    .dw State_NULL 
    OnEnter:    .dw State_NULL 
    OnExit:     .dw State_NULL
.ENDST
.DSTRUCT MyFSM_State3 INSTANCEOF State VALUES
    OnUpdate:   .dw State_NULL      
    OnEvent:    .dw State_NULL 
    OnEnter:    .dw State_NULL 
    OnExit:     .dw State_NULL
.ENDST
.DSTRUCT MyFSM_State4 INSTANCEOF State VALUES
    OnUpdate:   .dw State_NULL      
    OnEvent:    .dw State_NULL 
    OnEnter:    .dw State4_OnEnter 
    OnExit:     .dw State_NULL
.ENDST
.DSTRUCT MyFSM_State5 INSTANCEOF State VALUES
    OnUpdate:   .dw State_NULL      
    OnEvent:    .dw State_NULL 
    OnEnter:    .dw State_NULL 
    OnExit:     .dw State_NULL
.ENDST

.ENDS