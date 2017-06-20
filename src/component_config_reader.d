module component_config_reader;

import std.string: empty;
import std.path: buildPath, baseName, stripExtension;
import vibe.data.json: deserializeJson, parseJsonString;

import interfaces.filesystem_facade;
import component_config: ComponentConfig;

class ComponentConfigReader {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    ComponentConfig read(const string configFileName, ComponentConfig parentConfig) {
        if (!filesystemFacade_.fileExists(configFileName)) {
            return parentConfig;
        }
        auto json = filesystemFacade_.readText(configFileName).parseJsonString;
        auto componentConfig = json.deserializeJson!ComponentConfig;
        componentConfig.additionalFlags = parentConfig.additionalFlags.empty
            ? componentConfig.additionalFlags
            : parentConfig.additionalFlags ~ " " ~ componentConfig.additionalFlags;
        return componentConfig;
    }

private:
    IFilesystemFacade filesystemFacade_;

}

