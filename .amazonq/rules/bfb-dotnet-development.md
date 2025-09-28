# BFB AWSS3Light .NET Development Rules for Amazon Q Developer

## MANDATORY REQUIREMENTS

### .NET Version Requirement
**MANDATORY**: All new solutions, projects, and code generation MUST use .NET 8
- **Target Framework**: `net8.0` for all new projects
- **SDK Version**: Use .NET 8 SDK for all dotnet commands and project creation
- **Package Versions**: Use .NET 8 compatible package versions for all NuGet dependencies

### Reference Implementation
**CRITICAL**: Always use the reference implementation from the authoritative source for patterns, structure, and implementation details:
- **Repository**: https://github.com/fibi-poc-dev/bfb-template-ng.git
- **Requirement**: Always check this repository for existing code patterns, implementations, and architecture before generating new code
- **Priority**: If code exists in the reference repository, use it as the authoritative source for patterns, structure, and implementation details
- **Adaptation**: Adapt the reference code to the specific solution name using the `BFB.{SolutionName}.*` naming pattern

### Additional Reference Documents
- **DB2 Database Initialization Instructions** - Comprehensive guide for IBM DB2 database setup, Docker configuration, connection management, and troubleshooting. Includes package requirements, connection strings, culture configuration, and production best practices.

## Open Source & Licensing Requirements (MANDATORY)

### License Compliance
- **Prohibited Licenses**: GPL, AGPL, LGPL are strictly prohibited
- **Approved Licenses**: MIT, Apache 2.0, BSD, MS-PL, IBM Public License
- **License Compliance**: Document all open source packages and maintain license inventory
- Current packages in use follow approved licenses (Entity Framework Core, MongoDB.Driver, Polly, etc.)

## Security and Authentication (MANDATORY)

### Transaction ID Requirements
- **x-fibi-transaction-id Header**: MANDATORY for all API endpoints except those marked with `[DevelopmentOnly]`
- **Auto-Generation**: In Development environment, automatically generated for Swagger requests
- **Validation**: Returns HTTP 400 if header is missing in non-Development environments
- **Format**: Use 16-character alphanumeric string (e.g., generated via `Guid.NewGuid().ToString("N")[..16]`)
- **Logging**: All HTTP requests/responses must include transaction ID for correlation

### JWT Token Requirements
- **JWT Generation**: Use `IJwtGenerationService` for creating tokens with custom claims
- **JWT Validation**: Use `IJwtValidationService` for token validation
- **JWT Modes**: Support None, UseExisting, GenerateFresh, and EnhanceExisting modes
- **Token Enhancement**: Ability to add claims to existing JWT tokens
- **Bearer Format**: Always use "Bearer {token}" format in Authorization header
- **Certificate-based**: Use certificate files for JWT signing and validation

### Authentication Requirements
- **Authentication**: Use Kerberos for production, basic auth for development
- **Data Protection**: Use TLS/HTTPS for all communications
- **API Security**: Implement rate limiting and proper CORS policies
- **Configuration Security**: Never store sensitive information in source control
- Use environment variables or secret management for sensitive values in production

## Architecture & Structure

### Solution Structure (MANDATORY)
Follow this exact structure for all BFB template implementations:

- **BFB.{SolutionName}.Abstractions** - Interfaces, DTOs, entities, and exception definitions
- **BFB.{SolutionName}.BusinessServices** - Business logic implementations
- **BFB.{SolutionName}.DataAccess.*** - Data access modules per database technology
  - **DataAccess.SqlServer** - Microsoft SQL Server using Entity Framework Core
  - **DataAccess.DB2** - IBM DB2 using ADO.NET for performance and compatibility
  - **DataAccess.MongoDB** - MongoDB using native MongoDB.Driver
  - **DataAccess.Oracle** - Oracle using Entity Framework Core
- **BFB.{SolutionName}.Messaging.Kafka** - Confluent Kafka implementation
- **BFB.{SolutionName}.Storage.S3** - Amazon S3 storage implementation
- **BFB.{SolutionName}.Cache.Redis** - Redis cache implementation
- **BFB.{SolutionName}.RemoteAccess.RestApi** - REST API client implementations
- **BFB.{SolutionName}.API** - API layer exposing endpoints

### Technology-Specific Naming Conventions
- Classes are named after the underlying infrastructure (e.g., `MongoCustomerService`, `DB2BankService`)
- Controllers follow the same pattern (e.g., `MongoCustomersController`, `DB2BanksController`)

