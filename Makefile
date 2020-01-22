default: build

.PHONY: default build run clean #We need a way to tell make that this is a special target, it isn't really a le on disk, it's an action that should always be executed.

#Syntax
#target: prerequisites
#	command

build/multiboot_header.o: multiboot_header.asm
	mkdir -p build
	nasm -f elf64 multiboot_header.asm -o build/multiboot_header.o
	# Mandatory line uses a tab to indent

build/boot.o: boot.asm
	mkdir -p build
	nasm -f elf64 boot.asm -o build/boot.o

build/kernel.bin: build/multiboot_header.o build/boot.o linker.ld
	ld -n -o build/kernel.bin -T linker.ld build/multiboot_header.o build/boot.o

build/fridayOS.iso: build/kernel.bin grub.cfg #Need to have all required files in top directory => cp isofiles/boot/grub/grub.cfg .
	mkdir -p build/isofiles/boot/grub
	cp grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot/
	grub-mkrescue -o build/fridayOS.iso build/isofiles

run: build/fridayOS.iso #"make run" to boot the OS
	qemu-system-x86_64 -cdrom build/fridayOS.iso

build: build/fridayOS.iso

clean:
	rm -rf build
