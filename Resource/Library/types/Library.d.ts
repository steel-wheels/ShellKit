/**
 * @file Process.d.ts 
 */

declare class URL {
	get path() : string ;
}

declare function newURL(path: string): URL ;

/**
 * EnvVariables.d.ts
 */

/// <reference path="types/TextColor.d.ts"/>

declare class Environment
{
	get allKeys(): string[] ;

	get(name: string): string | null ;
	set(name: string, value: string): void ;
}

declare var env: Environment  ;

/**
 * @file FileHandle.d.ts
 */
declare class FileHandle {
    setReader(func: (str: string) => void): void ;
    write(str: string): void ;
}

declare var stdin:	FileHandle  ;
declare var stdout:	FileHandle  ;
declare var stderr:	FileHandle  ;

/**
 * Process.d.ts
 */

/// <reference path="URL.d.ts"/>
/// <reference path="FileHandle.d.ts"/>

declare class Process {
	get standardInput(): FileHandle ;
	set standardInput(hdl: FileHandle) ;

	get standardOutput(): FileHandle ;
	set standardOutput(hdl: FileHandle) ;

	get standardError(): FileHandle ;
	set standardError(hdl: FileHandle) ;

	get executableURL(): URL ;
	set executableURL(url: URL) ;

	get arguments(): string[] ;
	set arguments(arg: string[]) ;

	get isRunning(): boolean ;
	get exitCode(): number ;

	start(): number ;
}

declare function newProcess(): Process ;

/**
 * @file Thread.d.ts
 */

/// <reference path="FileHandle.d.ts"/>
/// <reference path="URL.d.ts"/>

declare class Thread
{
	get standardInput(): FileHandle ;
        set standardInput(hdl: FileHandle) ;

        get standardOutput(): FileHandle ;
        set standardOutput(hdl: FileHandle) ;

        get standardError(): FileHandle ;
        set standardError(hdl: FileHandle) ;

        get script(): string ;
        set script(hsrc: string) ;

        get arguments(): string[] | null ;
        set arguments(args: string[] | null) ;

        get executableURL(): URL | null ;
        set executableURL(url: URL | null) ;

	get isRunning(): boolean ;
	get exitCode(): number ;

	start(): void ;
}

declare function newThread(): Thread ;

/**
 * isUndefined.d.ts
 */

declare function isUndefined(obj: unknown): boolean ;

/**
 * @file TextColor.ts
 */
declare const enum TextColor {
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7
}
/**
 * @file Console.ts
 */
declare class Console {
    log(str: string): void;
}
/**
 * @file ThreadFunc.ts
 */
declare function allocateThread(inf: FileHandle, outf: FileHandle, errf: FileHandle): Thread;
declare function startThreadWithScript(thd: Thread, args: string[], script: string): void;
declare function startThreadWithFile(thd: Thread, args: string[], url: URL): void;
declare function waitThread(thd: Thread): number;
/**
 * ProcessFunc.ts
 */
declare function allocateProcess(inf: FileHandle, outf: FileHandle, errf: FileHandle): Process;
declare function startProcess(proc: Process, exec: URL, args: string[]): number;
declare function waitProcess(proc: Process): number;
/**
 * @file math.ts
 */
declare function abs(val: number): number;
