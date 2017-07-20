module task_creator;

import std.path;
import std.array;
import std.format;
import std.algorithm;
import std.exception;

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
            tasks ~= new Task("g++ -c -MMD -fPIC -shared%s %(-I%s%| %) -o %s %s".format(
                        group.config.compileFlags, group.config.includeDirs, outputFile, sourceFile),
                    input, outputFile, emptyDeps);
        }
    }

    Task createSharedLibraryTask(const ref string name, const string location, SourceFilesGroup[] sourceGroups) {
        Task[] tasks;
        sourceGroups.filter!(a => !a.sourceFiles.empty)
            .each!(a => addTasks(a, tasks));
        enforce!Error(!tasks.empty, "No tasks");
        auto libraryPath = buildPath(location, "lib%s.so".format(name));
        return new Task("g++ -shared -o %s %(%s%| %)".format(
                    libraryPath, tasks.map!(a => a.output).array),
                tasks.map!(a => a.output).array, libraryPath, tasks);
    }

    Task createApplicationTask(const ref string name, const ref SourceFilesGroup main, ref Task[] libraries) {
        Task[] deps = libraries;
        addTasks(main, deps);
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

