module project_config;

import vibe.data.json: optional, ignore, byName;

enum TargetType {
    none, application, library
}

class ProjectConfig {
    @optional string projectName;
    @ignore string rootDir;
    @ignore string sourceDir;
    @ignore string testsDir;
    @ignore string buildDir;
    @optional @byName TargetType targetType = TargetType.none;
}

