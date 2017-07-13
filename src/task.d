module task;

class Task {

    immutable string command;
    const string[] input;
    immutable string output;
    Task[] dependencies;

    this(const string command, const string[] input, const string output, ref Task[] dependencies) {
        this.command = command;
        this.input = input;
        this.output = output;
        this.dependencies = dependencies;
    }

}

