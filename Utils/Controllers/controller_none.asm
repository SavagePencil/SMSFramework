.IFNDEF __CONTROLLER_NONE_ASM__
.DEFINE __CONTROLLER_NONE_ASM__

.SECTION "Controller None" FREE
Controller_None_Ret:
    and a   ; Clear carry (no transition)
    ret

.DSTRUCT Controller_None_State INSTANCEOF State VALUES
    OnUpdate:   .DW Controller_None_Ret
    OnEnter:    .DW Controller_None_Ret
    OnExit:     .DW Controller_None_Ret
    OnEvent:    .DW Controller_None_Ret
.ENDST

.ENDS

.ENDIF  ;__CONTROLLER_NONE_ASM__