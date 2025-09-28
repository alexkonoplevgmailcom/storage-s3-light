param (
    [switch]$InstallGraphviz = $false
)

# Check if Graphviz is installed
$graphvizInstalled = $false
try {
    $dotVersion = dot -V 2>&1
    if ($dotVersion -match "graphviz") {
        $graphvizInstalled = $true
        Write-Host "Graphviz is already installed: $dotVersion" -ForegroundColor Green
    }
}
catch {
    $graphvizInstalled = $false
    Write-Host "Graphviz is not installed" -ForegroundColor Yellow
}

# Install Graphviz if requested and not already installed
if ($InstallGraphviz -and -not $graphvizInstalled) {
    if ($IsWindows) {
        Write-Host "Installing Graphviz using Chocolatey..." -ForegroundColor Cyan
        try {
            # Check if Chocolatey is installed
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                Write-Host "Chocolatey is not installed. Installing Chocolatey..." -ForegroundColor Yellow
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            choco install graphviz -y
        }
        catch {
            Write-Host "Failed to install Graphviz. Please install it manually from https://graphviz.org/download/" -ForegroundColor Red
            exit 1
        }
    }
    elseif ($IsMacOS) {
        Write-Host "Installing Graphviz using Homebrew..." -ForegroundColor Cyan
        try {
            # Check if Homebrew is installed
            if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                Write-Host "Homebrew is not installed. Installing Homebrew..." -ForegroundColor Yellow
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            brew install graphviz
        }
        catch {
            Write-Host "Failed to install Graphviz. Please install it manually using 'brew install graphviz'" -ForegroundColor Red
            exit 1
        }
    }
    elseif ($IsLinux) {
        Write-Host "Installing Graphviz using apt..." -ForegroundColor Cyan
        try {
            sudo apt-get update
            sudo apt-get install -y graphviz
        }
        catch {
            Write-Host "Failed to install Graphviz. Please install it manually using your package manager" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Unsupported OS. Please install Graphviz manually from https://graphviz.org/download/" -ForegroundColor Red
        exit 1
    }
}

# Create a temporary directory for the tool
$tempDir = Join-Path $PSScriptRoot "DependencyGraphTool"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create a simple console app
Write-Host "Compiling and running dependency graph generator..." -ForegroundColor Cyan
Set-Location -Path $tempDir
dotnet new console

# Create the Program.cs file with our dependency graph generator code
$programCs = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;

class Program
{
    static void Main(string[] args)
    {
        string solutionDir = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), ".."));
        Console.WriteLine($"Looking for project files in: {solutionDir}");
        
        // Only look in the src directory
        string srcDir = Path.Combine(solutionDir, "src");
        if (!Directory.Exists(srcDir))
        {
            Console.WriteLine($"Source directory not found: {srcDir}");
            return;
        }
        
        var projectFiles = Directory.GetFiles(srcDir, "*.csproj", SearchOption.AllDirectories);
        Console.WriteLine($"Found {projectFiles.Length} project files");
        
        var dependencies = new Dictionary<string, List<string>>();
        var packageReferences = new Dictionary<string, List<string>>();
        
        // Parse all project files to extract dependencies
        foreach (var projectFile in projectFiles)
        {
            try
            {
                string projectName = Path.GetFileNameWithoutExtension(projectFile);
                string projectContent = File.ReadAllText(projectFile);
                
                // Parse XML content
                XDocument doc = XDocument.Parse(projectContent);
                
                // Get project references
                var projectRefs = doc.Descendants()
                    .Where(x => x.Name.LocalName == "ProjectReference")
                    .Select(x => x.Attribute("Include")?.Value)
                    .Where(x => x != null)
                    .Select(x => {
                        // Handle both Windows and Unix paths
                        string path = x.Replace("..\\", "").Replace("../", "");
                        return Path.GetFileNameWithoutExtension(path);
                    })
                    .ToList();
                
                dependencies[projectName] = projectRefs;
                
                // Get package references
                var packageRefs = doc.Descendants()
                    .Where(x => x.Name.LocalName == "PackageReference")
                    .Select(x => new { 
                        Name = x.Attribute("Include")?.Value, 
                        Version = x.Attribute("Version")?.Value 
                    })
                    .Where(x => x.Name != null && x.Version != null)
                    .Select(x => $"{x.Name} {x.Version}")
                    .ToList();
                
                packageReferences[projectName] = packageRefs;
                
                Console.WriteLine($"Processed {projectName}: {projectRefs.Count} project references, {packageRefs.Count} package references");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing {projectFile}: {ex.Message}");
            }
        }
        
        // Generate DOT file for project dependencies
        GenerateDotFile(dependencies, "project_dependencies.dot");
        
        // Generate DOT file for project and package dependencies
        GenerateFullDotFile(dependencies, packageReferences, "full_dependencies.dot");
        
        Console.WriteLine("Dependency graph files generated:");
        Console.WriteLine("- project_dependencies.dot (Project dependencies only)");
        Console.WriteLine("- full_dependencies.dot (Project and package dependencies)");
    }
    
    static void GenerateDotFile(Dictionary<string, List<string>> dependencies, string fileName)
    {
        var sb = new StringBuilder();
        sb.AppendLine("digraph ProjectDependencies {");
        sb.AppendLine("  rankdir=LR;");
        sb.AppendLine("  node [shape=box, style=filled, fillcolor=lightblue];");
        
        // Add all projects as nodes first
        foreach (var project in dependencies.Keys)
        {
            sb.AppendLine($"  \"{project}\" [style=filled, fillcolor=lightblue];");
        }
        
        // Add dependency relationships
        foreach (var project in dependencies.Keys)
        {
            foreach (var dependency in dependencies[project])
            {
                sb.AppendLine($"  \"{dependency}\" -> \"{project}\";");
            }
        }
        
        sb.AppendLine("}");
        
        File.WriteAllText(fileName, sb.ToString());
    }
    
    static void GenerateFullDotFile(Dictionary<string, List<string>> projectDependencies, 
                                   Dictionary<string, List<string>> packageReferences, 
                                   string fileName)
    {
        var sb = new StringBuilder();
        sb.AppendLine("digraph FullDependencies {");
        sb.AppendLine("  rankdir=LR;");
        sb.AppendLine("  node [shape=box];");
        
        // Project nodes
        sb.AppendLine("  // Project nodes");
        foreach (var project in projectDependencies.Keys)
        {
            sb.AppendLine($"  \"{project}\" [style=filled, fillcolor=lightblue];");
        }
        
        // Package nodes
        sb.AppendLine("\n  // Package nodes");
        var allPackages = new HashSet<string>();
        foreach (var packages in packageReferences.Values)
        {
            foreach (var package in packages)
            {
                string packageName = package.Split(' ')[0];
                allPackages.Add(packageName);
            }
        }
        
        foreach (var package in allPackages)
        {
            sb.AppendLine($"  \"{package}\" [style=filled, fillcolor=lightgreen];");
        }
        
        // Project dependencies
        sb.AppendLine("\n  // Project dependencies");
        foreach (var project in projectDependencies.Keys)
        {
            foreach (var dependency in projectDependencies[project])
            {
                sb.AppendLine($"  \"{dependency}\" -> \"{project}\";");
            }
        }
        
        // Package dependencies
        sb.AppendLine("\n  // Package dependencies");
        foreach (var project in packageReferences.Keys)
        {
            foreach (var package in packageReferences[project])
            {
                string packageName = package.Split(' ')[0];
                sb.AppendLine($"  \"{packageName}\" -> \"{project}\";");
            }
        }
        
        sb.AppendLine("}");
        
        File.WriteAllText(fileName, sb.ToString());
    }
}
"@

