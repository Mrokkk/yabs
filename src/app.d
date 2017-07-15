module app;

import std.conv;
import std.path;
import std.stdio;
import std.format;
import std.getopt;
import std.process;
import core.stdc.stdlib;

import task;
import tree_reader;
import task_runner;
import yabs_config;
import task_creator;
import config_reader;
import project_config;
import filesystem_facade;
import source_files_group;
import interfaces.filesystem_facade;

enum TargetType {
    application, library
}

TargetType deduceTargetType(const ref SourceFilesGroup[] sourceGroups) {
    if (sourceGroups[$-1].sourceFiles[0].baseName.stripExtension == "main") {
        return TargetType.application;
    }
    else {
        return TargetType.library;
    }
}

enum Command {
    build, test, run
}

enum BuildType {
    debugBuild, releaseBuild
}

class Options {
    Command command = Command.run;
    BuildType buildType = BuildType.debugBuild;
    bool verbose = false;
}

Options parseArgs(ref string[] args) {
    auto options = new Options;
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
            "v|verbose", "Print verbose messages", &options.verbose
    );

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("yabs - simple C/C++ build system\nUsage:\n\tyabs command ...",
            helpInformation.options);
        exit(0);
    }
    return options;
}

int main(string[] args) {

    auto options = parseArgs(args);
    auto filesystemFacade = new FilesystemFacade;

    auto baseDir = args[0].absolutePath.dirName;
    auto currentDir = filesystemFacade.getCurrentDir();
    auto projectName = currentDir.baseName();

    auto configReader = new ConfigReader(filesystemFacade);

    auto yabsConfig = configReader.readYabsConfig(baseDir);
    auto projectConfig = configReader.readProjectConfig(yabsConfig, currentDir);

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);
    auto sourceGroups = treeReader.read(projectConfig.sourceDir);

    auto targetType = deduceTargetType(sourceGroups);

    auto taskCreator = new TaskCreator(filesystemFacade, projectConfig);
    auto sharedLibraryTask = taskCreator.createSharedLibraryTask(projectName,
            targetType == TargetType.application
                ? sourceGroups[0 .. $-1]
                : sourceGroups);

    Task targetTask;
    auto taskRunner = new TaskRunner(filesystemFacade);

    filesystemFacade.makeDir(projectConfig.buildDir);

    if (targetType == TargetType.application) {
        Task[] libs;
        libs ~= sharedLibraryTask;
        targetTask = taskCreator.createApplicationTask(projectName, sourceGroups[$-1], libs);
        taskRunner.call(targetTask);
        if (options.command == Command.run) {
            auto pid = spawnShell(buildPath(currentDir, projectName));
            wait(pid);
        }
    }
    else {
        targetTask = sharedLibraryTask;
        taskRunner.call(targetTask);
    }
    return 0;
}

