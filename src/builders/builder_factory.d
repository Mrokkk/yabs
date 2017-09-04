module builders.builder_factory;

public import interfaces.builder;
public import builders.tests_builder;
public import builders.library_builder;
public import builders.application_builder;

import args_parser;
import tree_reader;
import task_runner;
import task_creator;
import config_reader;
import project_config;
import filesystem_facade;

class BuilderFactory {

    this(IFilesystemFacade filesystemFacade,
            ProjectConfig projectConfig,
            TreeReader treeReader,
            TaskCreator taskCreator,
            TaskRunner taskRunner) {
        filesystemFacade_ = filesystemFacade;
        projectConfig_ = projectConfig;
        treeReader_ = treeReader;
        taskCreator_ = taskCreator;
        taskRunner_ = taskRunner;
    }

    IBuilder create(const Args args) {
        IBuilder builder;
        if (args.command == Command.test) {
            builder = new TestsBuilder(filesystemFacade_, projectConfig_, treeReader_, taskCreator_, taskRunner_);
        }
        else {
            switch (projectConfig_.targetType) {
                case TargetType.application:
                    builder = new ApplicationBuilder(filesystemFacade_, projectConfig_, treeReader_, taskCreator_, taskRunner_);
                    break;
                case TargetType.library:
                    builder = new LibraryBuilder(filesystemFacade_, projectConfig_, treeReader_, taskCreator_, taskRunner_);
                    break;
                default: break;
            }
        }
        return builder;
    }

private:
    IFilesystemFacade filesystemFacade_;
    ProjectConfig projectConfig_;
    TreeReader treeReader_;
    TaskCreator taskCreator_;
    TaskRunner taskRunner_;
}

