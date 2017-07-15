module app;

import std.conv;
import std.path;
import std.stdio;
import std.format;
import std.getopt;
import std.process;
import core.stdc.stdlib;

import task;
import args_parser;
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

interface IBuilder {
    void build(BuildType buildType);
}

class ApplicationBuilder : IBuilder {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig, TreeReader treeReader,
            TaskCreator taskCreator, TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    void build(BuildType buildType) {
        auto sourceFilesGroups = treeReader_.read(projectConfig_.sourceDir);
        auto sharedLibraryTask = taskCreator_.createSharedLibraryTask(projectConfig_.projectName,
                sourceFilesGroups[0 .. $-1]);
        Task targetTask;
        auto libs = [sharedLibraryTask];
        targetTask = taskCreator_.createApplicationTask(projectConfig_.projectName, sourceFilesGroups[$-1], libs);
        taskRunner_.call(targetTask);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
}

class LibraryBuilder : IBuilder {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig, TreeReader treeReader,
            TaskCreator taskCreator, TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    void build(BuildType buildType) {
        auto sourceFilesGroups = treeReader_.read(projectConfig_.sourceDir);
        auto sharedLibraryTask = taskCreator_.createSharedLibraryTask(projectConfig_.projectName,
                sourceFilesGroups);
        taskRunner_.call(sharedLibraryTask);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
}

class TestsBuilder : IBuilder {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig, TreeReader treeReader,
            TaskCreator taskCreator, TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    void build(BuildType buildType) {
        auto sourceTree = treeReader_.read(projectConfig_.sourceDir);
        auto sourceSharedLibTask = taskCreator_.createSharedLibraryTask(projectConfig_.projectName,
                sourceTree[0 .. $-1]);
        Task[] libs = [sourceSharedLibTask];
        auto testsTree = treeReader_.read(projectConfig_.testsDir);
        try {
            auto testsLibName = projectConfig_.projectName ~ "_tests";
            auto testsSharedLibTask = taskCreator_.createSharedLibraryTask(testsLibName,
                    testsTree[0 .. $-1]);
            libs ~= testsSharedLibTask;
        }
        catch (Error) {
        }
        auto testsApplicationName = projectConfig_.projectName ~ "_tests";
        auto targetTask = taskCreator_.createApplicationTask(testsApplicationName, testsTree[$-1], libs);
        taskRunner_.call(targetTask);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
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

