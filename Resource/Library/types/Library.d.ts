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
 * @file math.ts
 */
declare function abs(val: number): number;
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
	getString(name: string): string | null ;
	setString(name: string, value: string): void ;

	getStrings(name: string): string[] | null ;
	setStrings(name: string, value: string[]): void ;

	getNumber(name: string): number | null ;
	setNumber(name: string, value: number): void ;

	getURL(name: string): URL | null ;
	setURL(name: string, value: URL): void ;

	getTextColor(name: string): TextColor | null ;
	setTextColor(name: string, value: TextColor): void ;

	getForegroundTextColor(): TextColor | null ;
	setForegroundTextColor(value: TextColor): void ;

	getBackgroundTextColor(): TextColor | null ;
	setBackgroundTextColor(value: TextColor): void ;
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

	run(): number ;
	wait(): void ;
}

declare function newProcess(): Process ;

/**
 * isUndefined.d.ts
 */

declare function isUndefined(obj: unknown): boolean ;

