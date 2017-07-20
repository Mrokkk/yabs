module task_runner;

import std.path;
import std.stdio;
import std.format;
import std.string;
import std.process;
import std.algorithm;

public import task;
import interfaces.filesystem_facade;

class TaskRunner {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    private bool isOutdated(const ref string targetName, const string[] objects) {
        if (!filesystemFacade_.fileExists(targetName)) {
            return true;
        }
        foreach (object; objects.filter!(a => !a.empty)) {
            if (filesystemFacade_.lastModificationTime(targetName) <
                    filesystemFacade_.lastModificationTime(object)) {
                return true;
            }
        }
        return false;
    }

    void call(const Task task) {
        task.dependencies.each!(d => call(d));
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

