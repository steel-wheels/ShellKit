/**
 * file: which.ts
 */

/// <reference path="types/Library.d.ts"/>

function main(args: string[]): number
{
	/* get pathes from env */
	let pathval = env.get("PATH") ;
	if(pathval == null){
		return -1 ;
	}

	let pathes  = pathval.split(":") ;
	for(const subpath of args){
		for(const pathstr of pathes){
			let basedir = newURL(pathstr) ;
			whitch(basedir, subpath) ;
		}
	}
	return 0 ;
}

function whitch(base: URL, subpath: string) {
	let path = base.appendingPathComponent(subpath) ;
	if(fileManager.isExist(path) && fileManager.isExecutable(path)){
		console.log(path.path + "\n") ;
	}
}