Set-Content -Path "Program.cs" -Value $programCs

# Run the program
dotnet run

# Generate PNG files if Graphviz is installed
if ($graphvizInstalled -or $InstallGraphviz) {
    Write-Host "Generating PNG visualizations..." -ForegroundColor Cyan
    dot -Tpng project_dependencies.dot -o project_dependencies.png
    dot -Tpng full_dependencies.dot -o full_dependencies.png
    
    Write-Host "Dependency graph images generated:" -ForegroundColor Green
    Write-Host "- project_dependencies.png (Project dependencies only)" -ForegroundColor Green
    Write-Host "- full_dependencies.png (Project and package dependencies)" -ForegroundColor Green
    
    # Move files to parent directory
    Copy-Item -Path "project_dependencies.png" -Destination "../" -Force
    Copy-Item -Path "full_dependencies.png" -Destination "../" -Force
    Copy-Item -Path "project_dependencies.dot" -Destination "../" -Force
    Copy-Item -Path "full_dependencies.dot" -Destination "../" -Force
}
else {
    Write-Host "Graphviz is not installed. DOT files have been generated but not converted to PNG." -ForegroundColor Yellow
    Write-Host "To install Graphviz and generate PNG files, run this script with the -InstallGraphviz switch" -ForegroundColor Yellow
    
    # Move DOT files to parent directory
    Copy-Item -Path "project_dependencies.dot" -Destination "../" -Force
    Copy-Item -Path "full_dependencies.dot" -Destination "../" -Force
}

# Clean up
Set-Location -Path ".."
Remove-Item -Path "DependencyGraphTool" -Recurse -Force

Write-Host "Done!" -ForegroundColor Green