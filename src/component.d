module component;

public import component_config: ComponentConfig;

class Component {

    enum Type {
        normal, root
    }

    string[] objectFiles;
    string[] sourceFiles;

    this(const string path, ComponentConfig config, Type type) {
        path_ = path;
        config_ = config;
        type_ = type;
    }

    @property
    string path() const {
        return path_;
    }

    @property
    ComponentConfig config() {
        return config_;
    }

    @property
    Type type() const {
        return type_;
    }

private:
    immutable string path_;
    ComponentConfig config_;
    Type type_;

}

