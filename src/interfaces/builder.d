module interfaces.builder;

public import args_parser: BuildType; // FIXME

interface IBuilder {
    void build(BuildType buildType);
}

