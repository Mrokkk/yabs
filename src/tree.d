module tree;

import component;

class Tree {

    this(const string path, Component[] components) {
        this.path = path;
        this.components = components;
    }

    immutable string path;
    Component[] components;

}

