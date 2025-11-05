TARGET = Zigumi
BOOTLOADER = src/boot/boot.S
KERNEL = src/kernel.zig
BOOT_BIN = bootloader.bin
KERNEL_BIN = kernel.bin
IMG = $(TARGET).img

all: $(IMG)

$(BOOT_BIN): $(BOOTLOADER)
	as --32 -o bootloader.o $(BOOTLOADER)
	ld -m elf_i386 -Ttext 0x7C00 --oformat binary -o $@ bootloader.o
	truncate -s 512 $@
	rm -f bootloader.o

$(KERNEL_BIN): $(KERNEL) linker.ld
	zig build-exe $(KERNEL) \
		-target x86-freestanding \
		-femit-bin=kernel.elf \
		-O ReleaseSmall \
		--script linker.ld \
		-fno-strip
	objcopy -O binary kernel.elf $(KERNEL_BIN)
	rm -f kernel.elf

$(IMG): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(IMG) bs=512 count=100 status=none
	dd if=$(BOOT_BIN) of=$(IMG) conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$(IMG) bs=512 seek=1 conv=notrunc status=none
	@echo "Created $(IMG)"

run: $(IMG)
	qemu-system-x86_64 -drive format=raw,file=$(IMG)

clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(IMG)
