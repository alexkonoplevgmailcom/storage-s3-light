# BFB Template Clone & Rename - VS Code Extension Specification

This document provides comprehensive specifications for developing a VS Code extension that automates the cloning and renaming of the BFB Template solution. The extension should provide a seamless user experience for transforming the template into a custom solution.

## Table of Contents
1. [Extension Overview](#extension-overview)
2. [VS Code Extension Requirements](#vs-code-extension-requirements)
3. [User Interface Specifications](#user-interface-specifications)
4. [File Processing Requirements](#file-processing-requirements)
5. [Validation and Error Handling](#validation-and-error-handling)
6. [Progress Tracking and Feedback](#progress-tracking-and-feedback)
7. [Manual Implementation Reference](#manual-implementation-reference)
8. [Testing Requirements](#testing-requirements)

## Extension Overview

The VS Code extension should automate the complete process of cloning and renaming the BFB Template solution. The extension transforms `BFB.Template.*` patterns throughout the solution to use a user-provided solution name.

### Key Features Required
- **One-click template cloning and renaming**
- **Interactive solution name input with validation**
- **Automatic file and folder renaming**
- **Content replacement in all relevant files**
- **Progress tracking with detailed feedback**
- **Error handling and rollback capabilities**
- **Integration with VS Code workspace management**

### Template Transformation Pattern
- **Source Pattern**: `BFB.Template.*` (e.g., `BFB.Template.Api`, `BFB.Template.DataAccess.SqlServer`)
- **Target Pattern**: `BFB.{UserSolutionName}.*` (e.g., `BFB.Banking.Api`, `BFB.PaymentGateway.DataAccess.SqlServer`)

### Transformation Scope
The extension performs comprehensive transformations across multiple file types:

**Files that are RENAMED:**
- Solution file: `BFB.Template.sln` → `BFB.{SolutionName}.sln`
- Project files: `BFB.Template.*.csproj` → `BFB.{SolutionName}.*.csproj`
- Workspace file: `NewFibiTemplate.code-workspace` → `{SolutionName}.code-workspace`
- Project directories: `src/BFB.Template.*` → `src/BFB.{SolutionName}.*`

**Files with CONTENT UPDATES:**
- `.sln`: Project references and solution metadata
- `.csproj`: Project references and assembly names
- `.cs`: Namespaces, using statements, type references
- `.json`: Configuration values and API references
- `.http`: API endpoint URLs
- `.yml/.yaml`: Service names and configurations
- `.ps1`: Script variables and project references
- `.md`: Documentation and project names

**Files with BOTH renaming and content updates:**
- `.csproj` files: Both the filename and internal content are transformed

## VS Code Extension Requirements

### Extension Metadata
```json
{
  "name": "bfb-template-clone",
  "displayName": "BFB Template Clone & Rename",
  "description": "Automates cloning and renaming of BFB Template solutions",
  "version": "1.0.0",
  "publisher": "bfb-tools",
  "engines": {
    "vscode": "^1.70.0"
  },
  "categories": ["Other"],
  "activationEvents": [
    "onCommand:bfbTemplate.cloneAndRename",
    "workspaceContains:**/BFB.Template.sln"
  ],
  "main": "./out/extension.js"
}
```

### Required VS Code APIs
- **File System API**: `vscode.workspace.fs` for file operations
- **Progress API**: `vscode.window.withProgress` for progress tracking
- **Input API**: `vscode.window.showInputBox` for user input
- **Output API**: `vscode.window.createOutputChannel` for logging
- **Commands API**: `vscode.commands.registerCommand` for command registration
- **Workspace API**: `vscode.workspace.workspaceFolders` for workspace management

### Commands to Implement
```typescript
// Primary command - accessible via Command Palette
"bfbTemplate.cloneAndRename": "BFB Template: Clone and Rename Solution"

// Context menu commands
"bfbTemplate.cloneFromExplorer": "Clone BFB Template Here"
"bfbTemplate.renameCurrentTemplate": "Rename Current BFB Template"
```

## User Interface Specifications

### Input Validation Requirements
```typescript
interface SolutionNameValidation {
  // Required: Valid C# identifier rules
  pattern: /^[A-Za-z_][A-Za-z0-9_]*$/;
  
  // Minimum/Maximum length
  minLength: 3;
  maxLength: 50;
  
  // Reserved words to avoid
  reservedWords: ['Template', 'System', 'Microsoft', 'Object', 'String'];
  
  // Additional validation
  noSpecialChars: true;
  noStartWithNumber: true;
}
```

### User Flow Specification
```typescript
interface UserFlow {
  step1: {
    action: "detectTemplate";
    trigger: "command execution or workspace scan";
    validation: "check for BFB.Template.sln existence";
  };
  
  step2: {
    action: "promptSolutionName";
    ui: "vscode.window.showInputBox";
    validation: "real-time input validation";
    placeholder: "e.g., Banking, PaymentGateway, CustomerService";
  };
  
  step3: {
    action: "confirmOperation";
    ui: "vscode.window.showQuickPick";
    options: ["Clone to New Folder", "Rename Current Template", "Cancel"];
  };
  
  step4: {
    action: "selectDestination";  // Only for clone operation
    ui: "vscode.window.showOpenDialog";
    filter: "folders only";
  };
  
  step5: {
    action: "executeTransformation";
    ui: "vscode.window.withProgress";
    cancellable: true;
  };
}
```

### Progress Indicators
```typescript
interface ProgressSteps {
  "Analyzing template structure": 5;
  "Validating prerequisites": 10;
  "Creating directory structure": 15;
  "Renaming project folders": 25;
  "Updating solution file": 35;
  "Processing project files": 50;
  "Updating source code files": 70;
  "Updating configuration files": 85;
  "Verifying transformation": 95;
  "Finalizing workspace": 100;
}
```

## File Processing Requirements

### Directory Structure Mapping
```typescript
interface DirectoryMapping {
  source: string;
  target: string;
  processContents: boolean;
}

const directoryMappings: DirectoryMapping[] = [
  {
    source: "src/BFB.Template.Abstractions",
    target: "src/BFB.{SolutionName}.Abstractions",
    processContents: true
  },
  {
    source: "src/BFB.Template.API",
    target: "src/BFB.{SolutionName}.API", 
    processContents: true
  },
  {
    source: "src/BFB.Template.BusinessServices",
    target: "src/BFB.{SolutionName}.BusinessServices",
    processContents: true
  },
  {
    source: "src/BFB.Template.DataAccess.SqlServer",
    target: "src/BFB.{SolutionName}.DataAccess.SqlServer",
    processContents: true
  },
  {
    source: "src/BFB.Template.DataAccess.MongoDB",
    target: "src/BFB.{SolutionName}.DataAccess.MongoDB",
    processContents: true
  },
  {
    source: "src/BFB.Template.DataAccess.DB2",
    target: "src/BFB.{SolutionName}.DataAccess.DB2",
    processContents: true
  },
  {
    source: "src/BFB.Template.DataAccess.Oracle",
    target: "src/BFB.{SolutionName}.DataAccess.Oracle",
    processContents: true
  },
  {
    source: "src/BFB.Template.Messaging.Kafka",
    target: "src/BFB.{SolutionName}.Messaging.Kafka",
    processContents: true
  },
  {
    source: "src/BFB.Template.Storage.S3",
    target: "src/BFB.{SolutionName}.Storage.S3",
    processContents: true
  },
  {
    source: "src/BFB.Template.RemoteAccess.RestApi",
    target: "src/BFB.{SolutionName}.RemoteAccess.RestApi",
    processContents: true
  },
  {
    source: "src/BFB.Template.Cache.Redis",
    target: "src/BFB.{SolutionName}.Cache.Redis",
    processContents: true
  }
];
```

### File Processing Specifications
```typescript
interface FileProcessingRule {
  filePattern: string;
  action: "rename" | "updateContent" | "both";
  contentReplacements: ReplacementRule[];
}

interface ReplacementRule {
  pattern: RegExp;
  replacement: string;
  description: string;
}

const fileProcessingRules: FileProcessingRule[] = [
  {
    filePattern: "**/*.sln",
    action: "both",
    contentReplacements: [
      {
        pattern: /BFB\.Template/g,
        replacement: "BFB.{SolutionName}",
        description: "Solution project references"
      }
    ]
  },
  {
    filePattern: "**/*.csproj",
    action: "both",  // Both rename file and update content
    contentReplacements: [
      {
        pattern: /BFB\.Template\./g,
        replacement: "BFB.{SolutionName}.",
        description: "Project references"
      }
    ]
  },
  {
    filePattern: "**/*.cs",
    action: "updateContent", 
    contentReplacements: [
      {
        pattern: /namespace BFB\.Template\./g,
        replacement: "namespace BFB.{SolutionName}.",
        description: "C# namespaces"
      },
      {
        pattern: /using BFB\.Template\./g,
        replacement: "using BFB.{SolutionName}.",
        description: "C# using statements"
      },
      {
        pattern: /BFB\.Template\./g,
        replacement: "BFB.{SolutionName}.",
        description: "Type references"
      }
    ]
  },
  {
    filePattern: "**/*.json",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /"BFB\.Template\./g,
        replacement: "\"BFB.{SolutionName}.",
        description: "JSON configuration values"
      },
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "Template references in config"
      }
    ]
  },
  {
    filePattern: "**/*.http",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "HTTP test file references"
      }
    ]
  },
  {
    filePattern: "**/*.ps1",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "PowerShell script references"
      }
    ]
  },
  {
    filePattern: "**/*.yml",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "Docker compose references"
      }
    ]
  },
  {
    filePattern: "**/*.md",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "Documentation references"
      },
      {
        pattern: /NewFibiTemplate/g,
        replacement: "{SolutionName}",
        description: "Workspace name references"
      }
    ]
  },
  {
    filePattern: "**/*.code-workspace",
    action: "both",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "Workspace configuration"
      },
      {
        pattern: /NewFibiTemplate/g,
        replacement: "{SolutionName}",
        description: "Workspace name"
      }
    ]
  },
  {
    filePattern: "**/*.js",
    action: "updateContent",
    contentReplacements: [
      {
        pattern: /Template/g,
        replacement: "{SolutionName}",
        description: "JavaScript references"
      }
    ]
  }
];
```

### Special File Handling
```typescript
interface SpecialFileRule {
  filename: string;
  action: "rename" | "skip" | "special";
  customHandler?: string;
}

const specialFiles: SpecialFileRule[] = [
  {
    filename: "BFB.Template.sln",
    action: "rename",
  },
  {
    filename: "NewFibiTemplate.code-workspace", 
    action: "rename"
  },
  // Project files that need renaming
  {
    filename: "BFB.Template.Abstractions.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.API.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.BusinessServices.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.DataAccess.SqlServer.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.DataAccess.MongoDB.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.DataAccess.DB2.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.DataAccess.Oracle.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.Messaging.Kafka.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.Storage.S3.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.RemoteAccess.RestApi.csproj",
    action: "rename"
  },
  {
    filename: "BFB.Template.Cache.Redis.csproj",
    action: "rename"
  },
  {
    filename: "clone.instructions.md",
    action: "skip"  // Don't modify this instructions file
  },
  {
    filename: "README.md",
    action: "special",
    customHandler: "updateReadmeWithSolutionDetails"
  }
];
```

## Validation and Error Handling

### Pre-Operation Validation
```typescript
interface ValidationCheck {
  name: string;
  check: () => Promise<boolean>;
  errorMessage: string;
  severity: "error" | "warning";
}

const validationChecks: ValidationCheck[] = [
  {
    name: "templateDetection",
    check: async () => await checkForTemplateStructure(),
    errorMessage: "BFB Template structure not detected in current workspace",
    severity: "error"
  },
  {
    name: "solutionNameValid",
    check: async () => validateSolutionName(userInput),
    errorMessage: "Solution name must be a valid C# identifier",
    severity: "error"
  },
  {
    name: "destinationAvailable",
    check: async () => await checkDestinationPath(),
    errorMessage: "Destination path is not writable or already exists",
    severity: "error"
  },
  {
    name: "gitStatus",
    check: async () => await checkGitStatus(),
    errorMessage: "Working directory has uncommitted changes",
    severity: "warning"
  }
];
```

### Error Recovery and Rollback
```typescript
interface RollbackStrategy {
  onError: "rollback" | "partial" | "continue";
  backupStrategy: "none" | "temporary" | "versioned";
  cleanupOnCancel: boolean;
}

const errorHandling: RollbackStrategy = {
  onError: "rollback",
  backupStrategy: "temporary",
  cleanupOnCancel: true
};
```

### Error Message Templates
```typescript
const errorMessages = {
  INVALID_SOLUTION_NAME: "Solution name '{name}' is not valid. Must be a valid C# identifier (letters, numbers, underscore, no spaces).",
  TEMPLATE_NOT_FOUND: "BFB Template structure not found. Please open a workspace containing BFB.Template.sln.",
  DESTINATION_EXISTS: "Destination folder '{path}' already exists. Choose a different location or remove existing folder.",
  INSUFFICIENT_PERMISSIONS: "Insufficient permissions to write to '{path}'. Please check folder permissions.",
  OPERATION_CANCELLED: "Clone and rename operation was cancelled by user.",
  PARTIAL_COMPLETION: "Operation completed with {successCount} successes and {errorCount} errors. Check output panel for details."
};
```

## Progress Tracking and Feedback

### Progress Implementation
```typescript
interface ProgressStep {
  message: string;
  percentage: number;
  duration?: number; // estimated duration in ms
}

async function executeWithProgress(steps: ProgressStep[], operation: () => Promise<void>) {
  return vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: "BFB Template Clone & Rename",
    cancellable: true
  }, async (progress, token) => {
    for (const step of steps) {
      if (token.isCancellationRequested) {
        throw new Error("Operation cancelled");
      }
      
      progress.report({ 
        increment: step.percentage, 
        message: step.message 
      });
      
      // Execute step operation
      await executeStep(step);
    }
  });
}
```

### Output Channel Logging
```typescript
const outputChannel = vscode.window.createOutputChannel("BFB Template Tools");

function logOperation(level: "INFO" | "WARN" | "ERROR", message: string, details?: any) {
  const timestamp = new Date().toISOString();
  outputChannel.appendLine(`[${timestamp}] ${level}: ${message}`);
  
  if (details) {
    outputChannel.appendLine(`Details: ${JSON.stringify(details, null, 2)}`);
  }
}
```

### Success Feedback
```typescript
interface CompletionSummary {
  solutionName: string;
  filesProcessed: number;
  directoriesRenamed: number;
  timeElapsed: number;
  location: string;
}

function showCompletionMessage(summary: CompletionSummary) {
  const message = `Successfully created BFB.${summary.solutionName} solution!\n` +
                 `Processed ${summary.filesProcessed} files and renamed ${summary.directoriesRenamed} directories.\n` +
                 `Location: ${summary.location}`;
  
  vscode.window.showInformationMessage(message, "Open Solution", "Show in Explorer")
    .then(selection => {
      if (selection === "Open Solution") {
        // Open new solution in VS Code
      } else if (selection === "Show in Explorer") {
        // Reveal in file explorer
      }
    });
}
```

## Manual Implementation Reference

### Template Detection Algorithm
```typescript
async function detectBfbTemplate(workspaceFolder: vscode.WorkspaceFolder): Promise<boolean> {
  try {
    // Check for solution file
    const solutionFiles = await vscode.workspace.findFiles(
      new vscode.RelativePattern(workspaceFolder, "BFB.Template.sln"),
      null,
      1
    );
    
    if (solutionFiles.length === 0) return false;
    
    // Check for expected project structure
    const expectedProjects = [
      "src/BFB.Template.Abstractions",
      "src/BFB.Template.API", 
      "src/BFB.Template.BusinessServices"
    ];
    
    for (const projectPath of expectedProjects) {
      const projectExists = await vscode.workspace.fs.stat(
        vscode.Uri.joinPath(workspaceFolder.uri, projectPath)
      ).then(() => true, () => false);
      
      if (!projectExists) return false;
    }
    
    return true;
  } catch (error) {
    return false;
  }
}
```

### Solution Name Validation
```typescript
function validateSolutionName(name: string): ValidationResult {
  const result: ValidationResult = { isValid: true, errors: [] };
  
  // Check length
  if (name.length < 3) {
    result.errors.push("Solution name must be at least 3 characters long");
  }
  
  if (name.length > 50) {
    result.errors.push("Solution name must be no more than 50 characters long");
  }
  
  // Check valid C# identifier
  const validIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_]*$/;
  if (!validIdentifierPattern.test(name)) {
    result.errors.push("Solution name must be a valid C# identifier (letters, numbers, underscore only, cannot start with number)");
  }
  
  // Check reserved words
  const reservedWords = ['Template', 'System', 'Microsoft', 'Object', 'String', 'Class', 'Interface'];
  if (reservedWords.includes(name)) {
    result.errors.push(`"${name}" is a reserved word and cannot be used as solution name`);
  }
  
  result.isValid = result.errors.length === 0;
  return result;
}

interface ValidationResult {
  isValid: boolean;
  errors: string[];
}
```

### File Content Replacement Engine
```typescript
async function replaceFileContent(filePath: vscode.Uri, replacements: ReplacementRule[], solutionName: string): Promise<void> {
  try {
    // Read file content
    const content = await vscode.workspace.fs.readFile(filePath);
    let textContent = Buffer.from(content).toString('utf8');
    
    // Apply all replacements
    for (const rule of replacements) {
      const pattern = new RegExp(rule.pattern.source.replace('{SolutionName}', solutionName), rule.pattern.flags);
      const replacement = rule.replacement.replace('{SolutionName}', solutionName);
      textContent = textContent.replace(pattern, replacement);
    }
    
    // Write back to file
    await vscode.workspace.fs.writeFile(filePath, Buffer.from(textContent, 'utf8'));
  } catch (error) {
    throw new Error(`Failed to update file ${filePath.fsPath}: ${error.message}`);
  }
}
```

### Directory Renaming Implementation
```typescript
async function renameDirectories(workspaceFolder: vscode.WorkspaceFolder, solutionName: string): Promise<void> {
  const srcPath = vscode.Uri.joinPath(workspaceFolder.uri, 'src');
  
  try {
    const entries = await vscode.workspace.fs.readDirectory(srcPath);
    
    for (const [name, type] of entries) {
      if (type === vscode.FileType.Directory && name.startsWith('BFB.Template.')) {
        const oldPath = vscode.Uri.joinPath(srcPath, name);
        const newName = name.replace('Template', solutionName);
        const newPath = vscode.Uri.joinPath(srcPath, newName);
        
        await vscode.workspace.fs.rename(oldPath, newPath);
        logOperation("INFO", `Renamed directory: ${name} → ${newName}`);
      }
    }
  } catch (error) {
    throw new Error(`Failed to rename directories: ${error.message}`);
  }
}
```

### Build Verification
```typescript
async function verifyBuild(workspaceFolder: vscode.WorkspaceFolder): Promise<boolean> {
  return new Promise((resolve) => {
    const terminal = vscode.window.createTerminal({
      name: "BFB Template Build Verification",
      cwd: workspaceFolder.uri.fsPath
    });
    
    terminal.sendText("dotnet build --no-restore");
    
    // Note: VS Code doesn't provide direct access to terminal output
    // This would need to be handled through a different mechanism
    // or by using node.js child_process in the extension
    
    setTimeout(() => {
      terminal.dispose();
      resolve(true); // Placeholder - actual implementation would check build result
    }, 30000);
  });
}
```

## Testing Requirements

### Unit Test Specifications
```typescript
describe('BFB Template Clone Extension', () => {
  describe('Template Detection', () => {
    it('should detect valid BFB template structure', async () => {
      // Test template detection logic
    });
    
    it('should reject invalid template structure', async () => {
      // Test negative cases
    });
  });
  
  describe('Solution Name Validation', () => {
    it('should accept valid C# identifiers', () => {
      // Test valid names
    });
    
    it('should reject invalid characters', () => {
      // Test invalid names
    });
    
    it('should reject reserved words', () => {
      // Test reserved word rejection
    });
  });
  
  describe('File Processing', () => {
    it('should replace content in C# files correctly', async () => {
      // Test C# file content replacement
    });
    
    it('should update project references', async () => {
      // Test project file updates
    });
    
    it('should preserve file encoding', async () => {
      // Test encoding preservation
    });
  });
});
```

### Integration Test Scenarios
1. **Complete Clone Operation**: Test full clone and rename process
2. **In-Place Rename**: Test renaming current template
3. **Error Recovery**: Test rollback on failure
4. **Large Solutions**: Test performance with large codebases
5. **Special Characters**: Test handling of various file encodings

### Manual Testing Checklist
- [ ] Extension loads correctly in VS Code
- [ ] Commands appear in Command Palette
- [ ] Template detection works accurately
- [ ] Input validation provides clear feedback
- [ ] Progress indication works smoothly
- [ ] Error messages are helpful
- [ ] Rollback works on cancellation
- [ ] Final solution builds successfully
- [ ] All file types are processed correctly
- [ ] VS Code workspace integration works

---

**Implementation Priority**: 
1. Core template detection and validation
2. Basic file processing engine
3. User interface components
4. Progress tracking and feedback
5. Error handling and rollback
6. Advanced features and optimizations

This specification provides comprehensive requirements for GitHub Copilot to assist in developing a robust VS Code extension for automating BFB Template cloning and renaming operations.

### 1. Clone or Copy the Template

**Option A: Clone from Repository**
```powershell
git clone <repository-url> YourSolutionName
cd YourSolutionName
```

**Option B: Copy Template Directory**
```powershell
Copy-Item -Path "NewFibiTemplate" -Destination "YourSolutionName" -Recurse
cd YourSolutionName
```

### 2. Define Your Solution Name

Choose your solution name (replace `{YourSolutionName}` with your actual name):
```powershell
$solutionName = "YourSolutionName"  # Example: "Banking", "CustomerService", "PaymentGateway"
```

### 3. Rename Directories

Rename all project directories from `BFB.Template.*` to `BFB.{YourSolutionName}.*`:

```powershell
# Navigate to src directory
cd src

# Rename all template directories
$templateDirs = Get-ChildItem -Directory | Where-Object { $_.Name -like "BFB.Template.*" }
foreach ($dir in $templateDirs) {
    $newName = $dir.Name -replace "Template", $solutionName
    Rename-Item -Path $dir.FullName -NewName $newName
    Write-Host "Renamed: $($dir.Name) → $newName" -ForegroundColor Green
}

# Return to root directory
cd ..
```

### 4. Rename Solution File

```powershell
# Rename the solution file
$oldSolutionFile = "BFB.Template.sln"
$newSolutionFile = "BFB.$solutionName.sln"

if (Test-Path $oldSolutionFile) {
    Rename-Item -Path $oldSolutionFile -NewName $newSolutionFile
    Write-Host "Renamed: $oldSolutionFile → $newSolutionFile" -ForegroundColor Green
}
```

### 5. Rename Workspace File

```powershell
# Rename the VS Code workspace file
$oldWorkspaceFile = "NewFibiTemplate.code-workspace"
$newWorkspaceFile = "$solutionName.code-workspace"

if (Test-Path $oldWorkspaceFile) {
    Rename-Item -Path $oldWorkspaceFile -NewName $newWorkspaceFile
    Write-Host "Renamed: $oldWorkspaceFile → $newWorkspaceFile" -ForegroundColor Green
}
```

### 6. Update File Contents

Update all file contents to replace `Template` with your solution name:

#### 6.1 Update Solution File (.sln)
```powershell
$solutionFile = "BFB.$solutionName.sln"
if (Test-Path $solutionFile) {
    $content = Get-Content $solutionFile -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $solutionFile -Value $content -NoNewline
    Write-Host "Updated solution file references" -ForegroundColor Green
}
```

#### 6.2 Update Project Files (.csproj)
```powershell
$projectFiles = Get-ChildItem -Path "src" -Filter "*.csproj" -Recurse
foreach ($file in $projectFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.Name)" -ForegroundColor Green
}
```

#### 6.3 Update C# Source Files (.cs)
```powershell
$csFiles = Get-ChildItem -Path "src" -Filter "*.cs" -Recurse
foreach ($file in $csFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "BFB\.Template\.", "BFB.$solutionName."
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.FullName)" -ForegroundColor Yellow
}
```

#### 6.4 Update Configuration Files
```powershell
# Update appsettings.json files
$configFiles = Get-ChildItem -Path "src" -Filter "appsettings*.json" -Recurse
foreach ($file in $configFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.FullName)" -ForegroundColor Green
}

# Update launch settings
$launchFiles = Get-ChildItem -Path "src" -Filter "launchSettings.json" -Recurse
foreach ($file in $launchFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.FullName)" -ForegroundColor Green
}
```

#### 6.5 Update HTTP Test Files
```powershell
$httpFiles = Get-ChildItem -Path "src" -Filter "*.http" -Recurse
foreach ($file in $httpFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.FullName)" -ForegroundColor Green
}
```

#### 6.6 Update PowerShell Scripts
```powershell
$psFiles = Get-ChildItem -Path "." -Filter "*.ps1"
foreach ($file in $psFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.Name)" -ForegroundColor Green
}
```

#### 6.7 Update Docker Compose Files
```powershell
$dockerFiles = Get-ChildItem -Path "." -Filter "docker-compose*.yml"
foreach ($file in $dockerFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.Name)" -ForegroundColor Green
}
```

#### 6.8 Update Workspace File
```powershell
$workspaceFile = "$solutionName.code-workspace"
if (Test-Path $workspaceFile) {
    $content = Get-Content $workspaceFile -Raw
    $content = $content -replace "Template", $solutionName
    $content = $content -replace "NewFibiTemplate", $solutionName
    Set-Content -Path $workspaceFile -Value $content -NoNewline
    Write-Host "Updated workspace file" -ForegroundColor Green
}
```

#### 6.9 Update Documentation Files
```powershell
$docFiles = Get-ChildItem -Path "." -Filter "*.md"
foreach ($file in $docFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    $content = $content -replace "NewFibiTemplate", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.Name)" -ForegroundColor Green
}
```

#### 6.10 Update JavaScript Files (if any)
```powershell
$jsFiles = Get-ChildItem -Path "." -Filter "*.js" -Recurse
foreach ($file in $jsFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace "Template", $solutionName
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.FullName)" -ForegroundColor Green
}
```

### 7. Clean and Restore Solution

```powershell
# Clean any existing build artifacts
dotnet clean

# Restore NuGet packages
dotnet restore

# Build the solution to verify everything works
dotnet build
```

## Automated Renaming Script

Here's a complete PowerShell script that automates the entire renaming process:

```powershell
# rename-template.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$SolutionName,
    
    [Parameter()]
    [string]$SourcePath = "."
)

Write-Host "=== BFB Template Renaming Script ===" -ForegroundColor Cyan
Write-Host "Renaming Template to: $SolutionName" -ForegroundColor Yellow
Write-Host "Source Path: $SourcePath" -ForegroundColor Yellow

# Change to source directory
Push-Location $SourcePath

try {
    # Step 1: Rename directories
    Write-Host "`n1. Renaming project directories..." -ForegroundColor Cyan
    $templateDirs = Get-ChildItem -Path "src" -Directory | Where-Object { $_.Name -like "BFB.Template.*" }
    foreach ($dir in $templateDirs) {
        $newName = $dir.Name -replace "Template", $SolutionName
        $newPath = Join-Path $dir.Parent.FullName $newName
        Rename-Item -Path $dir.FullName -NewName $newName
        Write-Host "  ✓ $($dir.Name) → $newName" -ForegroundColor Green
    }

    # Step 2: Rename solution file
    Write-Host "`n2. Renaming solution file..." -ForegroundColor Cyan
    $oldSolutionFile = "BFB.Template.sln"
    $newSolutionFile = "BFB.$SolutionName.sln"
    if (Test-Path $oldSolutionFile) {
        Rename-Item -Path $oldSolutionFile -NewName $newSolutionFile
        Write-Host "  ✓ $oldSolutionFile → $newSolutionFile" -ForegroundColor Green
    }

    # Step 3: Rename workspace file
    Write-Host "`n3. Renaming workspace file..." -ForegroundColor Cyan
    $oldWorkspaceFile = "NewFibiTemplate.code-workspace"
    $newWorkspaceFile = "$SolutionName.code-workspace"
    if (Test-Path $oldWorkspaceFile) {
        Rename-Item -Path $oldWorkspaceFile -NewName $newWorkspaceFile
        Write-Host "  ✓ $oldWorkspaceFile → $newWorkspaceFile" -ForegroundColor Green
    }

    # Step 4: Update file contents
    Write-Host "`n4. Updating file contents..." -ForegroundColor Cyan

    # Function to update files
    function Update-FileContent {
        param($FilePath, $FileType)
        
        if (-not (Test-Path $FilePath)) { return }
        
        $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { return }
        
        $originalContent = $content
        
        # Replace namespaces and project references
        $content = $content -replace "BFB\.Template\.", "BFB.$SolutionName."
        $content = $content -replace "Template", $SolutionName
        $content = $content -replace "NewFibiTemplate", $SolutionName
        
        if ($content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -NoNewline
            Write-Host "    ✓ Updated $FileType`: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        }
    }

    # Update solution file
    Update-FileContent "BFB.$SolutionName.sln" "solution file"

    # Rename and update project files
    $projectFiles = Get-ChildItem -Path "src" -Filter "*.csproj" -Recurse
    foreach ($file in $projectFiles) {
        # Update content first
        Update-FileContent $file.FullName "project file"
        
        # Rename the .csproj file if it contains Template
        if ($file.Name -like "*Template*") {
            $newFileName = $file.Name -replace "Template", $SolutionName
            $newPath = Join-Path $file.Directory.FullName $newFileName
            Rename-Item -Path $file.FullName -NewName $newFileName
            Write-Host "    ✓ Renamed project file: $($file.Name) → $newFileName" -ForegroundColor Green
        }
    }

    # Update C# files
    $csFiles = Get-ChildItem -Path "src" -Filter "*.cs" -Recurse
    $totalCs = $csFiles.Count
    $currentCs = 0
    foreach ($file in $csFiles) {
        $currentCs++
        Write-Progress -Activity "Updating C# files" -Status "Processing $($file.Name)" -PercentComplete (($currentCs / $totalCs) * 100)
        Update-FileContent $file.FullName "C# file"
    }
    Write-Progress -Activity "Updating C# files" -Completed

    # Update configuration files
    $configFiles = Get-ChildItem -Path "src" -Filter "*.json" -Recurse
    foreach ($file in $configFiles) {
        Update-FileContent $file.FullName "config file"
    }

    # Update HTTP files
    $httpFiles = Get-ChildItem -Path "src" -Filter "*.http" -Recurse
    foreach ($file in $httpFiles) {
        Update-FileContent $file.FullName "HTTP file"
    }

    # Update PowerShell scripts
    $psFiles = Get-ChildItem -Path "." -Filter "*.ps1"
    foreach ($file in $psFiles) {
        if ($file.Name -ne "rename-template.ps1") {  # Skip this script
            Update-FileContent $file.FullName "PowerShell script"
        }
    }

    # Update Docker files
    $dockerFiles = Get-ChildItem -Path "." -Filter "docker-compose*.yml"
    foreach ($file in $dockerFiles) {
        Update-FileContent $file.FullName "Docker compose file"
    }

    # Update workspace file
    Update-FileContent "$SolutionName.code-workspace" "workspace file"

    # Update documentation
    $docFiles = Get-ChildItem -Path "." -Filter "*.md"
    foreach ($file in $docFiles) {
        if ($file.Name -ne "clone.instructions.md") {  # Skip instructions
            Update-FileContent $file.FullName "documentation file"
        }
    }

    # Update JavaScript files
    $jsFiles = Get-ChildItem -Path "." -Filter "*.js" -Recurse
    foreach ($file in $jsFiles) {
        Update-FileContent $file.FullName "JavaScript file"
    }

    # Step 5: Clean and restore
    Write-Host "`n5. Cleaning and restoring solution..." -ForegroundColor Cyan
    dotnet clean | Out-Null
    Write-Host "  ✓ Cleaned solution" -ForegroundColor Green
    
    dotnet restore
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Restored NuGet packages" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ NuGet restore had warnings/errors" -ForegroundColor Yellow
    }

    # Step 6: Build verification
    Write-Host "`n6. Building solution..." -ForegroundColor Cyan
    dotnet build --no-restore
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Solution built successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Build failed - please check errors above" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n=== Renaming Complete ===" -ForegroundColor Cyan
    Write-Host "✓ Template successfully renamed to: $SolutionName" -ForegroundColor Green
    Write-Host "✓ All files and references updated" -ForegroundColor Green
    Write-Host "✓ Solution builds successfully" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Review the renamed files in your IDE" -ForegroundColor White
    Write-Host "2. Update any custom configurations specific to your project" -ForegroundColor White
    Write-Host "3. Commit the changes to version control" -ForegroundColor White

} finally {
    Pop-Location
}
```

### Usage of Automated Script

```powershell
# Save the script as rename-template.ps1 and run:
.\rename-template.ps1 -SolutionName "YourSolutionName"

# Or specify a different source path:
.\rename-template.ps1 -SolutionName "YourSolutionName" -SourcePath "C:\Path\To\Template"
```

## Manual Verification Steps

After running the automated script, manually verify the following:

### 1. Check Project Structure
```powershell
# Verify all directories are renamed
Get-ChildItem -Path "src" -Directory | Where-Object { $_.Name -like "*Template*" }
# Should return no results
```

### 2. Check Solution File
```powershell
# Verify solution file references
Get-Content "BFB.$solutionName.sln" | Select-String "Template"
# Should return no matches
```

### 3. Check Project References
```powershell
# Check all project files for Template references
Get-ChildItem -Path "src" -Filter "*.csproj" -Recurse | ForEach-Object {
    $templateRefs = Get-Content $_.FullName | Select-String "Template"
    if ($templateRefs) {
        Write-Host "Template references found in: $($_.Name)" -ForegroundColor Red
        $templateRefs
    }
}
```

### 4. Check Namespace Usage
```powershell
# Check C# files for old namespace references
Get-ChildItem -Path "src" -Filter "*.cs" -Recurse | ForEach-Object {
    $templateRefs = Get-Content $_.FullName | Select-String "BFB\.Template\."
    if ($templateRefs) {
        Write-Host "Old namespace references found in: $($_.FullName)" -ForegroundColor Red
        $templateRefs | ForEach-Object { Write-Host "  Line $($_.LineNumber): $($_.Line)" }
    }
}
```

### 5. Test Build and Run
```powershell
# Test the API project
cd "src\BFB.$solutionName.API"
dotnet run
# Verify it starts without errors
```

## Common Issues and Solutions

### Issue 1: Build Errors After Renaming

**Symptoms**: Build fails with "project not found" errors

**Solution**: 
```powershell
# Clean everything and restore
dotnet clean
Remove-Item -Path "src\*\bin" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "src\*\obj" -Recurse -Force -ErrorAction SilentlyContinue
dotnet restore
dotnet build
```

### Issue 2: Namespace Conflicts

**Symptoms**: Compiler errors about duplicate types or missing references

**Solution**: Check for incomplete namespace replacements
```powershell
# Find any remaining Template references in code
Get-ChildItem -Path "src" -Filter "*.cs" -Recurse | Select-String "Template" | Group-Object Filename
```

### Issue 3: Configuration Issues

**Symptoms**: Runtime errors about missing configurations

**Solution**: Update configuration section names in appsettings.json
```json
// Change from:
"BfbTemplate": { ... }
// To:
"Bfb{YourSolutionName}": { ... }
```

### Issue 4: Docker Compose Issues

**Symptoms**: Docker services fail to start

**Solution**: Update service names in docker-compose files
```yaml
# Ensure service names are updated throughout all docker-compose*.yml files
services:
  bfb-yoursolutionname-api:  # Updated from bfb-template-api
```

## Additional Considerations

### Version Control
If using Git, consider:
```powershell
# Initialize new repository
git init
git add .
git commit -m "Initial commit: Renamed from BFB Template to BFB.$solutionName"
```

### IDE Settings
- Update any IDE-specific settings files
- Verify IntelliSense and code completion work correctly
- Check that debugging configurations are updated

### Database Migrations
If using Entity Framework migrations:
```powershell
# You may need to recreate initial migrations with new naming
# Navigate to each DataAccess project and run:
dotnet ef migrations remove
dotnet ef migrations add InitialMigration
```

### Documentation Updates
Update any project-specific documentation to reflect the new solution name and structure.

---

**Note**: Always test the renamed solution thoroughly before deploying to ensure all references have been updated correctly.
