module interfaces.filesystem_facade;

public import std.datetime: SysTime;
public import std.file: DirIterator, SpanMode;

interface IFilesystemFacade {

    bool fileExists(immutable string name);
    DirIterator listDir(immutable string dirName, SpanMode spanMode);
    string readText(immutable string fileName);
    void makeDir(immutable string path);
    void changeDir(immutable string path);
    string getCurrentDir();
    SysTime lastModificationTime(string fileName);

}

