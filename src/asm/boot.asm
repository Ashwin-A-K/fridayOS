extern kmain ; we'll be de ning kmain elsewhere 

global start ; Label start is made available outside of this file, Else, GRUB won’t know where to find its definition

section .text ; code goes into a section named .text. Everything that comes after the section line is in that section, until                        another section line.
bits 32 ; GRUB will boot us into protected mode, aka 32-bit mode

; A word is 16 bits, a double word is 32 bits, so a quad word is 64 bits

; ----------------------------------------------------------------------------------------------------------------------------------

; In long mode, the page table is four levels deep, and each page is 4096 bytes in size. Here are the offcial names:
;     the Page-Map Level-4 Table (PML4)
;     the Page-Directory Pointer Table (PDP)
;     the Page-Directory Table (PD)
;     and the Page Table (PT)

;   We're just going to go for 2 MiB pages, which means we only need three tables: we won't need a level 1 page table.

section .bss ; It stands for block started by symbol. Entries in the bss section are automatically set to zero by the linker

align 4096 ; align directive makes sure that we’ve aligned our tables properly.

p4_table:
    resb 4096 ;Reserves bytes directive reserve space for each entry
p3_table:
    resb 4096
p2_table:
    resb 4096

; GDT will have three entries:

; ----------------------------------------------------------------------------------------------------------------------------------
section .rodata ; read only data

; 1) a ‘zero entry’ (it needs to be a zero value)
gdt64: ; to tell the hardware where our GDT is located
    dq 0 ; define quad-word which is a 64-bit value

; 2) a ‘code segment’
.code: equ $ - gdt64 ; .code: tells the assembler to scope this label under the last label that appeared
                     ; equ sets the address for the label
                     ; $ is the current position and we are subtracting the address of gdt64 from the current position.               Conveniently, that's the offset number we need for later
                     ;
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53) ; a value that has the 44th, 47th, 41st, 43rd, and 53rd bit set

; 44: ‘descriptor type’: This has to be 1 for code and data segments
; 47: ‘present’: This is set to 1 if the entry is valid
; 41: ‘read/write’: If this is a code segment, 1 means that it’s readable
; 43: ‘executable’: Set to 1 for code segments
; 53: ‘64-bit’: if this is a 64-bit GDT, this should be set

; 3) a ‘data segment’
.data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) ; Others are covered before. The only difference is bit 41 where 1 means that it’s writable

; There’s a special assembly instruction to tell the hardware about our GDT: lgdt . But it doesn’t take the GDT itself; it takes a special structure: two bytes for the length, and eight bytes for the address.

.pointer:
    dw .pointer - gdt64 - 1 ; ; To calculate the length
    dq gdt64 ; dq here has the address of our table
; ----------------------------------------------------------------------------------------------------------------------------------

start:
    ; Point the first entry of the level 4 page table to the first entry in the p3 table
    mov eax, p3_table; copies the contents of the first third-level page table entry into the eax register
    
    or eax, 0b11; we or eax with 0b11 =>By setting the first bit, we say that page is currently in memory and by setting the second,              we say that page is allowed to be written to.
    
    mov dword [p4_table + 0], eax; copies the contents of eax reg to level 4 page table page table entry. Adding 0 intended to                                     convey to the reader that we’re accessing the zeroth entry in the page table

    ; Point the first entry of the level 3 page table to the first entry in the p2 table
    mov eax, p2_table
    or eax, 0b11
    mov dword [p3_table + 0], eax

    ; point each page table level two entry to a page
    mov ecx, 0 ; counter variable
    .map_p2_table:
        mov eax, 0x200000 ; Its 2MiB and each page is two megabytes in size
        mul ecx ; mul takes just one argument, here its ecx counter, and multiplies that by eax , storing the result in eax
        or eax, 0b10000011 ; Here, we don’t just or 0b11. This extra 1 is a ‘huge page’ bit, meaning that the pages are 2MiB
                           ; Thus 10000000 is 12 8bytes and with 8 bytes entry size, its 128*8 = 4MiB
        mov [p2_table + ecx * 8], eax ; ecx is our loop counter. Each entry is eight bytes in size, so we need to multiply the                                      counter by eight, and then add it to p2_table
        inc ecx
        cmp ecx, 512 ; we want to map 512 page entries overall
        jne .map_p2_table