## Database Technology Requirements (MANDATORY)

### Database-Specific Approach
- **Microsoft SQL Server**: MUST use Entity Framework Core
- **IBM DB2**: MUST use ADO.NET for better performance and platform compatibility
- **MongoDB**: MUST use native MongoDB.Driver (NOT MongoDB.EntityFrameworkCore)
- **Oracle**: MUST use Entity Framework Core

### Repository Pattern Implementation
- Define repository interfaces per aggregate in `BFB.{SolutionName}.Abstractions.Interfaces`
- Implement repository interfaces for each supported database using appropriate data access technology
- Return domain models, not database entities - map within repositories
- Use async/await for all database operations
- Separate domain models (Abstractions.Entities) from database entities (DataAccess projects)

## Resilience Patterns (MANDATORY)

### Modern Polly v8 Implementation
- **ALL external service integrations** must implement resilience patterns
- Use **ResiliencePipeline** for advanced implementations (S3 Storage)
- Use **HTTP Client Integration** for REST API with Polly.Extensions.Http
- Use **Entity Framework Integration** with built-in retry policies
- Configure retry policies, circuit breakers, and timeout handling
- Use structured logging for all resilience events

## Health Checks (MANDATORY)

### Comprehensive Health Monitoring
- **REQUIRED**: Implement health checks for ALL infrastructure components
- **Database Health Checks**: For all database providers (SQL Server, DB2, MongoDB, Oracle)
- **Service Health Checks**: For Redis, Kafka, S3, and REST API services
- Register health checks for all services and map health endpoints
- Health endpoints: `/health` (overall) and `/health/ready` (readiness probe)

## Configuration Management

### Environment-Specific Configuration
- Use environment-specific appsettings files:
  - **appsettings.json** - Base configuration for production environment
  - **appsettings.Development.json** - Development environment overrides
  - **appsettings.Test.json** - Test environment overrides
  - **appsettings.QA.json** - QA environment overrides
- Follow consistent configuration structure across environments
- Use strongly-typed configuration objects with IOptions pattern
- Never store sensitive information in source control
- Use environment variables or secret management for sensitive values in production
- Validate configuration during startup with clear error messages
- Configure appropriate logging levels per environment:
  - Development: Debug level with detailed context
  - Production: Information level with structured JSON format

## Entity Framework Guidelines (MANDATORY)

### Entity Configuration
- Define **domain models** in the Abstractions.Entities namespace
- Define **database entities** separately in each DataAccess project
- Use Data Annotations or Fluent API for database entity configuration
- Implement IEntityTypeConfiguration<T> for complex entity configurations
- Use proper naming conventions for entities, properties, and navigation properties
- Define primary keys, foreign keys, and indexes appropriately
- Use value objects for complex properties when applicable

### DbContext Implementation
- Create separate DbContext classes for each supported relational database (SQL Server, Oracle)
- **NOTE**: MongoDB uses native driver implementation, not Entity Framework
- Inherit from DbContext and implement proper constructor overloads
- Override OnConfiguring method only for development/testing scenarios
- Use OnModelCreating for entity configurations and seeding
- Implement proper DbSet properties for all database entities
- Configure connection strings through dependency injection

### Migration Management
- Use Entity Framework Core migrations for database schema management
- Name migrations descriptively using the format: `YYYYMMDD_DescriptiveName`
- Always review generated migrations before applying
- Use PowerShell scripts for migration automation

### Entity Framework Best Practices
- **ALWAYS register Entity Framework health checks** for production APIs
- **Customize model validation responses** for consistent error handling
- **Separate domain models from database entities** for clean architecture
- **Map between entities within repository implementations**
- **Use async/await for all database operations**
- **Implement proper error handling** with custom exceptions

## MongoDB Guidelines (MANDATORY)

### Package Dependencies
- **REQUIRED**: Use MongoDB.Driver (version 2.28.0 or later)
- **DO NOT USE**: MongoDB.EntityFrameworkCore - use native driver only

### Entity Configuration
- Use BSON attributes for property mapping in MongoDB entities
- Implement proper BSON serialization for complex types
- Use appropriate MongoDB data types and indexes

### Repository Implementation
- Implement repository pattern using MongoDB service
- Map between MongoDB entities and domain models
- Use async/await for all database operations
- Handle MongoDB-specific exceptions (MongoException, MongoConnectionException)

### Connection Configuration
- Use connection strings with proper authentication and database specification
- **Connection String Format**: `mongodb://username:password@host:port/database`
- Configure collections and indexes in initialization scripts

