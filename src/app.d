module app;

import std.path;
import std.stdio;
import std.array;
import std.format;
import std.process;

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

int main(string[] args) {

    auto filesystemFacade = new FilesystemFacade;

    auto baseDir = args[0].absolutePath.dirName;
    auto currentDir = filesystemFacade.getCurrentDir();
    auto projectName = currentDir.baseName();

    auto configReader = new ConfigReader(filesystemFacade);

    auto yabsConfig = configReader.readYabsConfig(baseDir);
    auto projectConfig = configReader.readProjectConfig(yabsConfig, currentDir);

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);
    auto sourceGroups = treeReader.read(projectConfig.sourceDir);

    TargetType targetType;

    if (sourceGroups[$-1].sourceFiles[0].baseName.stripExtension == "main") {
        targetType = TargetType.application;
    }
    else {
        targetType = TargetType.library;
    }

    auto taskCreator = new TaskCreator(filesystemFacade, projectConfig);
    auto sharedLibraryTask = taskCreator.createSharedLibraryTask(projectName,
            targetType == TargetType.application
                ? sourceGroups[0 .. $-1]
                : sourceGroups);

    Task targetTask;

    auto taskRunner = new TaskRunner(filesystemFacade);
    if (targetType == TargetType.application) {
        Task[] libs;
        libs ~= sharedLibraryTask;
        targetTask = taskCreator.createApplicationTask(projectName, sourceGroups[$-1], libs);
    }
    else {
        targetTask = sharedLibraryTask;
    }

    taskRunner.call(targetTask);

    if (targetType == TargetType.application) {
        auto pid = spawnShell("./" ~ projectName);
        wait(pid);
    }

    return 0;
}

