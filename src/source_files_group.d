module source_files_group;

class SourceFilesConfig {
    string configFile;
    string compileFlags;
}

class SourceFilesGroup {
    string[] sourceFiles;
    SourceFilesConfig config;
}

