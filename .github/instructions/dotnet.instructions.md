---
applyTo: '**'
---
# GitHub Copilot Instructions for BFB AWSS3Light Project

## MANDATORY REQUIREMENTS FOR COPILOT

### Source Code Template
**CRITICAL**: When creating any new BFB AWSS3Light solution or components, Copilot MUST use the reference implementation from:
- **Repository**: https://github.com/fibi-poc-dev/bfb-template-ng.git
- **Requirement**: Always check this repository for existing code patterns, implementations, and architecture before generating new code
- **Priority**: If code exists in the reference repository, use it as the authoritative source for patterns, structure, and implementation details
- **Adaptation**: Adapt the reference code to the specific solution name using the `BFB.{SolutionName}.*` naming pattern

### .NET Version Requirement
**MANDATORY**: All new solutions, projects, and code generation MUST use .NET 8
- **Target Framework**: `net8.0` for all new projects
- **SDK Version**: Use .NET 8 SDK for all dotnet commands and project creation
- **Package Versions**: Use .NET 8 compatible package versions for all NuGet dependencies
- **Migration**: When updating existing projects, migrate to .NET 8 target framework

## Table of Contents
1. [Additional Reference Documents](#additional-reference-documents)
2. [General Guidelines](#general-guidelines)
3. [Core Development Rules](#core-development-rules)
4. [Banking Application Development Rules](#banking-application-development-rules)
5. [Code Generation Guidelines](#code-generation-guidelines)
6. [CRITICAL LESSONS LEARNED](#critical-lessons-learned---must-follow-to-prevent-common-service-creation-errors)
7. [Service Creation Checklist](#service-creation-checklist-mandatory)

## Additional Reference Documents

### Database-Specific Setup and Configuration

- **[DB2 Database Initialization Instructions](./db2init.instructions.md)** - Comprehensive guide for IBM DB2 database setup, Docker configuration, connection management, and troubleshooting. Includes package requirements, connection strings, culture configuration, and production best practices.

## General Guidelines
Follow these rules when generating code for the Backend For Business (BFB) Template application.
These rules ensure consistency, maintainability, and security across the codebase.

## Core Development Rules

### Architecture & Structure
- Use the provided architecture and development guidelines as a reference
- Follow the solution structure outlined in the rules with BFB.{SolutionName}.* naming pattern
- Use dependency injection for all services and repositories
- Implement the repository and service interfaces as defined in the Abstractions project
- **MANDATORY**: Use Entity Framework Core for relational databases (SQL Server, Oracle)
- **MANDATORY**: Use ADO.NET for IBM DB2 database operations for better performance and platform compatibility
- **MANDATORY**: Use MongoDB native driver (MongoDB.Driver) for MongoDB operations
- **MANDATORY**: Implement resilience patterns using Polly for all external service integrations

**📘 For comprehensive DB2 setup and configuration details, see: [DB2 Database Initialization Instructions](./db2init.instructions.md)**

### Code Quality & Standards
- Adhere to the clean code principles and coding style specified in the rules
- Document all code with XML comments for public APIs
- Use the provided DTOs for data transfer between layers
- Implement error handling and logging as described in the rules
- Use the provided error handling and exception types for consistent error responses
- Follow technology-specific naming conventions (e.g., `DB2BankService`, `MongoCustomerService`)

### Configuration & Environment
- Follow the configuration management guidelines for environment-specific settings
- Use strongly-typed configuration classes with IOptions pattern
- Implement comprehensive health checks for all infrastructure components
- Follow the security guidelines for data protection, API security, and infrastructure security

### External Services & Integration
- Use Polly resilience patterns for all external service calls
- Use the provided ServiceCollectionExtension classes for service registration
- Implement proper retry policies, circuit breakers, and timeout handling
- Use structured logging for all resilience events
- Use appropriate authentication mechanisms (Kerberos for production, basic auth for development)
- Handle service unavailability gracefully with circuit breakers
- Implement structured logging for all external service interactions

### Testing & Development Tools
- Implement integration tests for data access layers
- Use the provided Docker Compose files for testing data access layers
- Use PowerShell scripts for automation tasks on Windows, and Bash scripts for Linux/macOS environments
- Use the specified health check endpoints for service validation
- Use the specified MinIO configuration for S3 storage testing

### Open Source & Licensing
- **Prohibited Licenses**: GPL, AGPL, LGPL are strictly prohibited
- **Approved Licenses**: MIT, Apache 2.0, BSD, MS-PL, IBM Public License
- **License Compliance**: Document all open source packages and maintain license inventory
- Current packages in use follow approved licenses (Entity Framework Core, MongoDB.Driver, Polly, etc.)

### Security and Authentication

#### Transaction ID Requirements (MANDATORY)
- **x-fibi-transaction-id Header**: MANDATORY for all API endpoints except those marked with `[DevelopmentOnly]`
- **Auto-Generation**: In Development environment, automatically generated for Swagger requests
- **Validation**: Returns HTTP 400 if header is missing in non-Development environments
- **Format**: Use 16-character alphanumeric string (e.g., generated via `Guid.NewGuid().ToString("N")[..16]`)
- **Logging**: All HTTP requests/responses must include transaction ID for correlation
- **Middleware**: Use TransactionIdMiddleware to enforce header requirement before FIBIContext middleware

#### JWT Token Requirements (MANDATORY)
- **JWT Generation**: Use `IJwtGenerationService` for creating tokens with custom claims
- **JWT Validation**: Use `IJwtValidationService` for token validation
- **JWT Modes**: Support None, UseExisting, GenerateFresh, and EnhanceExisting modes
- **Token Enhancement**: Ability to add claims to existing JWT tokens
- **Bearer Format**: Always use "Bearer {token}" format in Authorization header
- **Certificate-based**: Use certificate files for JWT signing and validation
- **Swagger Integration**: Include JWT Bearer authorization in Swagger UI

#### General Authentication
- **Authentication**: Use Kerberos for production, basic auth for development
- **Data Protection**: Use TLS/HTTPS for all communications
- **API Security**: Implement rate limiting and proper CORS policies
- **Configuration Security**: Never store sensitive information in source control

## Banking Application Development Rules

Rules for developing the Backend For Business (BFB) application

### Solution Structure
- **BFB.{SolutionName}.Abstractions** - Contains interfaces, DTOs, entities, and exception definitions
  - **Interfaces** - Define contracts for all services and repositories per aggregate
  - **DTOs** - Define data transfer objects for API communication
  - **Entities** - Define domain models for business logic (not database entities)
  - **Exceptions** - Define custom exception types for the application
- **BFB.{SolutionName}.BusinessServices** - Contains business logic implementations
  - Implements service interfaces from Abstractions
  - Uses dependency injection for data access components
  - Works exclusively with domain models, never database entities
  - **Technology-specific class naming**: Classes are named after the underlying infrastructure (e.g., `MongoCustomerService`, `DB2BankService`)
- **BFB.{SolutionName}.DataAccess.*** - Data access modules for supported database technologies
  - **DataAccess.SqlServer** - Microsoft SQL Server implementation using Entity Framework Core
  - **DataAccess.DB2** - IBM DB2 implementation using ADO.NET for better performance and cross-platform compatibility
    - **📋 Detailed setup guide**: [DB2 Database Initialization Instructions](./db2init.instructions.md)
  - **DataAccess.MongoDB** - MongoDB implementation using native MongoDB.Driver
  - **DataAccess.Oracle** - Oracle implementation using Entity Framework Core
  - Each module implements repository interfaces from Abstractions
  - Includes resilience configurations and retry policies
  - Provides ServiceCollectionExtension for DI registration
  - Contains mapping logic between database entities and domain models
- **BFB.{SolutionName}.Messaging.*** - Messaging modules for supported messaging systems
  - **Messaging.Kafka** - Confluent Kafka implementation with resilience patterns
- **BFB.{SolutionName}.Storage.*** - Storage modules for supported storage systems
  - **Storage.S3** - Amazon S3 storage implementation with advanced resilience patterns
- **BFB.{SolutionName}.Cache.*** - Cache modules for supported caching systems
  - **Cache.Redis** - Redis cache implementation with in-memory metadata tracking
- **BFB.{SolutionName}.RemoteAccess.*** - Remote data access modules
  - **RemoteAccess.RestApi** - REST API client implementations with Polly integration
- **BFB.{SolutionName}.API** - API layer exposing endpoints
  - Uses controllers to handle HTTP requests
  - Configures middleware for exception handling and logging
  - Implements comprehensive health checks
  - **Technology-specific class naming**: Controllers are named after the underlying infrastructure (e.g., `MongoCustomersController`, `DB2BanksController`)

### Architecture Guidelines
- **Layered Architecture** - Maintain clear separation between layers
  - Controllers should not access data access components directly
  - Controllers must only interact with business services
  - Business services coordinate between multiple data access components
  - Data access components should not reference other data access components
- **Dependency Injection** - Use DI for all component dependencies
  - Register components through ServiceCollectionExtension classes
  - Avoid service locator pattern and static access to services

### Repository Pattern Implementation

#### Core Repository Pattern Goals
- **Decouple data source logic from business logic** - Repositories handle all persistence concerns
- **Enable easy substitution of data sources** - Switch between MSSQL, DB2, MongoDB, Oracle through DI configuration
- **Enforce clear boundaries between layers** - Use interfaces to separate concerns
- **Centralize persistence logic** - All data access logic contained within repository implementations

#### Repository Interface Design
- **Define repository interface per aggregate** in `BFB.{SolutionName}.Abstractions.Interfaces` namespace
- Repository interfaces should be specific to business aggregates, not database tables
- Use domain models (entities) in repository interfaces, never database-specific types
- Support asynchronous operations for all data access methods

#### Repository Implementation Guidelines
- **Implement repository interfaces for each supported database** using appropriate data access technology
- **Group data access logic per data source** - Keep implementations in clearly separated namespaces:
  - `BFB.{SolutionName}.DataAccess.SqlServer` - Microsoft SQL Server using Entity Framework Core
  - `BFB.{SolutionName}.DataAccess.DB2` - IBM DB2 using ADO.NET for optimal performance
  - `BFB.{SolutionName}.DataAccess.MongoDB` - MongoDB with native driver
  - `BFB.{SolutionName}.DataAccess.Oracle` - Oracle using Entity Framework Core
- **Focus solely on data retrieval and persistence** - No business logic in repositories
- **Return domain models, not database entities** - Map database entities to domain models within repositories
- **Use appropriate data access pattern per database**:
  - **Entity Framework Core DbContext** for SQL Server and Oracle operations
  - **ADO.NET with IDbConnection** for DB2 operations with proper connection management
  - **MongoDB native driver** for document operations
- **Isolate configuration and context setup** in appropriate infrastructure layers

#### Domain Model vs Database Entity Separation
- **Domain Models** (in Abstractions.Entities) - Used by business services and repository interfaces
- **Database Entities** (in DataAccess projects) - Technology-specific entities (EF Core entities for SQL Server/Oracle, POCOs for DB2/ADO.NET)
- **Mapping Logic** - Convert between database entities and domain models within repository implementations

#### Repository Registration and Dependency Injection
- **Use dependency injection** to register appropriate repository implementations at runtime
- **Register based on configuration** - Switch between data sources through configuration
- **Provide ServiceCollectionExtension methods** for each data access module

### Development Guidelines

#### Scripting Preferences
- Use PowerShell scripting where possible for automation tasks on Windows
- PowerShell scripts should be used for:
  - Build and deployment automation
  - Environment setup and configuration
  - Testing and validation
  - Docker container management
  - Entity Framework migrations management
- Bash scripts should only be used when targeting Linux/macOS environments
- All scripts should include proper error handling and documentation
- When writing PowerShell or any other shell command (in case of Windows OS) commands:
  - **NEVER use the `&&` operator** - this is a Bash/Linux convention that doesn't work in PowerShell
  - **ALWAYS use semicolon `;` for command concatenation**
  - For complex operations, use PowerShell's pipeline syntax or script blocks
  - Use proper error handling with `try/catch` for critical operations
  - For command execution in different directories, use `Push-Location`/`Pop-Location` or `-WorkingDirectory` parameter when available

#### Data Access Testing
- Use the provided Docker Compose files to test data access layers independently
- Run tests using PowerShell scripts when on Windows with appropriate execution policy handling
- If execution policy restrictions are encountered, use bypass parameter
- Always test controllers with their specific data access dependencies

#### API Testing Guidelines
- **Use PowerShell's `Invoke-WebRequest`** for testing REST APIs, NOT curl commands
- **Build and run the API first**: Navigate to source directory and run dotnet
- **Check prerequisite services**: Ensure MongoDB/databases are running before testing
- **Use proper PowerShell syntax** for HTTP requests

**✅ CORRECT API Testing Commands**:
- Use Invoke-WebRequest for GET requests
- Use proper JSON conversion for POST requests with body
- Implement proper error handling with try/catch blocks

**❌ AVOID These Common Mistakes**:
- Don't use curl syntax in PowerShell
- Don't use incorrect header syntax
- Don't use bash operators in PowerShell commands

#### DTO Field Validation
- **Always verify DTO field names** before testing APIs
- Common field mapping issues:
  - Enum values (e.g., TransactionType: 1=Deposit, 2=Withdrawal, 3=Transfer, 4=Payment)
- **Read the DTO definitions** in `Abstractions/DTOs` before creating test data
- **Validate enum values** - using 0 often results in "unsupported type" errors

#### API Development Best Practices (Lessons from DB2 Banks Implementation)
**CRITICAL LESSONS LEARNED - MUST FOLLOW TO AVOID COMMON MISTAKES**

##### Validation Attributes Configuration
- **ALWAYS allow empty strings for optional fields** in validation attributes
- **Use RegEx patterns that include empty string alternative**: `^$|actual_pattern`
- **Common validation mistakes to avoid**: Force validation on empty optional fields
- **StringLength configuration for optional fields**: Use MinimumLength = 0 for optional fields

##### JSON Property Naming Conventions
- **ASP.NET Core uses PascalCase by default** for JSON serialization
- **PowerShell hashtables must use PascalCase property names**: Use PascalCase for proper binding to C# DTOs

##### SWIFT Code Validation Requirements
- **SWIFT codes must be 8-11 characters** according to international standards
- **Always use valid SWIFT codes in tests** (e.g., "DEUTDEFF", not "TBEUS33")
- **Test data requirements**: Use valid 8-character SWIFT codes, avoid invalid 7-character codes

##### Health Check Implementation Requirements
- **ALWAYS implement health checks** for production APIs
- **Include database connectivity checks** in health endpoints
- **Required health check configuration**: Register health checks with DbContext and map health endpoints

##### API Documentation Standards
- **ALWAYS add XML documentation** to controller methods
- **Include ProducesResponseType attributes** for Swagger documentation
- **Required documentation pattern**: Include comprehensive XML documentation with response codes

##### Error Response Handling
- **Customize model validation responses** for consistent error format
- **Use structured error responses** for client applications
- **Required validation configuration**: Configure custom validation response format


### Clean Code Principles
- Follow SOLID principles in all implementations
  - Single Responsibility Principle: Each class should have only one reason to change
  - Open/Closed Principle: Open for extension, closed for modification
  - Liskov Substitution Principle: Derived classes must be substitutable for their base classes
  - Interface Segregation Principle: Clients should not depend on methods they do not use
  - Dependency Inversion Principle: Depend on abstractions, not concretions
- Keep methods small and focused on a single task
- Use meaningful names for variables, methods, and classes
- Avoid code duplication (DRY principle)
- Limit method parameters to 3 or fewer when possible
- Write self-documenting code that expresses intent clearly

### Code Style
Follow C# coding conventions and project patterns
- Use camelCase for private fields and PascalCase for properties, methods, and classes
- Add XML documentation comments for public APIs
- Follow existing architectural patterns in the codebase
- Use dependency injection for all services

### Configuration Management
- Use environment-specific appsettings files:
  - **appsettings.json** - Base configuration for production environment
  - **appsettings.Development.json** - Development environment overrides
  - **appsettings.Test.json** - Test environment overrides
  - **appsettings.QA.json** - QA environment overrides
- Follow consistent configuration structure across environments
- Use strongly-typed configuration objects with IOptions pattern
- Never store sensitive information (passwords, API keys) in source control
- Use environment variables or secret management for sensitive values in production
- Configure appropriate logging levels per environment:
  - Development: Debug level with detailed context
  - Production: Information level with structured JSON format

### Error Handling
Guidelines for error handling in the application
- Use custom exception types defined in Abstractions.Exceptions namespace
- Log all exceptions with appropriate severity levels
- Return standardized error responses using ErrorResponse DTO
- Use the global exception handler middleware for API controllers

### Data Access
Rules for data access implementations - **MANDATORY: Database-Specific Approach**
- **RELATIONAL DATABASES**: SQL Server and Oracle MUST use Entity Framework Core; IBM DB2 MUST use ADO.NET
- **DOCUMENT DATABASES**: MongoDB MUST use native MongoDB .NET Driver (MongoDB.Driver)
- **SUPPORTED DATABASES ONLY**:
  - **Microsoft SQL Server** - Microsoft.EntityFrameworkCore.SqlServer
  - **IBM DB2** - ADO.NET with IBM.Data.DB2.Core for better performance and platform compatibility
  - **MongoDB** - MongoDB.Driver (native .NET driver with BSON mapping)
  - **Oracle** - Oracle.EntityFrameworkCore
- Implement repository interfaces from Abstractions.Interfaces using appropriate data access technology
- **For Entity Framework**: Use DbContext for all database operations and follow unit of work pattern
- **For ADO.NET (DB2)**: Use IDbConnection with proper connection management and parameterized queries
- **For MongoDB**: Use IMongoClient/IMongoDatabase/IMongoCollection for database operations
- Use async/await for all database operations
- **Do not return database entities directly to upper layers** - Always map to domain models
- **Avoid embedding business logic in repositories** - Focus solely on data retrieval and persistence

**🔗 For detailed DB2 setup, configuration, and implementation guidelines, see: [DB2 Database Initialization Instructions](./db2init.instructions.md)**

### Entity Framework Guidelines
Comprehensive guidelines for Entity Framework Core implementation for relational databases (SQL Server, Oracle)

#### Entity Configuration
- Define **domain models** in the Abstractions.Entities namespace
- Define **database entities** separately in each DataAccess project
- Use Data Annotations or Fluent API for database entity configuration
- Implement IEntityTypeConfiguration<T> for complex entity configurations
- Use proper naming conventions for entities, properties, and navigation properties
- Define primary keys, foreign keys, and indexes appropriately
- Use value objects for complex properties when applicable

#### DbContext Implementation
- Create separate DbContext classes for each supported relational database (SQL Server, Oracle)
- **NOTE**: MongoDB uses native driver implementation, not Entity Framework
- Inherit from DbContext and implement proper constructor overloads
- Override OnConfiguring method only for development/testing scenarios
- Use OnModelCreating for entity configurations and seeding
- Implement proper DbSet properties for all database entities
- Configure connection strings through dependency injection

#### Migration Management
- Use Entity Framework Core migrations for database schema management
- Name migrations descriptively using the format: `YYYYMMDD_DescriptiveName`
- Always review generated migrations before applying
- Use PowerShell scripts for migration automation

#### Entity Framework Best Practices
**Health Check Integration**
- **ALWAYS register Entity Framework health checks** for production APIs
- **Required health check configuration**: Register health checks with appropriate configuration

**Model Validation Configuration**
- **Customize model validation responses** for consistent error handling
- **Required validation configuration pattern**: Configure model validation for consistent responses

**DB2-Specific Configuration**
- **For DB2 ADO.NET implementation details** including culture configuration, package requirements, and connection string formats, see: [DB2 Database Initialization Instructions](./db2init.instructions.md)

**Entity Mapping Best Practices**
- **Separate domain models from database entities** for clean architecture
- **Map between entities within repository implementations**
- **Use proper navigation properties** for related entities

**Repository Implementation Standards**
- **Use async/await for all database operations**
- **Implement proper error handling** with custom exceptions
- **Map entities to domain models** within repository methods

#### Database Provider Configuration
- **Microsoft SQL Server Configuration**: Configure SQL Server provider
- **IBM DB2 Configuration** (ADO.NET approach): Configure DB2 with ADO.NET
- **MongoDB Configuration** (using native MongoDB.Driver): Configure MongoDB native driver
- **Oracle Configuration**: Configure Oracle provider

#### Connection Resilience
- Configure retry policies for Entity Framework operations

### MongoDB Guidelines  
Comprehensive guidelines for MongoDB native driver implementation (already implemented in codebase)

#### Package Dependencies
- **REQUIRED**: Use MongoDB.Driver (version 2.28.0 or later) - already configured
- **DO NOT USE**: MongoDB.EntityFrameworkCore - this project uses native driver

#### Entity Configuration
Use BSON attributes for property mapping in MongoDB entities with proper attribute configuration.

#### Service Implementation Pattern
Implement MongoDB service pattern with proper service structure.

#### Repository Implementation
- Implement repository pattern using MongoDB service
- Map between MongoDB entities and domain models
- Use async/await for all database operations
- Handle MongoDB-specific exceptions (MongoException, MongoConnectionException)

#### Connection Configuration
- Use connection strings with proper authentication and database specification
- **Connection String Format**: `mongodb://username:password@host:port/database`
- Configure collections and indexes in initialization scripts

### Messaging Systems
Guidelines for supported messaging technologies

#### Confluent Kafka Implementation
- Use **Confluent.Kafka** NuGet package for Kafka integration
- Implement in `BFB.{SolutionName}.Messaging.Kafka` project
- Use configuration objects for Kafka settings
- Implement resilience patterns with proper error handling

### Storage Systems
Guidelines for supported storage technology

#### Amazon S3 Implementation with Advanced Resilience
**CRITICAL**: The S3 implementation must be robust, reusable, and production-ready across ALL BFB template implementations. This implementation should NEVER require changes when creating new BFB templates.

##### S3 Implementation Standards for Maximum Reusability
**MANDATORY REQUIREMENTS - These standards ensure the S3 implementation remains unchanged across different BFB template implementations**:

1. **Configuration Validation with Startup Validation**
2. **Dual Implementation Pattern for Flexibility**
3. **Comprehensive Error Handling and Logging**
4. **Production-Ready Resilience Patterns**
5. **Automatic Bucket Management**
6. **Efficient Metadata Tracking**
7. **Smart Object Key Strategy**
8. **Secure Download Management**
9. **Optional Security Features**
10. **Development Environment Support**
11. **Comprehensive Health Monitoring**

##### Required S3 Project Structure
**MANDATORY**: All BFB template S3 implementations must follow this exact structure:
- Configuration directory with storage and resilience settings
- Services directory with basic and resilient implementations
- Extensions directory with service collection extensions
- Health check extensions implementation
- Main project file

##### S3 Configuration Classes with Built-in Validation
**S3StorageSettings - Production-Ready Configuration**: Includes comprehensive storage configuration with built-in validation.

**S3ResilienceSettings - Advanced Resilience Configuration**: Includes advanced resilience configuration for production environments.

##### Production-Ready Service Registration Pattern
**MANDATORY DI Registration with Configuration Validation**: Includes proper dependency injection registration with configuration validation.

##### Robust Health Check Implementation
**MANDATORY Health Check Pattern for Production Monitoring**: Includes comprehensive health check implementation for production monitoring.

##### Required Package Dependencies
**MANDATORY packages for all BFB template S3 implementations**: Includes all required AWS SDK and Microsoft Extensions packages with specific version requirements.

##### Configuration Template for New BFB AWSS3Lights
**MANDATORY appsettings configuration template**: Includes comprehensive configuration template for S3 settings.

##### Implementation Validation Checklist
**CRITICAL**: Every new BFB template MUST verify these implementation standards:

✅ **Configuration Validation**
- S3StorageSettings.Validate() called on startup
- Clear error messages for missing configuration
- MinIO compatibility automatically detected

✅ **Service Implementation**
- Both basic and resilient services implemented
- Modern Polly v8 ResiliencePipeline used
- Comprehensive error handling with structured logging

✅ **Health Checks**
- S3HealthCheck implemented and registered
- Bucket accessibility verification included
- Health endpoints respond correctly

✅ **Project Structure**
- Follows exact folder/file structure
- All required packages referenced
- ServiceCollectionExtensions properly implemented

✅ **Production Readiness**
- Metadata tracking implemented
- Pre-signed URL support included
- Server-side encryption configurable
- Bucket auto-creation handled

**ENFORCEMENT**: Any BFB template that doesn't follow these exact standards must be updated to comply before release. This ensures consistent, reliable S3 functionality across all implementations.

## CRITICAL WARNING: S3 IMPLEMENTATION IMMUTABILITY

**🚨 DO NOT MODIFY THE S3 IMPLEMENTATION 🚨**

The `BFB.{SolutionName}.Storage.S3` project is a **REFERENCE STANDARD IMPLEMENTATION** that must be copied exactly as-is to new BFB templates:

### What You MUST Do:
✅ **Copy the entire S3 project** from reference repository  
✅ **Change only the namespace** from `BFB.AWSS3Light.Storage.S3` to `BFB.{SolutionName}.Storage.S3`  
✅ **Update project references** to match your solution name  
✅ **Keep all file names, class names, and implementations identical**

### What You MUST NOT Do:
❌ **Never modify any S3 service logic**  
❌ **Never change configuration classes or validation**  
❌ **Never modify resilience patterns or health checks**  
❌ **Never add or remove methods from S3 services**  
❌ **Never change error handling or logging patterns**

### Why This Rule Exists:
- **Production-Tested**: The S3 implementation has been thoroughly tested and proven reliable
- **Maximum Reusability**: Designed to work unchanged across all BFB template scenarios  
- **Consistent Behavior**: Ensures identical S3 functionality in all BFB implementations
- **Zero Maintenance**: Prevents implementation drift and reduces support burden
- **Reference Standard**: Serves as the authoritative S3 implementation for all teams

**VIOLATION CONSEQUENCES**: Any modification to the S3 implementation will require justification and re-approval before deployment.

### Cache Systems
Guidelines for cache implementations

#### Redis Cache Implementation
- Use **StackExchange.Redis** for Redis integration in `BFB.{SolutionName}.Cache.Redis` project
- Implement in-memory metadata tracking alongside Redis operations

### Remote Data Access
Guidelines for remote data access

#### REST API Implementation with Polly Integration
- Use **HttpClient** with **IHttpClientFactory** for REST API calls
- Implement in `BFB.{SolutionName}.RemoteAccess.RestApi` project
- Use Polly for resilience patterns with proper HTTP client configuration

### Resilience Patterns
Comprehensive resilience implementation using Polly

#### Modern Polly v8 Patterns
- **ResiliencePipeline** for S3 Storage (advanced implementation)
- **HTTP Client Integration** for REST API with Polly.Extensions.Http
- **Entity Framework Integration** with built-in retry policies
- **Configuration-driven** resilience settings for all modules

#### Resilience Configuration
Each module must have resilience settings classes with proper configuration for retry attempts, delays, and timeouts.

#### Implementation Requirements
- **All external service integrations** must implement resilience patterns
- **Use structured logging** for resilience events
- **Configure retry policies** appropriate for each service type
- **Implement circuit breakers** to prevent cascade failures
- **Set appropriate timeouts** for all operations

### Health Checks
Comprehensive health monitoring implementation

#### Health Check Implementation
- **REQUIRED**: Implement health checks for all infrastructure components
- **Database Health Checks**: For all database providers (SQL Server, DB2, MongoDB, Oracle)
- **Service Health Checks**: For Redis, Kafka, S3, and REST API services
- **Health Check Registration**: Register health checks for all services and map health endpoints

#### Health Check Endpoints
- `/health` - Overall application health
- `/health/ready` - Readiness probe for orchestrators
- Return appropriate HTTP status codes (200 for healthy, 503 for unhealthy)

### Dependency Injection
Guidelines for service registration using ServiceCollectionExtension pattern

#### Service Registration Pattern
Each module provides extension methods for service registration with proper configuration, repository registration, and health check setup.

#### Comprehensive Service Registration
- Add all data access services (MongoDB, DB2, SQL Server, Oracle)
- Add Redis cache services
- Add all business services
- Add REST API remote access services
- Add Kafka messaging services

### Testing
Comprehensive testing guidelines for the BFB AWSS3Light application

#### API Testing with PowerShell
Use PowerShell's `Invoke-WebRequest` for testing API endpoints:

**Health Check Testing**: Test overall health and readiness endpoints

**Bank API Testing (DB2)**: Create bank using PascalCase for C# DTO binding with proper bank data structure

**Customer API Testing (MongoDB)**: Create customer with proper customer data structure

**Transaction Testing**: Test transaction types (1=Deposit, 2=Withdrawal, 3=Transfer, 4=Payment) with proper transaction data structure

#### Testing Prerequisites
- **ALWAYS verify database containers are running** before testing
- **Build solution successfully** before running tests
- **Use process cleanup functions** to prevent port conflicts
- **Verify health endpoints** before running API tests

#### Common Testing Issues and Solutions
- **Use PascalCase property names** in PowerShell hashtables (not camelCase)
- **Use valid SWIFT codes** (8-11 characters, e.g., "DEUTDEFF")
- **Use valid enum values** (not 0 for transaction types)
- **Generate unique test data** to avoid conflicts
- **Include comprehensive error handling** in test scripts

#### Required Test Structure
- Test prerequisites function to verify databases running
- Build solution function to verify build success
- Process cleanup function to prevent port conflicts
- Health endpoints testing function
- CRUD operations testing function
- Test summary function to show results

## Code Generation Guidelines
- Write only the ABSOLUTE MINIMAL amount of code needed to address the requirement correctly
- Follow existing patterns in the codebase (technology-specific naming, resilience patterns, etc.)
- **MANDATORY**: Use Entity Framework Core for SQL Server and Oracle, ADO.NET for DB2, MongoDB.Driver for MongoDB
- **MANDATORY**: Implement resilience patterns using Polly for all external service integrations
- **MANDATORY**: Include health checks for all infrastructure components
- **Always implement proper mapping** between database entities and domain models in repositories
- **Use technology-specific naming conventions** (e.g., `DB2BankRepository`, `MongoCustomerService`)
- **Follow the established ServiceCollectionExtension pattern** for service registration
- **Include comprehensive error handling** with custom exceptions and structured logging
- **Use strongly-typed configuration** with IOptions pattern for all settings

## CRITICAL LESSONS LEARNED - MUST FOLLOW TO PREVENT COMMON SERVICE CREATION ERRORS

### Dependency Injection Best Practices (MANDATORY)

#### Hosted Services and Scoped Dependencies
**CRITICAL**: Hosted services are registered as singletons and cannot directly consume scoped services

**❌ WRONG - Direct scoped service injection in hosted services**: Don't inject scoped services directly into hosted services

**✅ CORRECT - Use IServiceScopeFactory pattern**: Use IServiceScopeFactory to create scopes within hosted services and resolve scoped dependencies within those scopes

#### Constructor Initialization Anti-Patterns
**CRITICAL**: Never perform blocking operations or external service connections in constructors

**❌ WRONG - Blocking operations in constructor**: Don't perform consumer builds or service subscriptions in constructors

**✅ CORRECT - Lazy initialization pattern**: Store configuration only in constructors, initialize connections only when needed with proper error handling

### Configuration Management Best Practices (MANDATORY)

#### Robust Configuration Parsing
**CRITICAL**: Always provide fallbacks for configuration parsing failures

**❌ WRONG - Direct enum parsing that can fail**: Don't use direct enum parsing without fallbacks

**✅ CORRECT - Safe parsing with fallbacks**: Use TryParse with safe defaults for all enum configurations

#### Configuration Validation
**REQUIRED**: Validate configuration during startup with clear error messages for required settings

### Health Check Implementation Patterns (MANDATORY)

#### Simplified Health Check Registration
**CRITICAL**: Use simplified health check patterns to avoid configuration complexity during startup

**❌ WRONG - Complex health check configuration**: Don't use complex connection string resolution during health check registration

**✅ CORRECT - Simplified health check pattern**: Register health checks with simple patterns and implement custom health check classes with proper error handling

### Database Technology Separation (MANDATORY)

#### MongoDB vs Entity Framework Clear Separation
**CRITICAL**: Never mix Entity Framework patterns with MongoDB native driver patterns

**✅ REQUIRED MongoDB Pattern**: Use BSON attributes for MongoDB entities and IMongoCollection for repositories

**✅ REQUIRED Entity Framework Pattern**: Use Data Annotations or Fluent API for EF entities and DbContext for repositories

### Background Service Implementation (MANDATORY)

#### Proper Background Service Error Handling
**REQUIRED**: Background services must handle errors gracefully and not crash the application

**✅ REQUIRED Pattern**: Use IServiceScopeFactory in background services with proper error handling and cancellation support

#### Background Service Error Resilience
**REQUIRED**: Add delays to prevent tight error loops that block the application with proper delay implementation

### Exception Handling Patterns (MANDATORY)

#### Repository Exception Handling
**REQUIRED**: Repository implementations must handle database-specific exceptions and map to domain exceptions

**✅ REQUIRED Pattern**: Handle DbUpdateException and MongoWriteException with proper exception mapping

#### External Service Exception Handling
**REQUIRED**: External service connections must not throw exceptions during DI registration with proper initialization patterns

### Service Registration Order (MANDATORY)

#### Correct Service Registration Sequence
**CRITICAL**: Services must be registered in the correct order to avoid dependency resolution failures

**✅ REQUIRED Registration Order**: 
1. Configuration first
2. Infrastructure services second  
3. Business services third (depend on infrastructure)
4. Health checks last (after all dependencies are registered)

### Startup Validation (MANDATORY)

#### Application Startup Validation
**REQUIRED**: Validate that the application starts properly and all critical services can be resolved

**✅ REQUIRED Startup Pattern**: Log startup configuration, configure middleware and endpoints, don't validate service resolution during startup

### Kafka Configuration Best Practices (MANDATORY)

#### Safe Kafka Configuration Pattern
**REQUIRED**: Use safe defaults and graceful fallbacks for Kafka configuration with proper bootstrap servers, group IDs, and security protocol configuration

#### Safe appsettings.json Configuration:
Include proper Kafka configuration with bootstrap servers, group IDs, client IDs, security protocols, and topic names

## Service Creation Checklist (MANDATORY)

Before building any new service, ensure:

- [ ] **Dependency Injection**: Use IServiceScopeFactory for hosted services consuming scoped dependencies
- [ ] **Constructor Safety**: No blocking operations or external connections in constructors  
- [ ] **Configuration Validation**: Robust parsing with fallbacks for all configuration values
- [ ] **Health Checks**: Simple, custom health check implementations for all infrastructure
- [ ] **Database Separation**: Clear separation between MongoDB native driver and Entity Framework patterns
- [ ] **Error Handling**: Comprehensive exception handling in all repository implementations
- [ ] **Background Services**: Proper error handling with delays that doesn't crash the application
- [ ] **Service Registration**: Correct order - Configuration → Infrastructure → Business → Health Checks
- [ ] **Startup Validation**: Don't validate service resolution during startup - use lazy initialization
- [ ] **External Services**: Never connect to external services during DI registration (constructors)
- [ ] **Kafka Configuration**: Use safe defaults and graceful fallbacks for all settings

Following these patterns will prevent the majority of issues encountered during service creation and ensure robust, maintainable applications.