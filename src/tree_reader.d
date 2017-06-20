module tree_reader;

import std.file: DirEntry;
import std.stdio: writeln;
import std.format: format;
import std.algorithm: startsWith;
import std.json: JSONValue, parseJSON;
import std.path: buildPath, baseName, extension;

import interfaces.filesystem_facade;

import tree;
import context: Context;
import component: Component;
import component_config: ComponentConfig;
import component_config_reader: ComponentConfigReader;

class TreeReader {

    this(IFilesystemFacade filesystemFacade, ComponentConfigReader componentConfigReader, Context context) {
        filesystemFacade_ = filesystemFacade;
        componentConfigReader_ = componentConfigReader;
        context_ = context;
    }

    private void addSourceFile(DirEntry entry, Component component) {
        if (entry.name.baseName.startsWith(".")) {
            return;
        }
        try {
            auto language = context_.config.sourceFileExtensionToLanguageMap[entry.name.extension];
            component.sourceFiles ~= entry.name;
        }
        catch (Exception e) {
        }
    }

    private void readSourceDirRecursive(string dirName, ComponentConfig buildConfig, ref Component[] components) {
        auto configFile = buildPath(dirName, context_.config.expectedComponentConfigFileName);
        auto componentComponentConfig = componentConfigReader_.read(configFile, buildConfig);
        auto component = new Component(dirName, componentComponentConfig,
            dirName == context_.config.expectedSourceDirName ? Component.Type.root : Component.Type.normal);
        auto entries = filesystemFacade_.listDir(dirName, SpanMode.shallow);
        foreach (entry; entries) {
            if (entry.isDir) {
                readSourceDirRecursive(entry.name, component.config, components);
            }
            else if (entry.isFile) {
                addSourceFile(entry, component);
            }
        }
        components ~= component;
    }

    Tree read(const string root) {
        Component[] components;
        readSourceDirRecursive(root, context_.defaultComponentConfig, components);
        return new Tree(root, components);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ComponentConfigReader componentConfigReader_;
    Context context_;

}

