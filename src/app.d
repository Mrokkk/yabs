module app;

import std.path;
import std.stdio;
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

TargetType deduceTargetType(const ref SourceFilesGroup[] sourceGroups) {
    if (sourceGroups[$-1].sourceFiles[0].baseName.stripExtension == "main") {
        return TargetType.application;
    }
    else {
        return TargetType.library;
    }
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

    auto targetType = deduceTargetType(sourceGroups);

    auto taskCreator = new TaskCreator(filesystemFacade, projectConfig);
    auto sharedLibraryTask = taskCreator.createSharedLibraryTask(projectName,
            targetType == TargetType.application
                ? sourceGroups[0 .. $-1]
                : sourceGroups);

    Task targetTask;

    filesystemFacade.makeDir(projectConfig.buildDir);
    auto taskRunner = new TaskRunner(filesystemFacade);
    if (targetType == TargetType.application) {
        Task[] libs;
        libs ~= sharedLibraryTask;
        targetTask = taskCreator.createApplicationTask(projectName, sourceGroups[$-1], libs);
        taskRunner.call(targetTask);
        auto pid = spawnShell(buildPath(currentDir, projectName));
        wait(pid);
    }
    else {
        targetTask = sharedLibraryTask;
        taskRunner.call(targetTask);
    }
    return 0;
}

