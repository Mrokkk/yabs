module app;

import std.conv;
import std.path;
import std.array;
import std.stdio;
import std.format;
import std.getopt;
import std.process;
import std.algorithm;
import core.exception;
import core.stdc.stdlib;

import interfaces.builder;
import interfaces.filesystem_facade;

import args_parser;
import tree_reader;
import task_runner;
import yabs_config;
import task_creator;
import config_reader;
import project_config;
import filesystem_facade;
import source_files_group;

import builders.tests_builder;
import builders.library_builder;
import builders.application_builder;

TargetType deduceTargetType(YabsConfig yabsConfig, ProjectConfig projectConfig, IFilesystemFacade filesystemFacade) {
    try {
        auto main = filesystemFacade.glob(projectConfig.sourceDir, "main.*")
            .filter!(a => a.extension in yabsConfig.sourceFileExtensionToLanguageMap)
            .array[0];
        return TargetType.application;
    }
    catch (RangeError) {
        return TargetType.library;
    }
}

immutable enum Command[TargetType] defaultCommands = [
    TargetType.application: Command.run,
    TargetType.library: Command.build
];

int main(string[] argv) {

    auto args = ArgsParser.parseArgs(argv);
    auto filesystemFacade = new FilesystemFacade;

    auto configReader = new ConfigReader(filesystemFacade);

    auto baseDir = argv[0].absolutePath.dirName;
    auto yabsConfig = configReader.readYabsConfig(baseDir);
    auto projectConfig = configReader.readProjectConfig(yabsConfig);

    if (projectConfig.targetType == TargetType.none) {
        projectConfig.targetType = deduceTargetType(yabsConfig, projectConfig, filesystemFacade);
    }

    writeln("# Project name: %s".format(projectConfig.projectName));
    writeln("# Target type: %s".format(projectConfig.targetType));
    writeln("# Build type: %s".format(args.buildType));
    writeln("");

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);

    filesystemFacade.makeDir(projectConfig.buildDir);
    auto taskCreator = new TaskCreator(filesystemFacade, yabsConfig, projectConfig);
    auto taskRunner = new TaskRunner(filesystemFacade);

    IBuilder builder;

    if (args.command == Command.test) {
        builder = new TestsBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
    }
    else {
        if (args.command == Command.defaultCommand) {
            args.command = defaultCommands[projectConfig.targetType];
        }
        switch (projectConfig.targetType) {
            case TargetType.application:
                builder = new ApplicationBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
                break;
            case TargetType.library:
                builder = new LibraryBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
                break;
            default: break;
        }
    }
    builder.build(args.buildType);
    if (args.command == Command.run) {
        auto pid = spawnShell(buildPath(projectConfig.rootDir, projectConfig.projectName));
        wait(pid);
    }
    else if (args.command == Command.test) {
        auto pid = spawnShell(buildPath(projectConfig.rootDir, projectConfig.projectName ~ "_tests"));
        wait(pid);
    }
    return 0;
}

