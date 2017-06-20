module interfaces.linker;

public import binary: Binary;

interface ILinker {

    @property string path() immutable;
    Binary link(const string[] objectFiles, Binary[] libraries, Binary.Type outputTargetType, const string output, const string rpath = "", const string flags = "");

}

