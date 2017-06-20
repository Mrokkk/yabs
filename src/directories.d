module directories;

class Directories {

    immutable string yabsRoot;
    immutable string projectRoot;
    immutable string sourceRoot;
    immutable string testRoot;
    immutable string buildRoot;

    this(const ref string yabsRoot, const string projectRoot,
            const string sourceRoot, const string testRoot,
            const string buildRoot) {
        this.yabsRoot = yabsRoot;
        this.projectRoot = projectRoot;
        this.sourceRoot = sourceRoot;
        this.testRoot = testRoot;
        this.buildRoot = buildRoot;
    }

}

