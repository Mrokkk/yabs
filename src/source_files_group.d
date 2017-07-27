module source_files_group;

class SourceFilesConfig {

    this() {
        configFile = "";
        compileFlags = "";
        includeDirs = [];
    }

    this(const string configFile, const string compileFlags,
            const string[] includeDirs) {
        this.configFile = configFile;
        this.compileFlags = compileFlags;
        this.includeDirs = cast(immutable)includeDirs;
    }

    immutable string configFile;
    immutable string compileFlags;
    immutable string[] includeDirs;
}

class SourceFilesGroup {
    string[] sourceFiles;
    SourceFilesConfig config;
}

