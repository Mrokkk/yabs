module tree_reader;

import std.format;
import std.algorithm;
import vibe.data.json;
import std.array: array, empty;
import std.path: dirName, extension, absolutePath, buildPath, stripExtension, baseName;

import yabs_config;
public import tree;
import interfaces.filesystem_facade;

class TreeReader {

    this(IFilesystemFacade filesystemFacade, YabsConfig yabsConfig) {
        filesystemFacade_ = filesystemFacade;
        yabsConfig_ = yabsConfig;
    }

    private string createCompileFlags(const string parentCompileFlags, Json json) {
        try {
            return parentCompileFlags ~ " " ~ json["additionalFlags"].get!string;
        }
        catch (JSONException) {
            return parentCompileFlags;
        }
    }

    private string[] createIncludeDirs(const string[] parentIncludeDirs, Json json) {
        try {
            return parentIncludeDirs ~ json["includeDirs"]
                .get!(Json[])
                .map!(a => a.get!string)
                .array;
        }
        catch (JSONException) {
            return cast(string[])parentIncludeDirs;
        }
    }

    SourceFilesConfig readConfig(const string path, SourceFilesConfig defaultConfig) {
        Json json;
        try {
            json = filesystemFacade_.readText(path).parseJsonString;
        }
        catch (JSONException) {
            throw new Error("Not a JSON file: %s".format(path));
        }
        auto config = new SourceFilesConfig(path, createCompileFlags(defaultConfig.compileFlags, json),
                createIncludeDirs(defaultConfig.includeDirs, json));
        return config;
    }

    SourceFilesGroup readRecursively(const string path, SourceFilesConfig config, ref SourceFilesGroup[] groups) {
        auto entries = filesystemFacade_.listDir(path, SpanMode.shallow);
        auto configFile = buildPath(path, yabsConfig_.expectedComponentConfigFileName);
        if (groups.empty) {
            groups ~= new SourceFilesGroup;
            groups[$-1].config = config;
        }
        auto currentGroup = groups[$-1];
        if (filesystemFacade_.fileExists(configFile)) {
            auto newGroup = new SourceFilesGroup;
            newGroup.config = readConfig(configFile, config);
            config = newGroup.config;
            groups ~= newGroup;
            currentGroup = groups[$-1];
        }
        auto mainGroup = new SourceFilesGroup;
        foreach (entry; entries) {
            if (entry.isDir) {
                readRecursively(entry.name, config, groups);
            }
            else if (entry.isFile) {
                if (entry.name.extension in yabsConfig_.sourceFileExtensionToLanguageMap) {
                    if (entry.name.baseName.stripExtension == "main") {
                        mainGroup.sourceFiles ~= entry.name;
                        mainGroup.config = config;
                    }
                    else {
                        currentGroup.sourceFiles ~= entry.name;
                    }
                }
            }
        }
        return mainGroup;
    }

    Tree read(const string path) {
        SourceFilesGroup[] groups;
        auto mainGroup = readRecursively(path, new SourceFilesConfig, groups);
        if (!mainGroup.sourceFiles.empty) {
            groups ~= mainGroup;
        }
        return new Tree(groups, new Compiler("g++"));
    }

private:
    IFilesystemFacade filesystemFacade_;
    YabsConfig yabsConfig_;
}

