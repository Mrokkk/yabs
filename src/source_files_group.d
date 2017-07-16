module source_files_group;

class SourceFilesConfig {
    string configFile;
    string compileFlags;
    string[] includeDirs;
}

class SourceFilesGroup {
    string[] sourceFiles;
    SourceFilesConfig config;
}

