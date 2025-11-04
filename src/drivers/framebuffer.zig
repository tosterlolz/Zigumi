const std = @import("std");

const FRAMEBUFFER_WIDTH = 1024;
const FRAMEBUFFER_HEIGHT = 768;

const pastelColors: [5][3]u8 = [
    [255, 182, 193], // Light Pink
    [173, 216, 230], // Light Blue
    [144, 238, 144], // Light Green
    [255, 255, 224], // Light Yellow
    [255, 160, 122], // Light Salmon
];

pub fn initFramebuffer() !void {
    // Assuming framebuffer is mapped to a specific memory address
    const framebuffer: *u8 = @ptrCast(*u8, 0xB8000);
    
    for (y: usize = 0; y < FRAMEBUFFER_HEIGHT; y += 1) {
        for (x: usize = 0; x < FRAMEBUFFER_WIDTH; x += 1) {
            const colorIndex = (x / (FRAMEBUFFER_WIDTH / pastelColors.len)) % pastelColors.len;
            const color = pastelColors[colorIndex];

            const pixelIndex = (y * FRAMEBUFFER_WIDTH + x) * 4; // Assuming 4 bytes per pixel (RGBA)
            framebuffer[pixelIndex + 0] = color[0]; // Red
            framebuffer[pixelIndex + 1] = color[1]; // Green
            framebuffer[pixelIndex + 2] = color[2]; // Blue
            framebuffer[pixelIndex + 3] = 0xFF;      // Alpha
        }
    }
}

pub fn drawPixel(x: usize, y: usize, color: [3]u8) void {
    const framebuffer: *u8 = @ptrCast(*u8, 0xB8000);
    const pixelIndex = (y * FRAMEBUFFER_WIDTH + x) * 4;

    framebuffer[pixelIndex + 0] = color[0]; // Red
    framebuffer[pixelIndex + 1] = color[1]; // Green
    framebuffer[pixelIndex + 2] = color[2]; // Blue
    framebuffer[pixelIndex + 3] = 0xFF;      // Alpha
}