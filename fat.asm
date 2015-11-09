db 0x00, 0x00 ; Reserved
db 0xFF, 0x0F ; STAGE2.BIN First Cluster

pad: times (9*512)-($-$$) db 0
