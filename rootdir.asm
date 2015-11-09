db 'BOOTDISK' ; File Name
db '   '      ; File Extension
db 0x08       ; Attribute
db 0x00       ; Reserved for NT
db 0x01       ; Creation
dw 0x0000     ; Creation Time
dw 0x0000     ; Creation Date
dw 0x0000     ; Last Access Data
dw 0x0000     ; FAT32 Upper Half
dw 0x0000     ; Last Write Time
dw 0x0000     ; Last Write Date
dw 0x0000     ; Starting Cluster
dd 0x00000000 ; File Size

pad: times 512-($-$$)-1 db 0
