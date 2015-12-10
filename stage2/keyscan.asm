kbd_normal_table:
; 0x00
	db 0x00 ; Not assigned
	db 0x00 ; Escape
	db '1'
	db '2'
	db '3'
	db '4'
	db '5'
	db '6'
	db '7'
	db '8'
	db '9'
	db '0'
	db '-'
	db '='
	db 0x00 ; backspace
	db 0x00 ; tab
; 0x10
	db 'q'
	db 'w'
	db 'e'
	db 'r'
	db 't'
	db 'y'
	db 'u'
	db 'i'
	db 'o'
	db 'p'
	db '['
	db ']'
	db 0x00 ; Enter
	db 0x00 ; Left Ctrl
	db 'a'
	db 's'
; 0x20
	db 'd'
	db 'f'
	db 'g'
	db 'h'
	db 'j'
	db 'k'
	db 'l'
	db ';'
	db 0x27 ; Single Quote
	db '`'
	db 0x00 ; Left Shift
	db '\'
	db 'z'
	db 'x'
	db 'c'
	db 'v'
; 0x30
	db 'b'
	db 'n'
	db 'm'
	db ','
	db '.'
	db '/'
	db 0x00 ; Right Shift
	db '*'  ; Numeric Keypad
	db 0x00 ; Left Alt
	db ' '
	db 0x00 ; Caps Lock
	db 0x00 ; F1
	db 0x00 ; F2
	db 0x00 ; F3
	db 0x00 ; F4
	db 0x00 ; F5
; 0x40
	db 0x00 ; F6
	db 0x00 ; F7
	db 0x00 ; F8
	db 0x00 ; F9
	db 0x00 ; F10
	db 0x00 ; Num lock
	db 0x00 ; Scroll lock
	db '7'  ; Numeric Keypad
	db '8'  ; Numeric Keypad
	db '9'  ; Numeric Keypad
	db '-'  ; Numeric Keypad
	db '4'  ; Numeric Keypad
	db '5'  ; Numeric Keypad
	db '6'  ; Numeric Keypad
	db '+'  ; Numeric Keypad
	db '1'  ; Numeric Keypad
; 0x50
	db '2'  ; Numeric Keypad
	db '3'  ; Numeric Keypad
	db '0'  ; Numeric Keypad
	db '.'  ; Numeric Keypad
	db 0x00
	db 0x00
	db 0x00
	db 0x00 ; F11
	db 0x00 ; F12
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00

kbd_shift_table:
; 0x00
	db 0x00 ; Not assigned
	db 0x00 ; Escape
	db '!'
	db '@'
	db '#'
	db '$'
	db '%'
	db '^'
	db '&'
	db '*'
	db '('
	db ')'
	db '_'
	db '+'
	db 0x00 ; backspace
	db 0x00 ; tab
; 0x10
	db 'Q'
	db 'W'
	db 'E'
	db 'R'
	db 'T'
	db 'Y'
	db 'U'
	db 'I'
	db 'O'
	db 'P'
	db '{'
	db '}'
	db 0x00 ; Enter
	db 0x00 ; Left Ctrl
	db 'A'
	db 'S'
; 0x20
	db 'D'
	db 'F'
	db 'G'
	db 'H'
	db 'J'
	db 'K'
	db 'L'
	db ':'
	db '"'
	db '~'
	db 0x00 ; Left Shift
	db '|'
	db 'Z'
	db 'X'
	db 'C'
	db 'V'
; 0x30
	db 'B'
	db 'N'
	db 'M'
	db '<'
	db '>'
	db '?'
	db 0x00 ; Right Shift
	db '*'  ; Numeric Keypad
	db 0x00 ; Left Alt
	db ' '
	db 0x00 ; Caps Lock
	db 0x00 ; F1
	db 0x00 ; F2
	db 0x00 ; F3
	db 0x00 ; F4
	db 0x00 ; F5
; 0x40
	db 0x00 ; F6
	db 0x00 ; F7
	db 0x00 ; F8
	db 0x00 ; F9
	db 0x00 ; F10
	db 0x00 ; Num lock
	db 0x00 ; Scroll lock
	db 0x00 ; Numeric Keypad 7
	db 0x00 ; Numeric Keypad 8
	db 0x00 ; Numeric Keypad 9
	db '-'  ; Numeric Keypad
	db 0x00 ; Numeric Keypad 4
	db 0x00 ; Numeric Keypad 5
	db 0x00 ; Numeric Keypad 6
	db '+'  ; Numeric Keypad
	db 0x00 ; Numeric Keypad 1
; 0x50
	db 0x00 ; Numeric Keypad 2
	db 0x00 ; Numeric Keypad 3
	db 0x00 ; Numeric Keypad 0
	db '.'  ; Numeric Keypad
	db 0x00
	db 0x00
	db 0x00
	db 0x00 ; F11
	db 0x00 ; F12
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00
	db 0x00