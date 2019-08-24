
.PHONY: all
.PHONY: qemu
.PHONY: clean
.PHONY: kernel

ISO_BIN=kernel.iso

all: qemu

DC= ldc2
DFLAGS= -betterC -m64 -c -of
#DFLAGS= -betterC -m32 -c

LIBGCC_S=`gcc -m64 -print-libgcc-file-name`

SRC=${wildcard *.d *.asm bios/*.d}

OBJS=boot.o  vga.o main.o err.o ldc2lib.o #cpuid.o 


%.o : %.d
	${DC} ${DFLAGS} $@ $<

src: 
	@echo ${SRC}

kernel: ${OBJS} 
	ld -z max-page-size=4096 -m elf_i386 -T linker.ld -o kernel $^ 


boot.o: boot.asm 
	nasm -f elf64 -o boot.o boot.asm
	#nasm -f elf -o boot.o boot.asm #for 32

#qemu: ${ISO_BIN} ${SRC}
qemu: kernel ${SRC}
	qemu-system-x86_64 -kernel kernel -serial stdio -m 1024M


${ISO_BIN}: kernel
	mkdir -p iso/boot/grub
	cp grub.cfg.org iso/boot/grub/grub.cfg
	cp kernel iso/boot/
	grub-mkrescue -o $(ISO_BIN) iso

clean:
	@\rm -rf *.o kernel ${ISO_BIN} iso/boot/kernel
