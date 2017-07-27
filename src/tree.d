module tree;

public import compiler;
public import source_files_group;

class Tree {

    this(ref SourceFilesGroup[] sourceFilesGroups, Compiler compiler) {
        sourceFilesGroups_ = sourceFilesGroups;
        compiler_ = compiler;
    }

    ref SourceFilesGroup[] sourceFilesGroups() {
        return sourceFilesGroups_;
    }

    Compiler compiler() {
        return compiler_;
    }

private:
    SourceFilesGroup[] sourceFilesGroups_;
    Compiler compiler_;
}

