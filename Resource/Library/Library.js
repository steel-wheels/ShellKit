"use strict";
/**
 * @file TextColor.ts
 */
;
"use strict";
/**
 * @file Console.ts
 */
/// <reference path="types/FileHandle.d.ts"/>
class Console {
    log(str) {
        standardOutputFileHandle.write(str);
    }
}
var console = new Console();
"use strict";
/**
 * @file ThreadFunc.ts
 */
/// <reference path="types/Thread.d.ts"/>
function allocateThread(inf, outf, errf) {
    let thd = newThread();
    thd.standardInput = inf;
    thd.standardOutput = outf;
    thd.standardError = errf;
    return thd;
}
function startThreadWithScript(thd, args, script) {
    thd.script = script;
    thd.arguments = args;
    thd.start();
}
function startThreadWithFile(thd, args, url) {
    thd.executableURL = url;
    thd.arguments = args;
    thd.start();
}
function waitThread(thd) {
    while (thd.isRunning) {
    }
    return thd.exitCode;
}
"use strict";
/**
 * ProcessFunc.ts
 */
/// <reference path="types/Process.d.ts"/>
function allocateProcess(inf, outf, errf) {
    let proc = newProcess();
    proc.standardInput = inf;
    proc.standardOutput = outf;
    proc.standardError = errf;
    return proc;
}
function startProcess(proc, exec, args) {
    proc.executableURL = exec;
    proc.arguments = args;
    return proc.start();
}
function waitProcess(proc) {
    while (proc.isRunning) {
    }
    return proc.exitCode;
}
"use strict";
/**
 * @file math.ts
 */
function abs(val) {
    return val >= 0.0 ? val : -val;
}
