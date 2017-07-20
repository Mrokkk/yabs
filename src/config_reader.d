module config_reader;

import std.algorithm;
import vibe.data.json;
import std.path: buildPath, baseName, dirName, stripExtension;

import yabs_config;
import project_config;
import interfaces.filesystem_facade;

class ConfigReader {

    this(IFilesystemFacade filesystemFacade) {
        filesystemFacade_ = filesystemFacade;
    }

    YabsConfig readYabsConfig(const ref string dir) {
        immutable string configFileName = "db/config.json";
        immutable string languagesInfoDir = "db/languages";
        auto json = filesystemFacade_.readText(buildPath(dir, configFileName))
            .parseJsonString;
        Json languages = Json.emptyObject;
        filesystemFacade_.listDir(buildPath(dir, languagesInfoDir), SpanMode.shallow)
            .each!((ref entry) {
                auto languageInfo = filesystemFacade_.readText(entry.name).parseJsonString;
                languages[entry.name.baseName.stripExtension] = languageInfo;
            });
        json["languagesInfo"] = languages;
        return json.deserializeJson!YabsConfig;
    }

    void setDirs(ProjectConfig projectConfig, const string projectRoot, YabsConfig yabsConfig) {
        projectConfig.rootDir = projectRoot;
        projectConfig.sourceDir = buildPath(projectRoot, yabsConfig.expectedSourceDirName);
        projectConfig.testsDir = buildPath(projectRoot, yabsConfig.expectedTestsDirName);
        projectConfig.buildDir = buildPath(projectRoot, yabsConfig.buildDirName);
    }

    ProjectConfig readProjectConfig(YabsConfig yabsConfig) {
        const auto projectRoot = filesystemFacade_.getCurrentDir();
        immutable auto configFileName = buildPath(projectRoot, yabsConfig.expectedComponentConfigFileName);
        ProjectConfig projectConfig;
        auto json = filesystemFacade_.readText(configFileName).parseJsonString;
        projectConfig = json.deserializeJson!ProjectConfig;
        projectConfig.projectName = projectRoot.baseName;
        setDirs(projectConfig, projectRoot, yabsConfig);
        return projectConfig;
    }

private:
    IFilesystemFacade filesystemFacade_;
}

