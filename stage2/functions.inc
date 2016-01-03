%ifndef FUNCTIONS_INC
%define FUNCTIONS_INC

%macro  fprolog 1-*
.fprolog:
	push ebp 
	mov ebp, esp 
	%if %1
		sub esp, (%1*4)
	%endif
	%if %0 > 2
		%rotate 1
		%rep  %0-1
			push    %1
			%rotate 1
		%endrep
	%endif
.fbody:
%endmacro

%macro  freturn 0-*
.freturn:
	%rep %0
		%rotate -1
		pop %1
	%endrep
	mov esp, ebp
	pop ebp
	ret
%endmacro

%endif