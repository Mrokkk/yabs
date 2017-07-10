module app;

import std.stdio;
import std.array;
import std.algorithm;
import vibe.data.json;
import std.file: DirEntry;
import std.path: dirName, extension, absolutePath, buildPath, stripExtension, baseName, dirName;

import yabs_config;
import config_reader;
import filesystem_facade;
import interfaces.filesystem_facade;

class SourceFilesConfig {
    string compileFlags;
}

class SourceFilesGroup {
    string[] sourceFiles;
    SourceFilesConfig config;
}

class Directory {

    this(const string path, SourceFilesConfig config) {
        this.path = path;
        this.config = config;
    }

    string path;
    string[] sourceFiles;
    SourceFilesConfig config;
}

class TreeReader {

    this(IFilesystemFacade filesystemFacade, YabsConfig yabsConfig) {
        filesystemFacade_ = filesystemFacade;
        yabsConfig_ = yabsConfig;
    }

    private SourceFilesConfig readConfig(const string configFileName, SourceFilesConfig defaultConfig) {
        if (filesystemFacade_.fileExists(configFileName)) {
        }
        return defaultConfig;
    }

    private void readSourceDirRecursive(string dirName, SourceFilesConfig buildConfig, ref Directory[] directories) {
        auto configFile = buildPath(dirName, yabsConfig_.expectedComponentConfigFileName);
        auto directoryConfig = readConfig(configFile, buildConfig);
        auto directory = new Directory(dirName, directoryConfig);
        auto entries = filesystemFacade_.listDir(dirName, SpanMode.shallow);
        foreach (entry; entries) {
            if (entry.isDir) {
                readSourceDirRecursive(entry.name, directory.config, directories);
            }
            else if (entry.isFile) {
                if (entry.name.extension in yabsConfig_.sourceFileExtensionToLanguageMap) {
                    directory.sourceFiles ~= entry.name;
                }
            }
        }
        directories ~= directory;
    }

    Directory[] read(const string root) {
        Directory[] directories;
        readSourceDirRecursive(root, new SourceFilesConfig, directories);
        foreach (dir; directories) {
            writeln(dir.sourceFiles);
        }
        return directories;
    }

private:
    IFilesystemFacade filesystemFacade_;
    YabsConfig yabsConfig_;

}

int main(string[] args) {

    auto filesystemFacade = new FilesystemFacade;

    auto baseDir = args[0].absolutePath.dirName;
    auto currentDir = filesystemFacade.getCurrentDir();

    auto configReader = new ConfigReader(filesystemFacade);
    auto yabsConfig = configReader.readYabsConfig(baseDir);

    auto projectConfig = configReader.readProjectConfig(yabsConfig, currentDir);

    auto treeReader = new TreeReader(filesystemFacade, yabsConfig);
    treeReader.read(projectConfig.sourceDir);

    return 0;
}

