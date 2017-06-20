module context;

import std.stdio: writeln;

import yabs_config: YabsConfig;
import project_config: ProjectConfig;
import component_config: ComponentConfig;

class Context {

    this(string baseDir, string projectRoot, string projectName,
            string buildDir, ProjectConfig projectConfig, YabsConfig config,
            ComponentConfig defaultComponentConfig) {
        baseDir_ = baseDir;
        projectRoot_ = projectRoot;
        projectName_ = projectName;
        buildDir_ = buildDir;
        projectConfig_ = projectConfig;
        config_ = config;
        defaultComponentConfig_ = defaultComponentConfig;
    }

    @property
    string baseDir() {
        return baseDir_;
    }

    @property
    string projectRoot() {
        return projectRoot_;
    }

    @property
    string projectName() {
        return projectName_;
    }

    @property
    string buildDir() {
        return buildDir_;
    }

    @property
    ProjectConfig projectConfig() {
        return projectConfig_;
    }

    @property
    YabsConfig config() {
        return config_;
    }

    @property
    ComponentConfig defaultComponentConfig() {
        return defaultComponentConfig_;
    }

    void print() {
        writeln("# Base dir " ~ baseDir_);
        writeln("# Project root " ~ projectRoot_);
        writeln("# Build dir " ~ buildDir_);
        writeln("");
    }

private:
    immutable string baseDir_;
    immutable string projectRoot_;
    immutable string projectName_;
    immutable string buildDir_;
    ProjectConfig projectConfig_;
    YabsConfig config_;
    ComponentConfig defaultComponentConfig_;

}

