.include "boot.asm"
.include "interrupts.asm"
.include "FSM.asm"

.SECTION "Application Bootstrap" FREE
; This routine sets up an initial state as part of the bootstrapping.
; It should set a mode for the initial program.
Application_Bootstrap:
    ; Set our initial mode
    ld  de, gModeManagerDummyMode
    call ModeManager_Init

FSMTesting:
    ld  ix, gMyFSM
    ld  hl, MyFSM_State1
    call FSM_Init
    call FSM_OnUpdate

    ld  hl, MyFSM_State4
    call FSM_ChangeState

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

;                                      OnUpdate        OnEvent    OnEnter        OnExit
.DSTRUCT MyFSM_State1 INSTANCEOF State State_NULL      State_NULL State1_OnEnter State_NULL
.DSTRUCT MyFSM_State2 INSTANCEOF State State2_OnUpdate State_NULL State_NULL     State_NULL
.DSTRUCT MyFSM_State3 INSTANCEOF State State_NULL      State_NULL State_NULL     State_NULL
.DSTRUCT MyFSM_State4 INSTANCEOF State State_NULL      State_NULL State4_OnEnter State_NULL
.DSTRUCT MyFSM_State5 INSTANCEOF State State_NULL      State_NULL State_NULL     State_NULL

.ENDS