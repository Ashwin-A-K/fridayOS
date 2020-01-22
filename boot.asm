global start;Label start is made available outside of this file, Else, GRUB won’t know where to find its definition

section .text;code goes into a section named .text. Everything that comes after the section line is in that section, until another                section line.
bits 32;GRUB will boot us into protected mode, aka 32-bit mode
start:
    ;   size  place     thing
    ;     |     |         |
    ;     V     V         V
    mov word [0xb8000], 0x0948 ; H
    ;video memory must live in the address range beginning 0xb8000

    ;     __ background color
    ;    /  __foreground color
    ;    | /
    ;    V V
    ;    0 2 48 <- letter, in ASCII

    mov word [0xb8002], 0x0965 ; e
    ;Since we need half a word for the colors ( 02 ), and half a word for the H ( 48 ), that’s one word in total (or two bytes). Each place that the memory address points to can hold one byte (a.k.a. 8 bits or half a word). Hence, if our rst memory position is at 0 ,the second letter will start at 2 
    
    ;If we're in 32 bit mode, isn't a word 32 bits? Well, the ‘word’ keyword in the context of x86_64 assembly specically refers to 2 bytes, or 16 bits of data. This is for reasons of backwards compatibility.
    mov word [0xb8004], 0x096c ; l
    mov word [0xb8006], 0x096c ; l
    mov word [0xb8008], 0x096f ; o
    mov word [0xb800a], 0x0220 ; 
    mov word [0xb800c], 0x0977 ; w
    mov word [0xb800e], 0x096f ; o
    mov word [0xb8010], 0x0972 ; r
    mov word [0xb8012], 0x096c ; l
    mov word [0xb8014], 0x0964 ; d
    mov word [0xb8016], 0x0220 ; 
    hlt