; ----------------------------------------------------------------------------------------------------------------------------------

; Now that we have a valid page table, we need to inform the hardware about it. Here’s the steps we need to take:

    ; move page table address to cr3
    mov eax, p4_table
    mov cr3, eax ; cr3 is a special register, called a control register which control how the CPU actually works. In our case,                     cr3 register needs to hold the location of the page table.
    
    ; enable PAE
    mov eax, cr4 ; why alternating value of cr4 is not in scope of this tut
    or eax, 1 << 5 ; 1<<n = 2^n
    mov cr4, eax
    
    ; set the long mode bit
    mov ecx, 0xC0000080 ; why moving value is not in scope of this tut
    rdmsr ; The rdmsr and wrmsr instructions read and write to a ‘model speci c register’
    or eax, 1 << 8
    wrmsr
    
    ; enable paging
    mov eax, cr0 ; ; why altering the value is not in scope of this tut
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

; we’re in a special compatibility mode
; ----------------------------------------------------------------------------------------------------------------------------------

; global descriptor table


; Check line 30 to 57

lgdt [gdt64.pointer] ; lgdt stands for ‘load global descriptor table’
; ----------------------------------------------------------------------------------------------------------------------------------
;Our last task is to update several special registers called 'segment registers'.

; update selectors
mov ax, gdt64.data ; ax is a 16 bit register. And eax(e for extended) is the 32 bit version of the ax register. 
                   ; The segment registers are sixteen bit values, so we start off by putting the data part of our GDT into it, to    load into all of the segment registers
mov ss, ax ; It is a stack segment register. We don't even have a stack yet but Still needs to be set.
mov ds, ax ; It is a data segment register. This points to the data segment of our GDT, which we loaded into ax .
mov es, ax ; an extra segment register. Not used, still needs to be set.

; Unfortunately, we can't modify the code segment register ourselves. So "mov cs, ax" wont work and the way to change cs is to execute what's called a 'far jump'. foo:bar syntax is what makes this a long jump

; jmp gdt64.code:long_mode_start
jmp gdt64.code:kmain ; changed for rust code

; ----------------------------------------------------------------------------------------------------------------------------------
section .text
bits 64

long_mode_start:
    mov rax, 0x2f592f412f4b2f4f ; rax is a 64-bit version of eax
    mov qword [0xb8000], rax ; qword bit stands for 'quad-word', aka, 64-bit and 0xb8000 is the upper-left part of the screen
hlt

; ----------------------------------------------------------------------------------------------------------------------------------
    ; ;   size  place     thing
    ; ;     |     |         |
    ; ;     V     V         V
    ; mov word [0xb8000], 0x0948 ; H
    ; ;video memory must live in the address range beginning 0xb8000

    ; ;     __ background color
    ; ;    /  __foreground color
    ; ;    | /
    ; ;    V V
    ; ;    0 2 48 <- letter, in ASCII

    ; mov word [0xb8002], 0x0965 ; e
    ; ;Since we need half a word for the colors ( 02 ), and half a word for the H ( 48 ), that’s one word in total (or two bytes). Each place that the memory address points to can hold one byte (a.k.a. 8 bits or half a word). Hence, if our rst memory position is at 0 ,the second letter will start at 2 
    
    ; ;If we're in 32 bit mode, isn't a word 32 bits? Well, the ‘word’ keyword in the context of x86_64 assembly specically refers to 2 bytes, or 16 bits of data. This is for reasons of backwards compatibility.
    ; mov word [0xb8004], 0x096c ; l
    ; mov word [0xb8006], 0x096c ; l
    ; mov word [0xb8008], 0x096f ; o
    ; mov word [0xb800a], 0x0220 ; 
    ; mov word [0xb800c], 0x0977 ; w
    ; mov word [0xb800e], 0x096f ; o
    ; mov word [0xb8010], 0x0972 ; r
    ; mov word [0xb8012], 0x096c ; l
    ; mov word [0xb8014], 0x0964 ; d
    ; mov word [0xb8016], 0x0220 ; 
    ; hlt
