module app;

import std.conv: to;
import std.stdio: writeln;
import std.format: format;
import std.process: spawnShell, wait;
import std.algorithm: startsWith;
import core.exception: RangeError;
import std.getopt: getopt, defaultGetoptPrinter;
import std.path: dirName, baseName, absolutePath, buildPath, buildNormalizedPath;

import yabs: Yabs;
import tree_reader;
import binary: Binary;
import context: Context;
import build_type: BuildType;
import yabs_config: YabsConfig;
import directories: Directories;
import project_config: ProjectConfig;
import component_config: ComponentConfig;
import filesystem_facade: FilesystemFacade;
import yabs_config_reader: YabsConfigReader;
import compilers_map_builder: CompilersMapBuilder;
import project_config_reader: ProjectConfigReader;
import component_config_reader: ComponentConfigReader;

class Options {
    string command;
    BuildType build;
    bool show_progress;
    bool color;
    bool verbose;
}

Options readOptions(string[] args) {
    immutable string defaultCommand = "run";
    auto options = new Options;
    try {
        if (!args[1].startsWith("-")) {
            options.command = args[1];
        }
        else {
            options.command = defaultCommand;
        }
    }
    catch (RangeError) {
        options.command = defaultCommand;
    }
    auto helpInformation = getopt(args,
            "build", &options.build,
            "show_progress", &options.show_progress,
            "color", &options.color,
            "verbose", &options.verbose
    );
    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("YABS - build system for C and C++", helpInformation.options);
    }
    return options;
}

int main(string[] args) {

    auto options = readOptions(args);

    auto filesystemFacade = new FilesystemFacade;
    auto baseDir = args[0].absolutePath.dirName.buildNormalizedPath;
    auto projectRoot = filesystemFacade.getCurrentDir();
    auto yabsConfigReader = new YabsConfigReader(filesystemFacade);
    auto yabsConfig = yabsConfigReader.read(baseDir);
    auto defaultComponentConfig = new ComponentConfig;

    auto projectConfigReader = new ProjectConfigReader(filesystemFacade);
    auto projectConfig = projectConfigReader.read(buildPath(projectRoot, yabsConfig.expectedComponentConfigFileName));

    auto directories = new Directories(baseDir,
            projectRoot,
            buildPath(projectRoot, yabsConfig.expectedSourceDirName),
            buildPath(projectRoot, yabsConfig.expectedTestsDirName),
            buildPath(projectRoot, yabsConfig.buildDirName));

    auto context = new Context(baseDir,
            projectRoot,
            projectRoot.baseName,
            buildPath(projectRoot, yabsConfig.buildDirName),
            projectConfig,
            yabsConfig,
            defaultComponentConfig);

    auto componentConfigReader = new ComponentConfigReader(filesystemFacade);
    auto treeReader = new TreeReader(filesystemFacade, componentConfigReader, context);
    auto compilersMapBuilder = new CompilersMapBuilder(filesystemFacade, yabsConfig);

    auto yabs = new Yabs(filesystemFacade,
            treeReader,
            compilersMapBuilder,
            context);

    try {
        writeln("# Build config: %s".format(options.build.to!string));
        switch (options.command) {
            case "run":
                yabs.runApp(options.build);
                break;
            case "build":
                yabs.build(options.build);
                break;
            default: break;
        }
        return 0;
    }
    catch (Exception exception) {
        writeln(exception);
        return -1;
    }
}

