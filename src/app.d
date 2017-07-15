module app;

import std.conv;
import std.path;
import std.stdio;
import std.format;
import std.getopt;
import std.process;
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

int main(string[] argv) {

    auto args = ArgsParser.parseArgs(argv);
    auto filesystemFacade = new FilesystemFacade;

    auto configReader = new ConfigReader(filesystemFacade);

    auto baseDir = argv[0].absolutePath.dirName;
    auto yabsConfig = configReader.readYabsConfig(baseDir);
    auto projectConfig = configReader.readProjectConfig(yabsConfig);

    writeln("Project name: %s".format(projectConfig.projectName));
    writeln("Target type: %s".format(projectConfig.targetType));
    writeln("Build type: %s".format(args.buildType));

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);

    filesystemFacade.makeDir(projectConfig.buildDir);
    auto taskCreator = new TaskCreator(filesystemFacade, projectConfig);
    auto taskRunner = new TaskRunner(filesystemFacade);

    IBuilder builder;

    if (args.command == Command.test) {
        builder = new TestsBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
    }
    else {
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

