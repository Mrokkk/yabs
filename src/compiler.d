module compiler;

import std.format;

import source_files_group;

class GccCompiler {

    this(const string path) {
        path_ = path;
    }

    string generateCompileCommand(const string sourceFile, const string objectFile, SourceFilesConfig config) {
        return "{} -c -MMD -fPIC -shared %s %(-I%s%| %) -o %s %s".format(path_,
                config.compileFlags,
                config.includeDirs,
                objectFile,
                sourceFile);
    }

private:
    immutable string path_;
}

