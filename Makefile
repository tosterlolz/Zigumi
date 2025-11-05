TARGET = Zigumi
BOOTLOADER = src/boot/boot.asm
KERNEL = src/kernel.zig
BOOT_BIN = bin/bootloader.bin
KERNEL_BIN = bin/kernel.bin
IMG = bin/$(TARGET).img

all: $(IMG)

$(BOOT_BIN): $(BOOTLOADER)
	mkdir -p bin
	nasm -f bin -o $@ $(BOOTLOADER)
	truncate -s 512 $@

$(KERNEL_BIN): $(KERNEL) linker.ld
	zig build-exe $(KERNEL) \
		-target x86-freestanding \
		-femit-bin=bin/kernel.elf \
		-O ReleaseSmall \
		--script linker.ld \
		-fno-strip
	objcopy -O binary bin/kernel.elf $(KERNEL_BIN)

$(IMG): $(BOOT_BIN) $(KERNEL_BIN)
	# Create a larger image to safely contain kernel and future data
	dd if=/dev/zero of=$(IMG) bs=512 count=4096 status=none
	dd if=$(BOOT_BIN) of=$(IMG) conv=notrunc status=none
	dd if=$(KERNEL_BIN) of=$(IMG) bs=512 seek=1 conv=notrunc status=none
	@echo "Created $(IMG)"

run: $(IMG)
	qemu-system-x86_64 -drive format=raw,file=$(IMG)

clean:
	rm -r bin/ 