## Messaging Systems (MANDATORY)

### Confluent Kafka Implementation
- Use **Confluent.Kafka** NuGet package for Kafka integration
- Implement in `BFB.{SolutionName}.Messaging.Kafka` project
- Use configuration objects for Kafka settings
- Implement resilience patterns with proper error handling
- Use safe defaults and graceful fallbacks for all Kafka configuration
- Configure bootstrap servers, group IDs, client IDs, security protocols, and topic names

## Cache Systems (MANDATORY)

### Redis Cache Implementation
- Use **StackExchange.Redis** for Redis integration in `BFB.{SolutionName}.Cache.Redis` project
- Implement in-memory metadata tracking alongside Redis operations
- Configure proper connection strings and timeout settings
- Implement health checks for Redis connectivity

## Remote Data Access (MANDATORY)

### REST API Implementation with Polly Integration
- Use **HttpClient** with **IHttpClientFactory** for REST API calls
- Implement in `BFB.{SolutionName}.RemoteAccess.RestApi` project
- Use Polly for resilience patterns with proper HTTP client configuration
- Configure retry policies, circuit breakers, and timeout handling

## Critical S3 Implementation Rule

### S3 IMPLEMENTATION IMMUTABILITY
**🚨 DO NOT MODIFY THE S3 IMPLEMENTATION 🚨**

The `BFB.{SolutionName}.Storage.S3` project is a **REFERENCE STANDARD IMPLEMENTATION**:

#### What You MUST Do:
✅ Copy the entire S3 project from reference repository  
✅ Change only the namespace from `BFB.AWSS3Light.Storage.S3` to `BFB.{SolutionName}.Storage.S3`  
✅ Update project references to match your solution name  
✅ Keep all file names, class names, and implementations identical

#### What You MUST NOT Do:
❌ Never modify any S3 service logic  
❌ Never change configuration classes or validation  
❌ Never modify resilience patterns or health checks  
❌ Never add or remove methods from S3 services

## Development Guidelines

### PowerShell Scripting (Windows)
- Use PowerShell scripting for automation tasks on Windows
- **NEVER use the `&&` operator** - use semicolon `;` for command concatenation
- Use proper error handling with `try/catch` for critical operations
- Use `Push-Location`/`Pop-Location` for directory operations

### API Testing with PowerShell
- **Use PowerShell's `Invoke-WebRequest`** for testing REST APIs, NOT curl commands
- Build and run the API first before testing
- Check prerequisite services (databases) are running
- Use proper PowerShell syntax for HTTP requests

## Critical Lessons Learned (MANDATORY)

### Dependency Injection Best Practices
- **Hosted services cannot directly consume scoped services** - use IServiceScopeFactory pattern
- **Never perform blocking operations in constructors** - use lazy initialization
- **Service registration order**: Configuration → Infrastructure → Business → Health Checks

### Configuration Management Best Practices
- **Always provide fallbacks** for configuration parsing failures
- **Use TryParse with safe defaults** for all enum configurations
- **Validate configuration during startup** with clear error messages

### Background Service Implementation
- **Use IServiceScopeFactory** in background services with proper error handling
- **Add delays to prevent tight error loops** that block the application
- **Handle errors gracefully** and don't crash the application

### Kafka Configuration Best Practices
- **Use safe defaults and graceful fallbacks** for Kafka configuration
- **Configure bootstrap servers, group IDs, and security protocols** properly
- **Include proper topic names and client IDs** in configuration
- **Handle Kafka connection failures gracefully** with circuit breakers

### API Development Best Practices
- **Allow empty strings for optional fields** in validation attributes
- **Use RegEx patterns that include empty string alternative**: `^$|actual_pattern`
- **ASP.NET Core uses PascalCase by default** for JSON serialization
- **PowerShell hashtables must use PascalCase property names**
- **SWIFT codes must be 8-11 characters** - use valid codes in tests
- **Always implement health checks** for production APIs
- **Add XML documentation** to controller methods
- **Customize model validation responses** for consistent error format

## Code Quality Standards

### Clean Code Principles
- Follow SOLID principles in all implementations:
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
- Use camelCase for private fields and PascalCase for properties, methods, and classes
- Add XML documentation comments for public APIs
- Follow existing architectural patterns in the codebase
- Use dependency injection for all services

## Error Handling

