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
        return new Task("g++ -shared -o %s %(%s%| %)".format(
                    "liba.so", tasks.map!(a => a.output).array),
                tasks.map!(a => a.input[0]).array, "liba.so", tasks);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
}

