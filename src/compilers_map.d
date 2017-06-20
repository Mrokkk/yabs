module compilers_map;

import interfaces.compiler;

class CompilersMap {

    this(ref ICompiler[string] map) {
        map_ = map;
    }

    ref ICompiler opIndex(const string index) {
        return map_[index];
    }

    private ICompiler[string] map_;

}

