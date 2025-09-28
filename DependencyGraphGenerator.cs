using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;

namespace DependencyGraphGenerator
{
    class Program
    {
        static void Main(string[] args)
        {
            string solutionDir = Directory.GetCurrentDirectory();
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
}