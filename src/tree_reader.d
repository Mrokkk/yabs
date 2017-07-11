module tree_reader;

import std.stdio;
import vibe.data.json;
import std.format: format;
import std.array: array, empty;
import std.path: dirName, extension, absolutePath, buildPath, stripExtension, baseName;

import yabs_config;
import source_files_group;;
import interfaces.filesystem_facade;

class TreeReader {

    this(IFilesystemFacade filesystemFacade, YabsConfig yabsConfig) {
        filesystemFacade_ = filesystemFacade;
        yabsConfig_ = yabsConfig;
    }

    SourceFilesConfig readConfig(const string path, SourceFilesConfig defaultConfig) {
        auto json = filesystemFacade_.readText(path).parseJsonString;
        auto config = new SourceFilesConfig;
        config.compileFlags = defaultConfig.compileFlags ~ " " ~ json["additionalFlags"].get!string();
        return config;
    }

    void readRecursively(const string path, SourceFilesConfig config, ref SourceFilesGroup[] groups) {
        auto entries = filesystemFacade_.listDir(path, SpanMode.shallow);
        auto configFile = buildPath(path, yabsConfig_.expectedComponentConfigFileName);
        if (groups.empty) {
            groups ~= new SourceFilesGroup;
        }
        auto currentGroup = groups[$-1];
        if (filesystemFacade_.fileExists(configFile)) {
            auto newGroup = new SourceFilesGroup;
            newGroup.config = readConfig(configFile, config);
            config = newGroup.config;
            groups ~= newGroup;
            currentGroup = groups[$-1];
        }
        foreach (entry; entries) {
            if (entry.isDir) {
                readRecursively(entry.name, config, groups);
            }
            else if (entry.isFile) {
                if (entry.name.extension in yabsConfig_.sourceFileExtensionToLanguageMap) {
                    currentGroup.sourceFiles ~= entry.name;
                }
            }
        }
    }

    SourceFilesGroup[] read(const string path) {
        SourceFilesGroup[] groups;
        readRecursively(path, new SourceFilesConfig, groups);
        foreach (g; groups) {
            if (!g.sourceFiles.empty)
                writeln("%s %s".format(g.sourceFiles, g.config.compileFlags));
        }
        return groups;
    }

private:
    IFilesystemFacade filesystemFacade_;
    YabsConfig yabsConfig_;
}

