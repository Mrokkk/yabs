module task_creator;

import std.path;
import std.array;
import std.format;
import std.algorithm;

import task;
import project_config;
import source_files_group;
import interfaces.filesystem_facade;

class TaskCreator {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
    }

    private void addTasks(const ref SourceFilesGroup group, ref Task[] tasks) {
        Task[] emptyDeps;
        foreach (sourceFile; group.sourceFiles) {
            auto outputFile = buildPath(projectConfig_.buildDir, sourceFile.relativePath(projectConfig_.rootDir)
                .setExtension(".o"));
            auto input = [sourceFile, group.config.configFile];
            tasks ~= new Task("g++ -c -MMD -fPIC -shared%s -o %s %s".format(
                        group.config.compileFlags, outputFile, sourceFile),
                    input, outputFile, emptyDeps);
        }
    }

    Task createSharedLibraryTask(const ref string name, SourceFilesGroup[] sourceGroups) {
        Task[] tasks;
        foreach (group; sourceGroups) {
            if (group.sourceFiles.empty) {
                continue;
            }
            addTasks(group, tasks);
        }
        if (tasks.empty) {
            throw new Error("No tasks");
        }
        auto libraryFileName = buildPath(projectConfig_.buildDir, "lib%s.so".format(name));
        return new Task("g++ -shared -o %s %(%s%| %)".format(
                    libraryFileName, tasks.map!(a => a.output).array),
                tasks.map!(a => a.input[0]).array, libraryFileName, tasks);
    }

    Task createApplicationTask(const ref string name, const ref SourceFilesGroup main, Task[] libraries) {
        Task[] deps;
        addTasks(main, deps);
        deps ~= libraries;
        string[] input;
        input ~= main.sourceFiles;
        input ~= libraries.map!(a => a.output).array;
        return new Task("g++ -o %s -Wl,-rpath=%s %(%s%| %)".format(
                    name, projectConfig_.buildDir, input),
                input, name, deps);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
}

