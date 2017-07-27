module builders.tests_builder;

import tree_reader;
import task_runner;
import task_creator;
import project_config;
import interfaces.builder;
import interfaces.filesystem_facade;

class TestsBuilder : IBuilder {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig, TreeReader treeReader,
            TaskCreator taskCreator, TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    void build(BuildType buildType) {
        auto sourceTree = treeReader_.read(projectConfig_.sourceDir);
        auto sourceSharedLibTask = taskCreator_.createSharedLibraryTask(projectConfig_.projectName,
                projectConfig_.buildDir, sourceTree.sourceFilesGroups[0 .. $-1]);
        Task[] libs = [sourceSharedLibTask];
        auto testsTree = treeReader_.read(projectConfig_.testsDir);
        try {
            auto testsLibName = projectConfig_.projectName ~ "_tests";
            auto testsSharedLibTask = taskCreator_.createSharedLibraryTask(testsLibName,
                    projectConfig_.buildDir, testsTree.sourceFilesGroups[0 .. $-1]);
            libs ~= testsSharedLibTask;
        }
        catch (Error) {
        }
        auto testsApplicationName = projectConfig_.projectName ~ "_tests";
        auto targetTask = taskCreator_.createApplicationTask(testsApplicationName, testsTree.sourceFilesGroups[$-1], libs);
        taskRunner_.call(targetTask);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
}

