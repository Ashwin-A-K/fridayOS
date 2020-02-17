default: build

build: target/kernel.bin

.PHONY: default build run clean #We need a way to tell make that this is a special target, it isn't really a le on disk, it's an action that should always be executed.

#Syntax
#target: prerequisites
#	command

target/multiboot_header.o: src/asm/multiboot_header.asm
	mkdir -p target
	nasm -f elf64 src/asm/multiboot_header.asm -o target/multiboot_header.o
	# Mandatory line uses a tab to indent

target/boot.o: src/asm/boot.asm
	mkdir -p target
	nasm -f elf64 src/asm/boot.asm -o target/boot.o

target/kernel.bin: target/multiboot_header.o target/boot.o src/asm/linker.ld
	ld -n -o target/kernel.bin -T src/asm/linker.ld target/multiboot_header.o target/boot.o

target/kernel.bin: target/multiboot_header.o target/boot.o src/asm/linker.ld cargo
	ld -n -o target/kernel.bin -T src/asm/linker.ld target/multiboot_header.o target/boot.o target/x86_64-unknown-fridayOS-gnu/release/libfridayOS.a

target/fridayOS.iso: target/kernel.bin src/asm/grub.cfg # Need to have all required files in top directory => cp isofiles/boot/grub/														  grub.cfg .
	mkdir -p target/isofiles/boot/grub
	cp src/asm/grub.cfg target/isofiles/boot/grub
	cp target/kernel.bin target/isofiles/boot/
	grub-mkrescue -o target/fridayOS.iso target/isofiles

run: target/fridayOS.iso #"make run" to boot the OS
	qemu-system-x86_64 -cdrom target/fridayOS.iso

cargo:
	xargo build --release --target x86_64-unknown-fridayOS-gnu

clean:
	cargo clean
