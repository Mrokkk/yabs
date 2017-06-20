module compilers_map_builder;

import std.path: buildPath, extension;

import compiler: Compiler;
import yabs_config: YabsConfig;
import compilers_map: CompilersMap;

import interfaces.compiler;
import interfaces.filesystem_facade;

class CompilersMapBuilder {

    this(IFilesystemFacade filesystemFacade, YabsConfig yabsConfig) {
        filesystemFacade_ = filesystemFacade;
        yabsConfig_ = yabsConfig;
    }

    private void addCompilerIfDoesntExist(const ref string language, ref ICompiler[string] compilers) {
        if (!(language in compilers)) {
            compilers[language] = new Compiler(language, yabsConfig_.languages[language].defaultCompiler);
        }
    }

    private void readCompilersForComponent(Component component, ref ICompiler[string] compilers) {
        foreach (sourceFile; component.sourceFiles) {
            auto language = yabsConfig_.sourceFileExtensionToLanguageMap[sourceFile.extension];
            addCompilerIfDoesntExist(language, compilers);
        }
    }

    CompilersMap build(Component[] components) {
        ICompiler[string] compilers;
        foreach (component; components) {
            readCompilersForComponent(component, compilers);
        }
        return new CompilersMap(compilers);
    }

private:
    IFilesystemFacade filesystemFacade_;
    YabsConfig yabsConfig_;

}

