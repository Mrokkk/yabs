module app;

import std.path: dirName;

import yabs_config;
import config_reader;
import filesystem_facade;
import interfaces.filesystem_facade;

int main(string[] args) {

    auto filesystemFacade = new FilesystemFacade;

    auto baseDir = args[0].dirName;
    auto currentDir = filesystemFacade.getCurrentDir();

    auto configReader = new ConfigReader(filesystemFacade);
    auto yabsConfig = configReader.readYabsConfig(baseDir);

    auto projectConfig = configReader.readProjectConfig(yabsConfig, currentDir);

    return 0;
}

