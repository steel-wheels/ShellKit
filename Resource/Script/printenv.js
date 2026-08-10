"use strict";
/**
 * file: printenv.ts
 */
/// <reference path="types/Library.d.ts"/>
function main(args) {
    if (args.length == 0) {
        args = env.allKeys;
    }
    for (const key of args) {
        let val = env.get(key);
        if (val != null) {
            console.log(val + "\n");
        }
        else {
            console.log("nil\n");
        }
    }
    return 0;
}
