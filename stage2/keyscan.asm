keyscan_table:
; 0x00
	dw 0xFFFF ; Not assigned
	dw 0x0100 ; Escape
	dw '1'
	dw '2'
	dw '3'
	dw '4'
	dw '5'
	dw '6'
	dw '7'
	dw '8'
	dw '9'
	dw '0'
	dw '-'
	dw '='
	dw 0x0110 ; backspace
	dw 0x0111 ; tab
; 0x10
	dw 'q'
	dw 'w'
	dw 'e'
	dw 'r'
	dw 't'
	dw 'y'
	dw 'u'
	dw 'i'
	dw 'o'
	dw 'p'
	dw '['
	dw ']'
	dw 0x0112 ; Enter
	dw 0xFFFE ; Left Ctrl
	dw 'a'
	dw 's'
; 0x20
	dw 'd'
	dw 'f'
	dw 'g'
	dw 'h'
	dw 'j'
	dw 'k'
	dw 'l'
	dw ';'
	dw 0x0027 ; Single Quote
	dw '`'
	dw 0xFFFE ; Left Shift
	dw '\'
	dw 'z'
	dw 'x'
	dw 'c'
	dw 'v'
; 0x30
	dw 'b'
	dw 'n'
	dw 'm'
	dw ','
	dw '.'
	dw '/'
	dw 0xFFFE ; Right Shift
	dw '*'  ; Numeric Keypad
	dw 0xFFFE ; Left Alt
	dw ' '
	dw 0xFFFE ; Caps Lock
	dw 0xFFFF ; F1
	dw 0xFFFF ; F2
	dw 0xFFFF ; F3
	dw 0xFFFF ; F4
	dw 0xFFFF ; F5
; 0x40
	dw 0xFFFF ; F6
	dw 0xFFFF ; F7
	dw 0xFFFF ; F8
	dw 0xFFFF ; F9
	dw 0xFFFF ; F10
	dw 0xFFFE ; Num lock
	dw 0xFFFE ; Scroll lock
	dw '7'  ; Numeric Keypad
	dw '8'  ; Numeric Keypad
	dw '9'  ; Numeric Keypad
	dw '-'  ; Numeric Keypad
	dw '4'  ; Numeric Keypad
	dw '5'  ; Numeric Keypad
	dw '6'  ; Numeric Keypad
	dw '+'  ; Numeric Keypad
	dw '1'  ; Numeric Keypad
; 0x50
	dw '2'  ; Numeric Keypad
	dw '3'  ; Numeric Keypad
	dw '0'  ; Numeric Keypad
	dw '.'  ; Numeric Keypad
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF ; F11
	dw 0xFFFF ; F12
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF

keyscan_shift_table:
; 0xFFFF
	dw 0xFFFF ; Not assigned
	dw 0xFFFF ; Escape
	dw '!'
	dw '@'
	dw '#'
	dw '$'
	dw '%'
	dw '^'
	dw '&'
	dw '*'
	dw '('
	dw ')'
	dw '_'
	dw '+'
	dw 0xFFFF ; backspace
	dw 0xFFFF ; tab
; 0x10
	dw 'Q'
	dw 'W'
	dw 'E'
	dw 'R'
	dw 'T'
	dw 'Y'
	dw 'U'
	dw 'I'
	dw 'O'
	dw 'P'
	dw '{'
	dw '}'
	dw 0xFFFF ; Enter
	dw 0xFFFE ; Left Ctrl
	dw 'A'
	dw 'S'
; 0x20
	dw 'D'
	dw 'F'
	dw 'G'
	dw 'H'
	dw 'J'
	dw 'K'
	dw 'L'
	dw ':'
	dw '"'
	dw '~'
	dw 0xFFFE ; Left Shift
	dw '|'
	dw 'Z'
	dw 'X'
	dw 'C'
	dw 'V'
; 0x30
	dw 'B'
	dw 'N'
	dw 'M'
	dw '<'
	dw '>'
	dw '?'
	dw 0xFFFE ; Right Shift
	dw '*'  ; Numeric Keypad
	dw 0xFFFE ; Left Alt
	dw ' '
	dw 0xFFFF ; Caps Lock
	dw 0xFFFF ; F1
	dw 0xFFFF ; F2
	dw 0xFFFF ; F3
	dw 0xFFFF ; F4
	dw 0xFFFF ; F5
; 0x40
	dw 0xFFFF ; F6
	dw 0xFFFF ; F7
	dw 0xFFFF ; F8
	dw 0xFFFF ; F9
	dw 0xFFFF ; F10
	dw 0xFFFF ; Num lock
	dw 0xFFFF ; Scroll lock
	dw 0xFFFF ; Numeric Keypad 7
	dw 0xFFFF ; Numeric Keypad 8
	dw 0xFFFF ; Numeric Keypad 9
	dw '-'  ; Numeric Keypad
	dw 0xFFFF ; Numeric Keypad 4
	dw 0xFFFF ; Numeric Keypad 5
	dw 0xFFFF ; Numeric Keypad 6
	dw '+'  ; Numeric Keypad
	dw 0xFFFF ; Numeric Keypad 1
; 0x50
	dw 0xFFFF ; Numeric Keypad 2
	dw 0xFFFF ; Numeric Keypad 3
	dw 0xFFFF ; Numeric Keypad 0
	dw '.'  ; Numeric Keypad
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF ; F11
	dw 0xFFFF ; F12
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF
	dw 0xFFFF