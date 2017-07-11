module project_config;

import vibe.data.json: optional;

class ProjectConfig {
    @optional string rootDir;
    @optional string sourceDir;
    @optional string testsDir;
    @optional string buildDir;
    string targetType;
}

