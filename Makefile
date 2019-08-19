
.PHONY: all
.PHONY: qemu
.PHONY: clean
.PHONY: kernel

ISO_BIN=kernel.iso

all: qemu

DD= ldc2
DFLAGS= -betterC -m64 -c
#DFLAGS= -betterC -m32 -c

OBJS=boot.o  bios.vga.o main.o err.o #cpuid.o 

SRC=${wildcard *.d *.asm bios/*.d}

src: 
	@echo ${SRC}

kernel: ${OBJS} 
	#ld -m elf_x86_64 -T linker.ld -o kernel $^
	ld -m elf_i386 -T linker.ld -o kernel $^


boot.o: boot.asm 
	nasm -f elf64 -o boot.o boot.asm
	#nasm -f elf -o boot.o boot.asm #for 32

bios.vga.o: bios/vga.d
	${DD} ${DFLAGS} -of $@ $^

main.o: main.d
	${DD} ${DFLAGS} -of $@ $^

cpuid.o: cpuid.d
	${DD} ${DFLAGS} -of $@ $^

err.o: err.d
	${DD} ${DFLAGS} -of $@ $^

qemu: ${ISO_BIN} ${SRC}
	qemu-system-x86_64 -cdrom ${ISO_BIN} -serial stdio -m 1024M
	#qemu-system-i386 -cdrom ${ISO_BIN} -serial stdio -m 1024M


${ISO_BIN}: kernel
	mkdir -p iso/boot/grub
	cp grub.cfg.org iso/boot/grub/grub.cfg
	cp kernel iso/boot/
	grub-mkrescue -o $(ISO_BIN) iso

clean:
	@\rm -rf *.o kernel ${ISO_BIN} iso/boot/kernel