### Exception Handling Patterns
- Use custom exception types defined in Abstractions.Exceptions namespace
- Log all exceptions with appropriate severity levels
- Return standardized error responses using ErrorResponse DTO
- Repository implementations must handle database-specific exceptions and map to domain exceptions

## Testing Requirements (MANDATORY)

### API Testing Prerequisites
- **ALWAYS verify database containers are running** before testing
- **Build solution successfully** before running tests
- **Use process cleanup functions** to prevent port conflicts
- **Verify health endpoints** before running API tests

### Common Testing Issues
- **Use PascalCase property names** in PowerShell hashtables (not camelCase)
- **Use valid SWIFT codes** (8-11 characters, e.g., "DEUTDEFF")
- **Use valid enum values** (not 0 for transaction types)
- **Generate unique test data** to avoid conflicts

### Required Test Structure
- Test prerequisites function to verify databases running
- Build solution function to verify build success
- Process cleanup function to prevent port conflicts
- Health endpoints testing function
- CRUD operations testing function
- Test summary function to show results

### API Testing with PowerShell Examples
- **Health Check Testing**: Test overall health and readiness endpoints
- **Bank API Testing (DB2)**: Create bank using PascalCase for C# DTO binding
- **Customer API Testing (MongoDB)**: Create customer with proper customer data structure
- **Transaction Testing**: Test transaction types (1=Deposit, 2=Withdrawal, 3=Transfer, 4=Payment)

### DTO Field Validation
- **Always verify DTO field names** before testing APIs
- Common field mapping issues: Enum values (e.g., TransactionType: 1=Deposit, 2=Withdrawal, 3=Transfer, 4=Payment)
- **Read the DTO definitions** in `Abstractions/DTOs` before creating test data
- **Validate enum values** - using 0 often results in "unsupported type" errors

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
- [ ] **License Compliance**: Ensure all packages use approved licenses (MIT, Apache 2.0, BSD, MS-PL, IBM Public License)
- [ ] **Security Requirements**: Implement proper authentication, TLS/HTTPS, and API security measures
- [ ] **Testing Structure**: Include comprehensive test prerequisites and validation functions

## Code Generation Guidelines (MANDATORY)

### Implementation Requirements
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

## Repository Pattern Implementation Details

### Core Repository Pattern Goals
- **Decouple data source logic from business logic** - Repositories handle all persistence concerns
- **Enable easy substitution of data sources** - Switch between MSSQL, DB2, MongoDB, Oracle through DI configuration
- **Enforce clear boundaries between layers** - Use interfaces to separate concerns
- **Centralize persistence logic** - All data access logic contained within repository implementations

### Repository Interface Design
- **Define repository interface per aggregate** in `BFB.{SolutionName}.Abstractions.Interfaces` namespace
- Repository interfaces should be specific to business aggregates, not database tables
- Use domain models (entities) in repository interfaces, never database-specific types
- Support asynchronous operations for all data access methods

### Repository Implementation Guidelines
- **Group data access logic per data source** - Keep implementations in clearly separated namespaces
- **Focus solely on data retrieval and persistence** - No business logic in repositories
- **Use appropriate data access pattern per database**:
  - **Entity Framework Core DbContext** for SQL Server and Oracle operations
  - **ADO.NET with IDbConnection** for DB2 operations with proper connection management
  - **MongoDB native driver** for document operations
- **Isolate configuration and context setup** in appropriate infrastructure layers

### Domain Model vs Database Entity Separation
- **Domain Models** (in Abstractions.Entities) - Used by business services and repository interfaces
- **Database Entities** (in DataAccess projects) - Technology-specific entities (EF Core entities for SQL Server/Oracle, POCOs for DB2/ADO.NET)
- **Mapping Logic** - Convert between database entities and domain models within repository implementations

## Architecture Guidelines

### Layered Architecture
- **Maintain clear separation between layers**
  - Controllers should not access data access components directly
  - Controllers must only interact with business services
  - Business services coordinate between multiple data access components
  - Data access components should not reference other data access components
- **Use dependency injection** for all component dependencies
  - Register components through ServiceCollectionExtension classes
  - Avoid service locator pattern and static access to services

## Dependency Injection Guidelines

### Service Registration Pattern
- Each module provides extension methods for service registration with proper configuration, repository registration, and health check setup
- Add all data access services (MongoDB, DB2, SQL Server, Oracle)
- Add Redis cache services
- Add all business services
- Add REST API remote access services
- Add Kafka messaging services

Following these patterns will prevent the majority of issues encountered during service creation and ensure robust, maintainable applications.

