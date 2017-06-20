module project_config;

import vibe.data.json: optional;

class ProjectConfig {
    string targetType;
    @optional string compilerFlags;
}

