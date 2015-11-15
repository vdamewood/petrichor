db 0xF9, 0xFF, 0xFF ; FAT ID / End of File indicator
db 0xFF, 0x0F ; STAGE2.BIN First Cluster

pad: times (9*512)-($-$$) db 0
