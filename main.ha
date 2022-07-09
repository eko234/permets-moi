use fmt;
use os;
use fs;
use strconv;
use io;

type config = struct{
	files: fs::mode,
	dirs: fs::mode,
};

const default_config: config = config {
	files = (fs::mode::USER_RW ^ fs::mode::GROUP_RW  ^ fs::mode::OTHER_R),  // -rw-rw-r--
	dirs = (fs::mode::USER_RWX ^ fs::mode::GROUP_RWX ^ fs::mode::OTHER_RX), // drwxrwxr-x
};

fn isDotty(fname: str) bool = {
	if (fname == "." || fname == "..") {
  	return true;
	} else {
  	return false;
	};
};

fn recufix(path: str, toplevel: bool) (void | io::error) = {

	if (toplevel) {
  	match (os::chmod(path, default_config.dirs)) {
  	case let err: fs::error =>
  		fmt::fatalf("Seems you didn't provided a directory or maybe you don't have the permissions needed to alter it");
  	case =>
  		fmt::println("OK...")!;
  	};
	};

	match (os::readdir(path)) {
	case let err: fs::error =>
  	fmt::printf("Oops: {} for {}\n",fs::strerror(err), path)!;
	case let ents: []fs::dirent =>
		for (let i = 0z; i < len(ents); i+= 1) {
			if (isDotty(ents[i].name)) { continue; };
			let fullpath = fmt::asprintf("{}/{}",path ,ents[i].name);
    	fmt::printf("fixing {}\n", fullpath)!;
			if (fs::isdir(ents[i].ftype)) {
      	os::chmod(fullpath, 0)!;
      	os::chmod(fullpath, default_config.dirs)!;
      	recufix(fmt::asprintf("{}/{}", path, ents[i].name), false)!;
			} else {
      	os::chmod(fullpath, 0)!;
       	os::chmod(fullpath, default_config.files)!;
			};
		};
	};
};

export fn main() void = {
	fmt::println("fixing your stuff bro...")!;
	if (len(os::args) < 2) {
		fmt::fatalf("You must provide the path");
	};
	recufix(os::args[1], true)!;
};
