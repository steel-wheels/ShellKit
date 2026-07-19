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
        stdout.write(str);
    }
}
"use strict";
/**
 * @file math.ts
 */
/// <reference path="types/BuiltinLibrary.d.ts"/>
function abs(val) {
    return val >= 0.0 ? val : -val;
}
