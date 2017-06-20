module yabs_config_reader;

import std.path: buildPath, baseName, stripExtension;

import vibe.data.json: Json, deserializeJson, parseJsonString;

import interfaces.filesystem_facade;
import yabs_config: YabsConfig, LanguageInfo;

class YabsConfigReader {

    immutable string configDir = "db";
    immutable string configFile = "config.json";
    immutable string languagesDir = "languages";

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    YabsConfig read(const string baseDir) {
        auto json = filesystemFacade_.readText(buildPath(baseDir, configDir, configFile))
            .parseJsonString;
        Json languages = Json.emptyObject;
        foreach (entry; filesystemFacade_.listDir(buildPath(baseDir, configDir, languagesDir), SpanMode.shallow)) {
            auto languageInfo = filesystemFacade_.readText(entry.name).parseJsonString;
            languages[entry.name.baseName.stripExtension] = languageInfo;
        }
        json["languages"] = languages;
        return json.deserializeJson!YabsConfig;
    }

private:
    IFilesystemFacade filesystemFacade_;

}

