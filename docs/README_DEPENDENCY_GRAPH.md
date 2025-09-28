# Dependency Graph Generator

This tool generates visual dependency graphs for the AWSS3Light solution, showing the relationships between projects and external packages.

## Prerequisites

- .NET SDK (already installed if you're working with this solution)
- PowerShell
- Graphviz (optional, for visualization)

## Usage

### Generate Dependency Graphs

Run the PowerShell script to generate dependency graphs:

```powershell
# On Windows
.\GenerateDependencyGraph.ps1

# On macOS/Linux
pwsh ./GenerateDependencyGraph.ps1
```

This will:
1. Create a temporary .NET console application
2. Compile and run the dependency graph generator
3. Generate DOT files for the dependency graphs
4. Clean up temporary files

### Generate Dependency Graphs with Visualization

If you want to automatically install Graphviz and generate PNG visualizations:

```powershell
# On Windows
.\GenerateDependencyGraph.ps1 -InstallGraphviz

# On macOS/Linux
pwsh ./GenerateDependencyGraph.ps1 -InstallGraphviz
```

## Output Files

The script generates the following files:

- `project_dependencies.dot` - DOT file showing only project-to-project dependencies
- `full_dependencies.dot` - DOT file showing both project and package dependencies
- `project_dependencies.png` - Visualization of project dependencies (if Graphviz is installed)
- `full_dependencies.png` - Visualization of all dependencies (if Graphviz is installed)

## Manual Visualization

If you have Graphviz installed but didn't use the `-InstallGraphviz` option, you can manually generate the PNG files:

```bash
dot -Tpng project_dependencies.dot -o project_dependencies.png
dot -Tpng full_dependencies.dot -o full_dependencies.png
```

## Understanding the Graphs

- **Blue boxes**: .NET projects in the solution
- **Green boxes**: External NuGet packages
- **Arrows**: Dependencies (arrows point from the dependency to the dependent project)

## Customizing the Generator

If you need to customize the dependency graph generator:

1. Modify the `DependencyGraphGenerator.cs` file
2. Run the PowerShell script again to apply your changes