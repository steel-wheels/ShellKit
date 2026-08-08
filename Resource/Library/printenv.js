"use strict";
/**
 * file: printenv.ts
 */
/// <reference path="types/Library.d.ts"/>
function printenv(args) {
    for (let arg in args) {
        let urlp = env.getURL(arg);
    }
}
