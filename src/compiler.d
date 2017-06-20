module compiler;

import std.format: format;

import interfaces.compiler;
import component: Component;

class Compiler : ICompiler {

    this(const string language, const string path) {
        language_ = language;
        path_ = path;
    }

    @property
    string path() const {
        return path_;
    }

    @property
    string language() const {
        return language_;
    }

    string compileCommand(string input, string output, ComponentConfig componentConfig, Component.Type type) {
        string libraryFlags;
        switch (type) {
            case Component.Type.normal: {
                libraryFlags = "-fPIC -shared";
                break;
            }
            default:
        }
        return "%s -c -MMD %s %s -o %s %s".format(path_, componentConfig.additionalFlags, libraryFlags, output, input);
    }

private:
    immutable string language_;
    immutable string path_;

}

