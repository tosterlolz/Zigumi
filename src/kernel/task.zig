// Task/Process structure for Zigumi OS

pub const TaskState = enum(u8) {
    Ready,
    Running,
    Blocked,
    Terminated,
};

pub const Task = struct {
    id: u32,
    name: [32]u8,
    state: TaskState,

    // CPU state (registers)
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
    esi: u32,
    edi: u32,
    ebp: u32,
    esp: u32,
    eip: u32,
    eflags: u32,

    // Stack for the task
    stack: [4096]u8,

    // Scheduling info
    priority: u8,
    time_slice: u32,
    time_used: u32,

    pub fn init(id: u32, name: []const u8, entry_point: u32) Task {
        var task = Task{
            .id = id,
            .name = [_]u8{0} ** 32,
            .state = .Ready,
            .eax = 0,
            .ebx = 0,
            .ecx = 0,
            .edx = 0,
            .esi = 0,
            .edi = 0,
            .ebp = 0,
            .esp = 0,
            .eip = entry_point,
            .eflags = 0x202, // IF flag set (interrupts enabled)
            .stack = [_]u8{0} ** 4096,
            .priority = 5,
            .time_slice = 10,
            .time_used = 0,
        };

        // Copy task name
        var i: usize = 0;
        while (i < name.len and i < 31) : (i += 1) {
            task.name[i] = name[i];
        }

        // Set up stack pointer to top of stack
        task.esp = @intFromPtr(&task.stack) + 4096 - 4;

        return task;
    }
};
