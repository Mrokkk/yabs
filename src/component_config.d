module component_config;

import vibe.data.json: optional;

class ComponentConfig {
    @optional string compilerPath;
    @optional string additionalFlags;
}

