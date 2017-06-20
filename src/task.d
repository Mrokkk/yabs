module task;

class Task {

    immutable string command;
    const string[] prerequisite;
    immutable string result;
    Task[] dependencies;

    this(const string command, const string[] prerequisite, const string result, ref Task[] dependencies) {
        this.command = command;
        this.prerequisite = prerequisite;
        this.result = result;
        this.dependencies = dependencies;
    }

}

