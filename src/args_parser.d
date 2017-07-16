module args_parser;

import std.conv;
import std.stdio;
import std.format;
import std.getopt;
import core.stdc.stdlib;

enum Command {
    defaultCommand, build, test, run
}

enum BuildType {
    debugBuild, releaseBuild
}

class Args {
    Command command = Command.defaultCommand;
    BuildType buildType = BuildType.debugBuild;
    bool verbose = false;
}

class ArgsParser {

    static Args parseArgs(ref string[] args) {
        auto options = new Args;
        string[] args2;
        if (args.length < 2 || args[1][0] == '-') {
            args2 = args;
        }
        else {
            args2 = args[1 .. $];
            try {
                options.command = args[1].to!Command;
            }
            catch (Exception) {
                writeln("No such command: %s".format(args[1]));
                exit(-1);
            }
        }
        auto helpInformation = getopt(args2,
                "b|build", "Build type", &options.buildType,
                "v|verbose", "Print verbose messages", &options.verbose
        );

        if (helpInformation.helpWanted) {
            defaultGetoptPrinter("yabs - simple C/C++ build system\nUsage:\n\tyabs command ...",
                helpInformation.options);
            exit(0);
        }
        return options;
    }

}

