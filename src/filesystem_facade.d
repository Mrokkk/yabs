module filesystem_facade;

import std.array;
public import std.datetime: SysTime;
public import std.file: DirIterator, SpanMode;
import std.file: chdir, mkdirRecurse, getcwd, exists, readText, timeLastModified, dirEntries;

public import interfaces.filesystem_facade;

class FilesystemFacade : IFilesystemFacade {

    bool fileExists(immutable string name) {
        return name.exists;
    }

    DirIterator listDir(immutable string dirName, SpanMode spanMode) {
        return dirEntries(dirName, spanMode);
    }

    string readText(immutable string fileName) {
        return fileName.readText;
    }

    void makeDir(immutable string path) {
        mkdirRecurse(path);
    }

    void changeDir(immutable string path) {
        chdir(path);
    }

    string getCurrentDir() {
        return getcwd;
    }

    SysTime lastModificationTime(string fileName) {
        return fileName.timeLastModified;
    }

    DirEntry[] glob(immutable string dirName, immutable string glob) {
        return dirEntries(dirName, glob, SpanMode.shallow).array;
    }

}

