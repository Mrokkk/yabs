module builders.library_builder;

import tree_reader;
import task_runner;
import task_creator;
import project_config;
import interfaces.builder;
import interfaces.filesystem_facade;

class LibraryBuilder : IBuilder {

    this(IFilesystemFacade filesystemFacade, ProjectConfig projectConfig, TreeReader treeReader,
            TaskCreator taskCreator, TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    void build(BuildType buildType) {
        auto sharedLibraryTask = taskCreator_.createSharedLibraryTask(projectConfig_.projectName,
                projectConfig_.rootDir,
                treeReader_.read(projectConfig_.sourceDir));
        taskRunner_.call(sharedLibraryTask);
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
}

