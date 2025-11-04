OUT := build/zigumi.elf
# Prefer a small, known-good kernel stub for initial builds. If it doesn't
# exist, fall back to the project's `src/main.zig` (may contain work-in-progress
# code and fail to compile).
SRC := $(shell if [ -f src/kernel_stub.zig ]; then echo src/kernel_stub.zig; else echo src/main.zig; fi)

.PHONY: all clean iso run

all: $(OUT)

$(OUT):
	mkdir -p build
	# If a NASM multiboot header source exists, assemble it to an object and
	# pass that object to the Zig linker so the header lands inside the final
	# ELF image (GRUB will detect it). Use elf64 since kernel is x86_64.
	OBJ_HDR=""
	if [ -f boot/multiboot_header.asm ]; then \
		nasm -f elf64 boot/multiboot_header.asm -o build/multiboot_header.o; \
		OBJ_HDR=build/multiboot_header.o; \
	fi; \
	# Try ReleaseSmall first, fall back to Debug. Use a freestanding x86_64
	# target and emit an ELF binary. Zig flag `-femit-bin` creates the output file.
	zig build-exe $(SRC) $$OBJ_HDR -O ReleaseSmall -target x86_64-freestanding-none -femit-bin=$(OUT) || \
		zig build-exe $(SRC) $$OBJ_HDR -O Debug -target x86_64-freestanding-none -femit-bin=$(OUT)

clean:
	rm -rf build zig-out .zig-cache

iso: all
	mkdir -p build/iso/boot
	cp $(OUT) build/iso/boot/kernel
	cp -r boot/* build/iso/boot/ 2>/dev/null || true


	# Create a minimal GRUB configuration. NOTE: GRUB can only load ELF kernels
	# directly if they expose a Multiboot/Multiboot2 header. If your kernel is
	# not Multiboot-compliant, the ISO will be produced but GRUB may fail to
	# boot it. In that case `make run` will fall back to `qemu -kernel`.
	mkdir -p build/iso/boot/grub
	printf '%s\n' "set timeout=5" "set default=0" "" \
		"menuentry \"Zigumi OS\" {" \
		"  # GRUB will try to load /boot/kernel as a multiboot image" \
		"  multiboot /boot/kernel" \
		"  boot" \
		"}" > build/iso/boot/grub/grub.cfg

	# Prefer grub-mkrescue when available (it bundles the proper boot images).
	if command -v grub-mkrescue >/dev/null 2>&1; then \
		grub-mkrescue -o build/zigumi.iso build/iso >/dev/null 2>&1 && echo "ISO created with grub-mkrescue" || (echo "grub-mkrescue failed, falling back to xorriso" && xorriso -as mkisofs -V Zigumi -o build/zigumi.iso -J -R build/iso); \
	else \
		echo "grub-mkrescue not found; creating plain ISO with xorriso (may not be bootable)"; \
		xorriso -as mkisofs -V Zigumi -o build/zigumi.iso -J -R build/iso; \
	fi

run: iso
	@# Prefer the ISO (with Limine) if present, otherwise try the ELF kernel
	@if [ -f build/zigumi.iso ]; then \
		if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then echo "qemu-system-x86_64 not found in PATH"; exit 1; fi; \
		echo "Running ISO with QEMU..."; \
		qemu-system-x86_64 -cdrom build/zigumi.iso -m 512M -serial stdio -no-reboot; \
	elif [ -f build/zigumi.elf ]; then \
		if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then echo "qemu-system-x86_64 not found in PATH"; exit 1; fi; \
		echo "Running ELF kernel with QEMU (using -kernel)..."; \
		qemu-system-x86_64 -kernel build/zigumi.elf -m 512M -serial stdio -no-reboot; \
	else \
		echo "No build artifact found. Run 'make iso' or 'make all' first."; exit 1; \
	fi