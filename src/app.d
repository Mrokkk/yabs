module app;

import std.path;
import std.stdio;
import std.array;
import std.format;
import std.algorithm;
import std.process;

import tree_reader;
import yabs_config;
import config_reader;
import project_config;
import filesystem_facade;
import source_files_group;
import interfaces.filesystem_facade;

class Task {

    immutable string command;
    const string[] input;
    immutable string output;
    Task[] dependencies;

    this(const string command, const string[] input, const string output, ref Task[] dependencies) {
        this.command = command;
        this.input = input;
        this.output = output;
        this.dependencies = dependencies;
    }

}

enum TargetType {
    application, library
}

class TaskCreator {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
    }

    private void addTasks(const ref SourceFilesGroup group, ref Task[] tasks) {
        Task[] emptyDeps;
        foreach (sourceFile; group.sourceFiles) {
            auto outputFile = buildPath("build", sourceFile.relativePath(projectConfig_.rootDir)
                .setExtension(".o"));
            string[] input;
            input ~= sourceFile;
            tasks ~= new Task("g++ -c -MMD -fPIC -shared%s -o %s %s".format(
                        group.config.compileFlags, outputFile, sourceFile),
                    input, outputFile, emptyDeps);
        }
    }

    Task createSharedLibraryTask(const ref SourceFilesGroup[] sourceGroups) {
        Task[] tasks;
        foreach (group; sourceGroups) {
            addTasks(group, tasks);
        }
        auto sourceFiles = tasks.map!(a => a.input[0]).array;
        auto objFiles = tasks.map!(a => a.output).array;
        return new Task("g++ -shared -o %s %(%s%| %)".format("liba.so", objFiles), sourceFiles, "liba.so", tasks);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
}

class TaskRunner {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    private bool isOutdated(string targetName, const string[] objects) {
        if (!filesystemFacade_.fileExists(targetName)) {
            return true;
        }
        foreach (object; objects) {
            if (filesystemFacade_.lastModificationTime(targetName) <
                    filesystemFacade_.lastModificationTime(object)) {
                return true;
            }
        }
        return false;
    }

    void call(Task task) {
        foreach (t; task.dependencies) {
            call(t);
        }
        if (isOutdated(task.output, task.input)) {
            filesystemFacade_.makeDir(task.output.dirName);
            writeln("Building %s".format(task.command));
            auto p = executeShell(task.command);
            if (p.status != 0) {
                writeln(p.output);
            }
        }
    }

private:
    IFilesystemFacade filesystemFacade_;
}

int main(string[] args) {

    auto filesystemFacade = new FilesystemFacade;

    auto baseDir = args[0].absolutePath.dirName;
    auto currentDir = filesystemFacade.getCurrentDir();

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
    auto sharedLibraryTask = taskCreator.createSharedLibraryTask(sourceGroups);

    auto taskRunner = new TaskRunner(filesystemFacade);
    if (targetType == TargetType.application) {
    }

    taskRunner.call(sharedLibraryTask);

    return 0;
}

