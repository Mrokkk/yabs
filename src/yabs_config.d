module yabs_config;

class LanguageInfo {
    string defaultCompiler;
    string[] sourceFileExtensions;
    string[] headerFileExtensions;
    string defaultLinker;
    string objectFileExtension;
}

class YabsConfig {
    string expectedSourceDirName;
    string expectedTestsDirName;
    string expectedComponentConfigFileName;
    string buildDirName;
    string[string] sourceFileExtensionToLanguageMap;
    LanguageInfo[string] languages;
}

