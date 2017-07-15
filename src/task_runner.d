module task_runner;

import std.path;
import std.stdio;
import std.format;
import std.process;

import task;
import interfaces.filesystem_facade;

class TaskRunner {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    private bool isOutdated(const ref string targetName, const string[] objects) {
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

    void call(const Task task) {
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

