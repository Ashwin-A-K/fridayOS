section .multiboot_header
header_start:  
    dd 0xe85250d6; loader searches for a magic number to find the header If it doesn’t have the magic number, we can throw an error
    dd 0; protected mode code
    dd header_end - header_start ; header length
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start)); Checksum that let us and GRUB double-check that everything
    ;field checksum is a 32-bit unsigned value when added to the other magic fields must have a 32-bit unsigned sum of zero

    ; required end tag
    dw 0; type
    dw 0; flags
    dd 8; size
header_end: