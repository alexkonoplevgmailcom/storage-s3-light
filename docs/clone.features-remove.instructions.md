# BFB AWSS3Light Feature Selection Extension - GitHub Copilot Instructions

This document provides comprehensive instructions for GitHub Copilot to extend the BFB AWSS3Light Clone & Rename VS Code extension with feature selection capabilities. The extension should allow users to choose which features to keep in their newly created solution, automatically removing unwanted features and all their references.

## Table of Contents
1. [Feature Selection Overview](#feature-selection-overview)
2. [Available Features to Remove](#available-features-to-remove)
3. [User Interface Requirements](#user-interface-requirements)
4. [Feature Removal Logic](#feature-removal-logic)
5. [Dependency Analysis and Cleanup](#dependency-analysis-and-cleanup)
6. [File System Operations](#file-system-operations)
7. [Configuration Updates](#configuration-updates)
8. [Implementation Guidelines](#implementation-guidelines)
9. [Testing Requirements](#testing-requirements)

## Feature Selection Overview

The extended functionality allows users to selectively remove entire feature modules from the BFB AWSS3Light solution during the clone and rename process. This creates cleaner, more focused solutions that only include the technologies and capabilities the user actually needs.

### ⚠️ CRITICAL EXECUTION ORDER
**Feature removal MUST happen BEFORE the standard clone and rename process.** This is essential for:
- **Efficiency**: Avoid wasting time renaming files that will be deleted
- **Accuracy**: Prevent broken references from removed features affecting the rename process
- **Clean Results**: Ensure the final solution only contains references to selected features

**Correct Process Flow:**
1. **Clone repository** (if needed)
2. **Feature Selection Dialog** - User chooses which features to keep
3. **🚨 FEATURE REMOVAL** - Remove unwanted projects, files, and references
4. **Rename Process** - Transform BFB.AWSS3Light.* to BFB.{SolutionName}.*

### Core Concept
- **Feature Modules**: Self-contained functionality groups (Cache, DataAccess, Messaging, etc.)
- **Selective Removal**: Users can choose to exclude specific feature modules
- **Clean Removal**: All references, dependencies, and configurations are automatically cleaned up
- **Consistent Solution**: The resulting solution remains fully functional with only selected features

### Benefits
- **Reduced Complexity**: Eliminate unused technologies and dependencies
- **Cleaner Codebase**: Remove unnecessary project references and configurations
- **Focused Development**: Include only the features needed for the specific project
- **Maintenance Simplicity**: Fewer dependencies to manage and update

## Available Features to Remove

### Feature Categories
Each feature category represents a distinct technology stack or capability that can be independently removed:

```typescript
interface FeatureDefinition {
  id: string;
  name: string;
  description: string;
  projectPatterns: string[];
  dependencyProjects: string[];
  configurationKeys: string[];
  dockerServices: string[];
  testFiles: string[];
  documentationFiles: string[];
}

const availableFeatures: FeatureDefinition[] = [
  {
    id: "cache-redis",
    name: "Redis Caching",
    description: "Redis-based caching implementation",
    projectPatterns: [
      "BFB.AWSS3Light.Cache.Redis"
    ],
    dependencyProjects: [], // No dependencies on other feature projects
    configurationKeys: [
      "ConnectionStrings:Redis",
      "Redis:*",
      "Cache:*"
    ],
    dockerServices: [
      "redis"
    ],
    testFiles: [
      "**/test-redis-*.ps1",
      "**/manage-redis.ps1"
    ],
    documentationFiles: [
      "**/REDIS_*.md"
    ]
  },
  {
    id: "dataaccess-sqlserver",
    name: "SQL Server Data Access",
    description: "Microsoft SQL Server database implementation",
    projectPatterns: [
      "BFB.AWSS3Light.DataAccess.SqlServer"
    ],
    dependencyProjects: [], // Core data access, no dependencies
    configurationKeys: [
      "ConnectionStrings:SqlServer",
      "SqlServer:*"
    ],
    dockerServices: [
      "sqlserver"
    ],
    testFiles: [
      "**/test-*-sqlserver*.ps1",
      "**/manage-sqlserver.ps1",
      "docker-compose.sqlserver.yml"
    ],
    documentationFiles: []
  },
  {
    id: "dataaccess-db2",
    name: "IBM DB2 Data Access",
    description: "IBM DB2 database implementation",
    projectPatterns: [
      "BFB.AWSS3Light.DataAccess.DB2"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "DB2:*"
    ],
    dockerServices: [
      "db2"
    ],
    testFiles: [
      "**/test-*-db2*.ps1",
      "**/manage-db2.ps1",
      "docker-compose.db2.yml"
    ],
    documentationFiles: []
  },
  {
    id: "dataaccess-mongodb",
    name: "MongoDB Data Access",
    description: "MongoDB document database implementation",
    projectPatterns: [
      "BFB.AWSS3Light.DataAccess.MongoDB"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "ConnectionStrings:MongoDB",
      "MongoDB:*"
    ],
    dockerServices: [
      "mongodb"
    ],
    testFiles: [
      "**/test-*-mongodb*.ps1",
      "**/manage-mongodb.ps1",
      "docker-compose.mongodb.yml",
      "init-mongo.js"
    ],
    documentationFiles: []
  },
  {
    id: "dataaccess-oracle",
    name: "Oracle Data Access",
    description: "Oracle database implementation",
    projectPatterns: [
      "BFB.AWSS3Light.DataAccess.Oracle"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "ConnectionStrings:Oracle",
      "Oracle:*"
    ],
    dockerServices: [
      "oracle"
    ],
    testFiles: [
      "**/test-*-oracle*.ps1",
      "**/manage-oracle*.ps1",
      "docker-compose.oracle.yml"
    ],
    documentationFiles: []
  },
  {
    id: "messaging-kafka",
    name: "Apache Kafka Messaging",
    description: "Confluent Kafka messaging implementation",
    projectPatterns: [
      "BFB.AWSS3Light.Messaging.Kafka"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "Kafka:*",
      "Messaging:*"
    ],
    dockerServices: [
      "kafka",
      "zookeeper"
    ],
    testFiles: [
      "**/test-kafka*.ps1",
      "**/manage-kafka*.ps1",
      "**/stress-test-kafka*.ps1",
      "**/throughput-test-kafka*.ps1",
      "docker-compose.kafka.yml"
    ],
    documentationFiles: []
  },
  {
    id: "storage-s3",
    name: "Amazon S3 Storage",
    description: "AWS S3-compatible storage implementation",
    projectPatterns: [
      "BFB.AWSS3Light.Storage.S3"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "AWS:*",
      "S3:*",
      "Storage:*"
    ],
    dockerServices: [
      "minio"
    ],
    testFiles: [
      "**/test-s3*.ps1",
      "docker-compose.minio.yml"
    ],
    documentationFiles: []
  },
  {
    id: "remoteaccess-restapi",
    name: "REST API Remote Access",
    description: "HTTP REST API client implementation",
    projectPatterns: [
      "BFB.AWSS3Light.RemoteAccess.RestApi"
    ],
    dependencyProjects: [],
    configurationKeys: [
      "ExternalAPIs:*",
      "RemoteAccess:*"
    ],
    dockerServices: [],
    testFiles: [
      "**/test-*-restapi*.ps1"
    ],
    documentationFiles: []
  }
];
```

### Feature Dependencies
Some features may have logical dependencies that should be considered:

```typescript
interface FeatureDependency {
  featureId: string;
  dependsOn: string[];
  conflicts: string[];
  recommendations: string[];
}

const featureDependencies: FeatureDependency[] = [
  {
    featureId: "cache-redis",
    dependsOn: [], // Can work independently
    conflicts: [], // No conflicts
    recommendations: ["At least one data access feature recommended"]
  },
  {
    featureId: "dataaccess-sqlserver",
    dependsOn: [],
    conflicts: [],
    recommendations: ["Business Services layer will need at least one data access implementation"]
  },
  // ... similar for other data access features
];
```

## User Interface Requirements

### Feature Selection Dialog
```typescript
interface FeatureSelectionUI {
  title: "Select Features for Your Solution";
  subtitle: "Choose which technologies and capabilities to include. Unselected features will be completely removed.";
  
  sections: [
    {
      title: "Data Access Technologies";
      description: "Database and data persistence implementations";
      features: ["dataaccess-sqlserver", "dataaccess-db2", "dataaccess-mongodb", "dataaccess-oracle"];
      minSelection: 1; // At least one data access method required
      defaultSelection: ["dataaccess-sqlserver"]; // Default to SQL Server
    },
    {
      title: "Caching Systems";
      description: "Distributed caching implementations";
      features: ["cache-redis"];
      minSelection: 0;
      defaultSelection: [];
    },
    {
      title: "Messaging Systems";
      description: "Asynchronous messaging and event streaming";
      features: ["messaging-kafka"];
      minSelection: 0;
      defaultSelection: [];
    },
    {
      title: "Storage Systems";
      description: "File and object storage implementations";
      features: ["storage-s3"];
      minSelection: 0;
      defaultSelection: [];
    },
    {
      title: "Remote Access";
      description: "External service integration capabilities";
      features: ["remoteaccess-restapi"];
      minSelection: 0;
      defaultSelection: [];
    }
  ];
}
```

### UI Implementation Guidelines
```typescript
// VS Code extension UI implementation
const showFeatureSelectionDialog = async (): Promise<string[]> => {
  const quickPick = vscode.window.createQuickPick();
  quickPick.title = "Select Features for Your Solution";
  quickPick.placeholder = "Choose which features to include (unselected will be removed)";
  quickPick.canSelectMany = true;
  
  // Create items grouped by category
  const items: vscode.QuickPickItem[] = [];
  
  // Add section headers and features
  for (const section of featureSelectionSections) {
    // Add section header
    items.push({
      label: `$(folder) ${section.title}`,
      description: section.description,
      kind: vscode.QuickPickItemKind.Separator
    });
    
    // Add features in this section
    for (const featureId of section.features) {
      const feature = availableFeatures.find(f => f.id === featureId);
      if (feature) {
        items.push({
          label: `$(${getFeatureIcon(feature.id)}) ${feature.name}`,
          description: feature.description,
          detail: `Projects: ${feature.projectPatterns.join(', ')}`,
          picked: section.defaultSelection.includes(featureId)
        });
      }
    }
  }
  
  quickPick.items = items;
  
  return new Promise<string[]>((resolve) => {
    quickPick.onDidAccept(() => {
      const selectedFeatures = quickPick.selectedItems
        .filter(item => item.kind !== vscode.QuickPickItemKind.Separator)
        .map(item => getFeatureIdFromLabel(item.label));
      
      // Validate minimum selections
      const validationResult = validateFeatureSelection(selectedFeatures);
      if (!validationResult.isValid) {
        vscode.window.showErrorMessage(validationResult.message);
        return;
      }
      
      resolve(selectedFeatures);
      quickPick.dispose();
    });
    
    quickPick.show();
  });
};
```

## Feature Removal Logic

### Removal Process Overview
```typescript
interface FeatureRemovalPlan {
  selectedFeatures: string[];
  featuresToRemove: string[];
  projectsToRemove: string[];
  filesToRemove: string[];
  configurationsToRemove: string[];
  dependenciesToUpdate: ProjectDependencyUpdate[];
  testFilesToRemove: string[];
  dockerServicesToRemove: string[];
}

const createRemovalPlan = (selectedFeatures: string[]): FeatureRemovalPlan => {
  const allFeatures = availableFeatures.map(f => f.id);
  const featuresToRemove = allFeatures.filter(f => !selectedFeatures.includes(f));
  
  const plan: FeatureRemovalPlan = {
    selectedFeatures,
    featuresToRemove,
    projectsToRemove: [],
    filesToRemove: [],
    configurationsToRemove: [],
    dependenciesToUpdate: [],
    testFilesToRemove: [],
    dockerServicesToRemove: []
  };
  
  // Build comprehensive removal plan
  for (const featureId of featuresToRemove) {
    const feature = availableFeatures.find(f => f.id === featureId);
    if (feature) {
      plan.projectsToRemove.push(...feature.projectPatterns);
      plan.configurationsToRemove.push(...feature.configurationKeys);
      plan.testFilesToRemove.push(...feature.testFiles);
      plan.dockerServicesToRemove.push(...feature.dockerServices);
    }
  }
  
  return plan;
};
```

### Project Removal Logic
```typescript
interface ProjectRemovalOperation {
  projectPath: string;
  projectName: string;
  removeFromSolution: boolean;
  removeDependencies: string[]; // Other projects that reference this one
  removeFolder: boolean;
}

const removeProjects = async (plan: FeatureRemovalPlan): Promise<void> => {
  const operations: ProjectRemovalOperation[] = [];
  
  for (const projectPattern of plan.projectsToRemove) {
    // Find actual project folders matching the pattern
    const projectFolders = await findProjectFolders(projectPattern);
    
    for (const folder of projectFolders) {
      operations.push({
        projectPath: folder.path,
        projectName: folder.name,
        removeFromSolution: true,
        removeDependencies: await findProjectReferences(folder.name),
        removeFolder: true
      });
    }
  }
  
  // Execute removal operations
  await executeProjectRemovals(operations);
};

const executeProjectRemovals = async (operations: ProjectRemovalOperation[]): Promise<void> => {
  for (const operation of operations) {
    // Remove from solution file
    if (operation.removeFromSolution) {
      await removeProjectFromSolution(operation.projectName);
    }
    
    // Remove project references from other projects
    for (const dependentProject of operation.removeDependencies) {
      await removeProjectReference(dependentProject, operation.projectName);
    }
    
    // Remove project folder and files
    if (operation.removeFolder) {
      await removeDirectory(operation.projectPath);
    }
  }
};
```

## Dependency Analysis and Cleanup

### Project Reference Analysis
```typescript
interface ProjectReference {
  projectFile: string;
  referencedProject: string;
  referenceType: 'ProjectReference' | 'PackageReference' | 'Using';
}

const analyzeProjectDependencies = async (): Promise<ProjectReference[]> => {
  const references: ProjectReference[] = [];
  
  // Scan all .csproj files for project references
  const projectFiles = await findFiles('**/*.csproj');
  
  for (const projectFile of projectFiles) {
    const content = await readFile(projectFile);
    
    // Find ProjectReference elements
    const projectReferences = extractProjectReferences(content);
    references.push(...projectReferences.map(ref => ({
      projectFile,
      referencedProject: ref,
      referenceType: 'ProjectReference' as const
    })));
  }
  
  return references;
};

const removeProjectReferences = async (plan: FeatureRemovalPlan): Promise<void> => {
  const allReferences = await analyzeProjectDependencies();
  
  for (const projectToRemove of plan.projectsToRemove) {
    // Find all references to this project
    const referencesToRemove = allReferences.filter(ref => 
      ref.referencedProject.includes(projectToRemove)
    );
    
    // Remove each reference
    for (const reference of referencesToRemove) {
      await removeProjectReferenceFromFile(reference.projectFile, reference.referencedProject);
    }
  }
};
```

### Using Statement Cleanup
```typescript
const cleanupUsingStatements = async (plan: FeatureRemovalPlan): Promise<void> => {
  const csFiles = await findFiles('**/*.cs');
  
  for (const csFile of csFiles) {
    let content = await readFile(csFile);
    let modified = false;
    
    for (const projectToRemove of plan.projectsToRemove) {
      // Convert project name to namespace pattern
      const namespacePattern = projectToRemove.replace('BFB.AWSS3Light.', 'BFB.{SolutionName}.');
      
      // Remove using statements
      const usingRegex = new RegExp(`^using\\s+${escapeRegex(namespacePattern)}.*?;\\s*$`, 'gm');
      if (usingRegex.test(content)) {
        content = content.replace(usingRegex, '');
        modified = true;
      }
    }
    
    if (modified) {
      await writeFile(csFile, content);
    }
  }
};
```

### Service Registration Cleanup
```typescript
const cleanupServiceRegistrations = async (plan: FeatureRemovalPlan): Promise<void> => {
  // Program.cs and other startup files
  const startupFiles = await findFiles('**/Program.cs');
  
  for (const startupFile of startupFiles) {
    let content = await readFile(startupFile);
    let modified = false;
    
    for (const projectToRemove of plan.projectsToRemove) {
      // Remove service registration calls
      const serviceRegex = new RegExp(
        `builder\\.Services\\.Add${extractServiceName(projectToRemove)}\\([^)]*\\);?\\s*`,
        'g'
      );
      
      if (serviceRegex.test(content)) {
        content = content.replace(serviceRegex, '');
        modified = true;
      }
    }
    
    if (modified) {
      await writeFile(startupFile, content);
    }
  }
};
```

## File System Operations

### File and Folder Removal
```typescript
interface FileRemovalOperation {
  path: string;
  type: 'file' | 'directory';
  reason: string; // Why this file is being removed
}

const removeFeatureFiles = async (plan: FeatureRemovalPlan): Promise<void> => {
  const operations: FileRemovalOperation[] = [];
  
  // Remove project directories
  for (const projectPattern of plan.projectsToRemove) {
    const projectDirs = await findDirectories(`src/${projectPattern}`);
    operations.push(...projectDirs.map(dir => ({
      path: dir,
      type: 'directory' as const,
      reason: `Removed feature: ${projectPattern}`
    })));
  }
  
  // Remove test files
  for (const testFilePattern of plan.testFilesToRemove) {
    const testFiles = await findFiles(testFilePattern);
    operations.push(...testFiles.map(file => ({
      path: file,
      type: 'file' as const,
      reason: `Removed test file for removed feature`
    })));
  }
  
  // Remove Docker Compose files for unused services
  for (const dockerService of plan.dockerServicesToRemove) {
    const dockerFiles = await findFiles(`docker-compose.${dockerService}.yml`);
    operations.push(...dockerFiles.map(file => ({
      path: file,
      type: 'file' as const,
      reason: `Removed Docker service: ${dockerService}`
    })));
  }
  
  // Execute removals
  await executeFileRemovals(operations);
};

const executeFileRemovals = async (operations: FileRemovalOperation[]): Promise<void> => {
  for (const operation of operations) {
    try {
      if (operation.type === 'directory') {
        await vscode.workspace.fs.delete(vscode.Uri.file(operation.path), { 
          recursive: true, 
          useTrash: false 
        });
      } else {
        await vscode.workspace.fs.delete(vscode.Uri.file(operation.path));
      }
      
      console.log(`✓ Removed ${operation.type}: ${operation.path} (${operation.reason})`);
    } catch (error) {
      console.warn(`⚠ Failed to remove ${operation.type}: ${operation.path} - ${error}`);
    }
  }
};
```

## Configuration Updates

### AppSettings Cleanup
```typescript
const cleanupConfiguration = async (plan: FeatureRemovalPlan): Promise<void> => {
  const configFiles = await findFiles('**/appsettings*.json');
  
  for (const configFile of configFiles) {
    let config = JSON.parse(await readFile(configFile));
    let modified = false;
    
    for (const configKey of plan.configurationsToRemove) {
      if (removeConfigurationKey(config, configKey)) {
        modified = true;
      }
    }
    
    if (modified) {
      await writeFile(configFile, JSON.stringify(config, null, 2));
    }
  }
};

const removeConfigurationKey = (config: any, keyPattern: string): boolean => {
  let modified = false;
  
  if (keyPattern.includes(':')) {
    // Nested key like "ConnectionStrings:Redis"
    const [section, key] = keyPattern.split(':');
    if (config[section] && config[section][key] !== undefined) {
      delete config[section][key];
      modified = true;
      
      // Remove section if empty
      if (Object.keys(config[section]).length === 0) {
        delete config[section];
      }
    }
  } else if (keyPattern.includes('*')) {
    // Wildcard pattern like "Redis:*"
    const prefix = keyPattern.replace('*', '');
    for (const key of Object.keys(config)) {
      if (key.startsWith(prefix)) {
        delete config[key];
        modified = true;
      }
    }
  } else {
    // Direct key
    if (config[keyPattern] !== undefined) {
      delete config[keyPattern];
      modified = true;
    }
  }
  
  return modified;
};
```

### Solution File Updates
```typescript
const updateSolutionFile = async (plan: FeatureRemovalPlan): Promise<void> => {
  const solutionFiles = await findFiles('*.sln');
  
  for (const solutionFile of solutionFiles) {
    let content = await readFile(solutionFile);
    let modified = false;
    
    for (const projectToRemove of plan.projectsToRemove) {
      // Remove project entries from solution
      const projectRegex = new RegExp(
        `Project\\([^)]+\\)\\s*=\\s*"[^"]*",\\s*"[^"]*${escapeRegex(projectToRemove)}[^"]*",\\s*"[^"]*"[^}]*EndProject\\s*`,
        'gm'
      );
      
      if (projectRegex.test(content)) {
        content = content.replace(projectRegex, '');
        modified = true;
      }
    }
    
    if (modified) {
      await writeFile(solutionFile, content);
    }
  }
};
```

## Implementation Guidelines

### Extension Integration
```typescript
// Extend the main clone and rename command
const cloneAndRenameWithFeatureSelection = async () => {
  try {
    // Step 1: Detect template
    const templateDetected = await detectBFBTemplate();
    if (!templateDetected) {
      vscode.window.showErrorMessage("No BFB AWSS3Light found in current workspace");
      return;
    }
    
    // Step 2: Get solution name
    const solutionName = await getSolutionName();
    if (!solutionName) return;
    
    // Step 3: Feature selection (NEW)
    const selectedFeatures = await showFeatureSelectionDialog();
    if (!selectedFeatures) return;
    
    // Step 4: Create removal plan
    const removalPlan = createRemovalPlan(selectedFeatures);
    
    // Step 5: Execute with progress tracking
    await vscode.window.withProgress({
      location: vscode.ProgressLocation.Notification,
      title: "Cloning and customizing BFB AWSS3Light",
      cancellable: false
    }, async (progress) => {
      // CRITICAL: Feature removal MUST happen BEFORE renaming (25% of progress)
      // This prevents wasting time renaming files that will be deleted
      await executeFeatureRemoval(removalPlan, progress, 0, 25);
      
      // Standard clone and rename after feature removal (75% of progress)
      await executeStandardCloneAndRename(solutionName, progress, 25, 100);
    });
    
    vscode.window.showInformationMessage(
      `Successfully created ${solutionName} solution with selected features!`
    );
    
  } catch (error) {
    vscode.window.showErrorMessage(`Error: ${error.message}`);
  }
};
```

### Progress Tracking
```typescript
const executeFeatureRemoval = async (
  plan: FeatureRemovalPlan, 
  progress: vscode.Progress<{message?: string; increment?: number}>,
  startPercent: number,
  endPercent: number
): Promise<void> => {
  const totalSteps = 6;
  const incrementPerStep = (endPercent - startPercent) / totalSteps;
  
  // IMPORTANT: This runs BEFORE renaming to avoid processing files that will be deleted
  
  // Step 1: Remove project files and folders
  progress.report({ 
    message: "Removing unnecessary project files...", 
    increment: incrementPerStep 
  });
  await removeProjects(plan);
  
  // Step 2: Clean up project references
  progress.report({ 
    message: "Cleaning up project references...", 
    increment: incrementPerStep 
  });
  await removeProjectReferences(plan);
  
  // Step 3: Clean up using statements
  progress.report({ 
    message: "Removing unused using statements...", 
    increment: incrementPerStep 
  });
  await cleanupUsingStatements(plan);
  
  // Step 4: Clean up service registrations
  progress.report({ 
    message: "Removing service registrations...", 
    increment: incrementPerStep 
  });
  await cleanupServiceRegistrations(plan);
  
  // Step 5: Update configuration files
  progress.report({ 
    message: "Cleaning up configuration files...", 
    increment: incrementPerStep 
  });
  await cleanupConfiguration(plan);
  
  // Step 6: Update solution file
  progress.report({ 
    message: "Updating solution file...", 
    increment: incrementPerStep 
  });
  await updateSolutionFile(plan);
  
  // After this completes, the standard rename process will run on the cleaned solution
};
```

### Error Handling and Rollback
```typescript
interface RemovalState {
  removedFiles: string[];
  modifiedFiles: { path: string; originalContent: string }[];
  removedProjects: string[];
}

const executeFeatureRemovalWithRollback = async (plan: FeatureRemovalPlan): Promise<void> => {
  const state: RemovalState = {
    removedFiles: [],
    modifiedFiles: [],
    removedProjects: []
  };
  
  try {
    // Execute removal with state tracking
    await executeFeatureRemovalTracked(plan, state);
  } catch (error) {
    // Rollback on error
    await rollbackFeatureRemoval(state);
    throw error;
  }
};

const rollbackFeatureRemoval = async (state: RemovalState): Promise<void> => {
  // Restore modified files
  for (const modifiedFile of state.modifiedFiles) {
    await writeFile(modifiedFile.path, modifiedFile.originalContent);
  }
  
  // Note: Cannot restore removed files/folders without backup
  // This is why validation is crucial before removal
  
  vscode.window.showWarningMessage(
    "Feature removal failed and was partially rolled back. Some files may need manual restoration."
  );
};
```

## Testing Requirements

### Unit Tests for Feature Logic
```typescript
describe('Feature Selection Logic', () => {
  test('should create valid removal plan', () => {
    const selectedFeatures = ['dataaccess-sqlserver', 'cache-redis'];
    const plan = createRemovalPlan(selectedFeatures);
    
    expect(plan.featuresToRemove).toContain('dataaccess-mongodb');
    expect(plan.featuresToRemove).toContain('messaging-kafka');
    expect(plan.projectsToRemove).toContain('BFB.AWSS3Light.DataAccess.MongoDB');
  });
  
  test('should validate minimum feature requirements', () => {
    const result = validateFeatureSelection([]);
    expect(result.isValid).toBe(false);
    expect(result.message).toContain('at least one data access');
  });
  
  test('should handle feature dependencies correctly', () => {
    // Test dependency validation logic
  });
});
```

### Integration Tests
```typescript
describe('Feature Removal Integration', () => {
  test('should remove project and all references', async () => {
    // Create test solution with known structure
    const testWorkspace = await createTestWorkspace();
    
    // Execute removal
    const plan = createRemovalPlan(['dataaccess-sqlserver']);
    await executeFeatureRemoval(plan);
    
    // Verify removal
    expect(await fileExists('src/BFB.AWSS3Light.DataAccess.MongoDB')).toBe(false);
    expect(await projectReferencesExist('BFB.AWSS3Light.DataAccess.MongoDB')).toBe(false);
  });
});
```

### Manual Testing Scenarios
```markdown
## Manual Testing Checklist

### Basic Feature Removal
1. ✅ Clone template with only SQL Server data access
2. ✅ Verify MongoDB project is completely removed
3. ✅ Verify no references to MongoDB remain in any file
4. ✅ Verify solution builds successfully
5. ✅ Verify Docker Compose files for unused services are removed

### Complex Feature Combinations
1. ✅ Test with minimal features (only SQL Server)
2. ✅ Test with maximum features (all selected)
3. ✅ Test various combinations of data access providers
4. ✅ Test combinations with and without caching/messaging

### Error Scenarios
1. ✅ Test with invalid feature selections
2. ✅ Test cancellation during removal process
3. ✅ Test with corrupted project files
4. ✅ Test rollback functionality

### Validation Tests
1. ✅ Verify all removed projects are gone from file system
2. ✅ Verify solution file contains only selected projects
3. ✅ Verify no broken project references remain
4. ✅ Verify configuration files are cleaned appropriately
5. ✅ Verify using statements are cleaned up
6. ✅ Verify service registrations are removed
```

## Summary

This feature selection extension provides users with fine-grained control over which technologies and capabilities to include in their customized BFB AWSS3Light solution. The implementation ensures:

- **🚨 CRITICAL: Proper Execution Order**: Feature removal happens BEFORE renaming to avoid processing files that will be deleted
- **Clean Removal**: Complete elimination of unwanted features and all their references
- **Consistent Solution**: Resulting solution builds and functions correctly with only selected features
- **User-Friendly**: Intuitive interface for feature selection with validation and guidance
- **Maintainable**: Well-structured code that can be extended for additional features
- **Reliable**: Comprehensive error handling and validation to prevent broken solutions
- **Efficient**: Optimized process flow that avoids unnecessary work on files that will be removed

### Key Implementation Points:
1. **Feature removal executes first** (0-25% progress) - removes unwanted projects and cleans references
2. **Standard rename process follows** (25-100% progress) - transforms remaining files to new solution name
3. **No wasted effort** - only files that will remain in the final solution are renamed
4. **Clean references** - no broken dependencies from removed features affect the rename process

The extension transforms the BFB AWSS3Light from a comprehensive but potentially overwhelming starting point into a focused, customized foundation that includes only the technologies the user actually needs for their specific project.
