module app;

import std.stdio;
import std.path: dirName, absolutePath;

import tree_reader;
import yabs_config;
import config_reader;
import filesystem_facade;
import interfaces.filesystem_facade;

class Task {

    immutable string command;
    const string[] input;
    immutable string output;
    Task[] dependencies;

    this(const string command, const string[] input, const string output, ref Task[] dependencies) {
        this.command = command;
        this.input = input;
        this.output = output;
        this.dependencies = dependencies;
    }

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

