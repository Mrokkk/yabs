module task_creator;

import std.path;
import std.array;
import std.format;
import std.algorithm;

public import task;
import yabs_config;
import project_config;
import source_files_group;
import interfaces.filesystem_facade;

class TaskCreator {

    this(IFilesystemFacade filesystemFacade, YabsConfig yabsConfig, ProjectConfig projectConfig) {
        filesystemFacade_ = filesystemFacade;
        yabsConfig_ = yabsConfig;
        projectConfig_ = projectConfig;
    }

    private void addTasks(const ref SourceFilesGroup group, ref Task[] tasks) {
        Task[] emptyDeps;
        foreach (sourceFile; group.sourceFiles) {
            auto language = yabsConfig_.sourceFileExtensionToLanguageMap[sourceFile.extension];
            auto outputFile = buildPath(projectConfig_.buildDir,
                    sourceFile.relativePath(projectConfig_.rootDir)
                .setExtension(yabsConfig_.languagesInfo[language].objectFileExtension));
            auto input = [sourceFile, group.config.configFile];
            tasks ~= new Task("g++ -c -MMD -fPIC -shared%s -o %s %s".format(
                        group.config.compileFlags, outputFile, sourceFile),
                    input, outputFile, emptyDeps);
        }
    }

    Task createSharedLibraryTask(const ref string name, const string location, SourceFilesGroup[] sourceGroups) {
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
        auto libraryPath = buildPath(location, "lib%s.so".format(name));
        return new Task("g++ -shared -o %s %(%s%| %)".format(
                    libraryPath, tasks.map!(a => a.output).array),
                tasks.map!(a => a.input[0]).array, libraryPath, tasks);
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
    YabsConfig yabsConfig_;
    ProjectConfig projectConfig_;
}

