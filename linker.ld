/*This is a ‘linker script’. It controls how our linker will combine these boot.o and multiboot_header.o into the final output*/

ENTRY(start) /*entry point for this executable (as in boot.asm)*/

SECTIONS {

. = 1M; /*This line means that we will start putting sections at the one megabyte mark. This is the conventional place to put a kernel. Below one megabyte is all kinds of memory-mapped stuff. VGA wouldn’t work if we mapped our kernel’s code to that part of memory... garbage on the screen!*/

.boot : /*This will create a section named boot*/

{

*(.multiboot_header) /*Every section named multiboot_header goes here. Remember section in multiboot_header.asm ? It’ll be here, at the start of the boot section. That’s what we need for GRUB to see it.*/

}

.text : /*This will create a section named text*/

{

*(.text) /*Next, The text section code is put inside it...*/

}
}