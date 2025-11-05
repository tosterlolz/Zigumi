// Simple Task Scheduler for Zigumi OS

const MAX_TASKS = 8;

pub const TaskState = enum(u8) {
    Ready,
    Running,
    Sleeping,
    Terminated,
};

pub const Task = struct {
    pid: u32,
    name: [16]u8,
    name_len: usize,
    state: TaskState,
    priority: u8,
};

var tasks: [MAX_TASKS]?Task = [_]?Task{null} ** MAX_TASKS;
var current_task_id: usize = 0;
var next_pid: u32 = 1;

pub fn init() void {
    // Initialize all tasks to null
    for (&tasks) |*task| {
        task.* = null;
    }
    current_task_id = 0;
    next_pid = 1;
}

pub fn createTask(name: []const u8) !u32 {
    // Find free task slot
    var i: usize = 0;
    while (i < MAX_TASKS) : (i += 1) {
        if (tasks[i] == null) {
            const pid = next_pid;
            next_pid += 1;

            var task = Task{
                .pid = pid,
                .name = [_]u8{0} ** 16,
                .name_len = 0,
                .state = .Ready,
                .priority = 5,
            };

            // Copy name
            var j: usize = 0;
            while (j < name.len and j < 16) : (j += 1) {
                task.name[j] = name[j];
            }
            task.name_len = j;

            tasks[i] = task;
            return pid;
        }
    }

    return error.NoFreeTaskSlot;
}

pub fn getTaskCount() usize {
    var count: usize = 0;
    for (tasks) |task| {
        if (task != null) {
            count += 1;
        }
    }
    return count;
}

pub fn listTasks() [MAX_TASKS]?Task {
    return tasks;
}
