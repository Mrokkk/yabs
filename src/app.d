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

int main(string[] args) {

    auto options = ArgsParser.parseArgs(args);
    auto filesystemFacade = new FilesystemFacade;

    auto configReader = new ConfigReader(filesystemFacade);

    auto baseDir = args[0].absolutePath.dirName;
    auto yabsConfig = configReader.readYabsConfig(baseDir);
    auto projectConfig = configReader.readProjectConfig(yabsConfig);

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);

    filesystemFacade.makeDir(projectConfig.buildDir);
    auto taskCreator = new TaskCreator(filesystemFacade, projectConfig);
    auto taskRunner = new TaskRunner(filesystemFacade);

    IBuilder builder;
    if (options.command == Command.test) {
        builder = new TestsBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
    }
    else {
        auto targetType = TargetType.application;
        switch (targetType) {
            case TargetType.application:
                builder = new ApplicationBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
                break;
            case TargetType.library:
                builder = new LibraryBuilder(filesystemFacade, projectConfig, treeReader, taskCreator, taskRunner);
                break;
            default: break;
        }
    }
    builder.build(BuildType.debugBuild);
    if (options.command == Command.run) {
        auto pid = spawnShell(buildPath(projectConfig.rootDir, projectConfig.projectName));
        wait(pid);
    }
    else if (options.command == Command.test) {
        auto pid = spawnShell(buildPath(projectConfig.rootDir, projectConfig.projectName ~ "_tests"));
        wait(pid);
    }
    return 0;
}

