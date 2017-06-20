module yabs;

import std.conv: to;
import std.stdio: writeln;
import std.format: format;
import std.process: executeShell, spawnShell, wait;
import std.path: setExtension, extension, buildPath, dirName;
import std.algorithm;
import std.array;

import tree_reader;
import binary: Binary;
import context: Context;
import build_type: BuildType;
import directories: Directories;
import compilers_map: CompilersMap;
import compilers_map_builder: CompilersMapBuilder;

import task;
import component;

import interfaces.filesystem_facade;

class Yabs {

    this(IFilesystemFacade filesystemFacade,
            TreeReader treeReader,
            CompilersMapBuilder compilersMapBuilder,
            Context context) {
        filesystemFacade_ = filesystemFacade;
        treeReader_ = treeReader;
        compilersMapBuilder_ = compilersMapBuilder;
        context_ = context;
    }

    private Task[] createTasks(Component[] components, CompilersMap compilers) {
        Task[] tasks;
        Task[] emptyDeps;
        foreach (component; components) {
            foreach (sourceFile; component.sourceFiles) {
                auto path = buildPath(context_.projectRoot, sourceFile);
                auto language = context_.config.sourceFileExtensionToLanguageMap[sourceFile.extension];
                auto objectFile = sourceFile.setExtension(context_.config.languages[language]
                        .objectFileExtension);
                string[] prerequisite;
                prerequisite ~= path;
                tasks ~= new Task(compilers[language].compileCommand(path, objectFile, component.config, component.type),
                        prerequisite,
                        objectFile,
                        emptyDeps);
            }
        }
        return tasks;
    }

    private static string targetFileName(const string targetName, Binary.Type targetType) {
        switch (targetType) {
            case Binary.Type.executable: return targetName;
            case Binary.Type.sharedLibrary: return "lib" ~ targetName ~ ".so";
            case Binary.Type.staticLibrary: return "lib" ~ targetName ~ ".a";
            default: return targetName;
        }
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

    private void callTasks(Task task) {
        foreach (t; task.dependencies) {
            callTasks(t);
        }
        if (isOutdated(task.result, task.prerequisite)) {
            filesystemFacade_.makeDir(task.result.dirName);
            writeln("Building %s".format(task.command));
            auto p = executeShell(task.command);
            if (p.status != 0) {
                writeln(p.output);
            }
        }
    }

    void build(BuildType buildType) {
        context_.print();
        auto tree = treeReader_.read(context_.config.expectedSourceDirName);
        auto compilersMap = compilersMapBuilder_.build(tree.components);
        auto sharedLibCompilationTasks = createTasks(tree.components[0 .. $-1], compilersMap);
        auto executableCompilationTasks = createTasks(tree.components[$-1 .. $], compilersMap);
        string[] empty;
        Task[] tasks;
        auto sharedLibName = targetFileName(context_.projectName, Binary.Type.sharedLibrary);
        auto objFiles = sharedLibCompilationTasks.map!(a => a.result).array;
        tasks ~= new Task("g++ -shared -o %s %(%s%| %)".format(sharedLibName, objFiles),
                objFiles,
                sharedLibName,
                sharedLibCompilationTasks);
        tasks ~= executableCompilationTasks;
        auto executableTask = new Task("g++ -o %s -Wl,-rpath=%s -Wl,%s %(%s| %)".format(
                    context_.projectName, context_.buildDir, tasks[0].result, executableCompilationTasks
                        .map!(a => a.result)
                ), empty, context_.projectName, tasks);
        filesystemFacade_.makeDir("build");
        filesystemFacade_.changeDir("build");
        callTasks(executableTask);
    }

    void runApp(BuildType buildType) {
        build(buildType);
        auto process = spawnShell("./%s".format(context_.projectName));
        wait(process);
    }

private:
    IFilesystemFacade filesystemFacade_;
    TreeReader treeReader_;
    CompilersMapBuilder compilersMapBuilder_;
    Context context_;

}

