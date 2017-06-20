module project_config_reader;

import std.path: buildPath, baseName, stripExtension;

import vibe.data.json: deserializeJson, parseJsonString;

import interfaces.filesystem_facade;
import project_config: ProjectConfig;

class ProjectConfigReader {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    ProjectConfig read(const string configFileName) {
        if (!filesystemFacade_.fileExists(configFileName)) {
            return new ProjectConfig;
        }
        auto json = filesystemFacade_.readText(configFileName).parseJsonString;
        return json.deserializeJson!ProjectConfig;
    }

private:
    IFilesystemFacade filesystemFacade_;

}

