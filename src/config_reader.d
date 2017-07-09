module config_reader;

import vibe.data.json;
import std.path: buildPath, baseName, dirName, stripExtension;

import yabs_config;
import interfaces.filesystem_facade;

class ConfigReader {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    YabsConfig readYabsConfig(const string dir) {
        immutable string configFileName = "db/config.json";
        immutable string languagesInfoDir = "db/languages";
        auto json = filesystemFacade_.readText(buildPath(dir, configFileName))
            .parseJsonString;
        Json languages = Json.emptyObject;
        foreach (entry; filesystemFacade_.listDir(buildPath(dir, languagesInfoDir), SpanMode.shallow)) {
            auto languageInfo = filesystemFacade_.readText(entry.name).parseJsonString;
            languages[entry.name.baseName.stripExtension] = languageInfo;
        }
        json["languagesInfo"] = languages;
        return json.deserializeJson!YabsConfig;
    }

private:
    IFilesystemFacade filesystemFacade_;
}



