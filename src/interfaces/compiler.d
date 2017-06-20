module interfaces.compiler;

public import component: Component;
public import component_config: ComponentConfig;

public interface ICompiler {

    @property string path() const;
    @property string language() const;
    string compileCommand(string input, string output, ComponentConfig buildConfig, Component.Type type);

}

