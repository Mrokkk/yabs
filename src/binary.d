module binary;

class Binary {

    enum Type {
        executable, sharedLibrary, staticLibrary
    }

    this(const string path, const Type type) {
        path_ = path;
        type_ = type;
    }

    @property
    string path() const {
        return path_;
    }

    Type type() const {
        return type_;
    }

private:
    immutable string path_;
    immutable Type type_;

}

