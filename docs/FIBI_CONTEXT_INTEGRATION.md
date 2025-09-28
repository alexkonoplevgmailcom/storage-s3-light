# FIBIContext Integration Implementation

## Overview
This document describes the implementation of FIBIContext integration throughout the BFB AWSS3Light .NET solution to enable request-scoped tracking with x-fibi-transaction-id, AuthenticationJWT, and ForwardAccessToken.

## FIBIContext Architecture

### Core Design Principles
1. **Request-Scoped Context**: FIBIContext is registered as `Scoped` in dependency injection
2. **Controller Pattern**: Controllers never expose FIBIContext in public methods, but obtain it from DI internally
3. **Business Services Pattern**: All business services receive FIBIContext via constructor injection
4. **Singleton Services Pattern**: Singleton services (e.g., Redis, Kafka) receive FIBIContext as method parameters
5. **Infrastructure Services Pattern**: Data access and infrastructure services receive FIBIContext via constructor injection

## Implementation Details

### 1. FIBIContext Class
**Location**: `src/BFB.AWSS3Light.Abstractions/Models/FIBIContext.cs`

```csharp
public class FIBIContext
{
    public string TransactionId { get; set; } = Guid.NewGuid().ToString();
    public string AuthenticationJWT { get; set; } = string.Empty;
    public string ForwardAccessToken { get; set; } = string.Empty;
}
```

**Registration**: Added as `Scoped` service in `Program.cs`

### 2. Controller Implementation Pattern
**Example**: `RedisCacheController`

- Controllers inject `IServiceProvider` to get FIBIContext per request
- FIBIContext is obtained inside each action method: `var context = _serviceProvider.GetRequiredService<FIBIContext>()`
- Controllers never expose FIBIContext in public API signatures

### 3. Business Services Implementation Pattern
**Examples**: `MongoCustomerService`, `DB2BankService`, `KafkaCashWithdrawalService`

- FIBIContext is injected via constructor
- Used for logging with `context.TransactionId`
- Passed down to infrastructure services and singleton services

### 4. Singleton Services Implementation Pattern
**Examples**: `RedisCacheService`, `KafkaProducer`

#### Redis Cache Service
- **Interface**: `ICacheService` - All methods require `FIBIContext context` parameter
- **Implementation**: `RedisCacheService` - FIBIContext NOT injected via constructor
- **Usage**: All cache operations log transaction ID and pass context through

#### Kafka Producer Service  
- **Interface**: `IKafkaProducer<TKey, TValue>` - All methods require `FIBIContext context` parameter
- **Implementation**: `KafkaProducer<TKey, TValue>` - FIBIContext NOT injected via constructor
- **Enhancement**: Automatically adds FIBIContext headers to Kafka messages:
  - `x-fibi-transaction-id`
  - `x-fibi-auth-jwt` (if present)
  - `x-fibi-forward-token` (if present)

### 5. Infrastructure Services Implementation Pattern
**Examples**: `MongoCustomerRepository`

- FIBIContext injected via constructor (since repositories are scoped)
- Used for logging and audit trails

## Updated Service Interfaces

### ICacheService Interface
All methods now require `FIBIContext context` parameter:
- `SetAsync(CacheItemRequest request, FIBIContext context)`
- `GetAsync(string key, FIBIContext context)`
- `DeleteAsync(string key, FIBIContext context)`
- etc.

### IKafkaProducer Interface
All methods now require `FIBIContext context` parameter:
- `ProduceAsync(string topic, TKey key, TValue value, FIBIContext context)`
- `ProduceAsync(string topic, TKey key, TValue value, IDictionary<string, string> headers, FIBIContext context)`

## Service Registration Updates

### Scoped Services (Receive FIBIContext via Constructor)
- Business Services: `MongoCustomerService`, `DB2BankService`, etc.
- Repositories: `MongoCustomerRepository`, etc.
- **Changed**: `MongoCustomerService` changed from `Singleton` to `Scoped`

### Singleton Services (Receive FIBIContext as Method Parameters)
- Cache Services: `RedisCacheService` (remains `Singleton`)
- Messaging Services: `KafkaProducer` (remains `Singleton`)
- Storage Services: S3 services (remain `Singleton`)

## Logging Enhancement
All services now include `TransactionId` in log messages:
```csharp
_logger.LogInformation("Operation performed for transaction: {TransactionId}", context.TransactionId);
```

## Message Headers Enhancement
Kafka messages automatically include FIBIContext information in headers for distributed tracing and authentication context propagation.

## Benefits

1. **Request Tracing**: Every operation can be traced through the entire request lifecycle
2. **Authentication Context**: JWT and access tokens are available throughout the request processing
3. **Distributed Tracing**: Context propagates through messaging systems (Kafka)
4. **Audit Logging**: All operations are logged with transaction identifiers
5. **Clean Architecture**: Clear separation between singleton and scoped service patterns

## Usage Examples

### Controller Usage
```csharp
[HttpPost]
public async Task<ActionResult> CreateItem([FromBody] ItemRequest request)
{
    var context = _serviceProvider.GetRequiredService<FIBIContext>();
    await _itemService.CreateItemAsync(request, context);
    return Ok();
}
```

### Business Service Usage
```csharp
public class ItemService
{
    private readonly FIBIContext _context;
    private readonly ICacheService _cacheService;
    
    public ItemService(FIBIContext context, ICacheService cacheService)
    {
        _context = context;
        _cacheService = cacheService;
    }
    
    public async Task CreateItemAsync(ItemRequest request)
    {
        _logger.LogInformation("Creating item for transaction: {TransactionId}", _context.TransactionId);
        await _cacheService.SetAsync(cacheRequest, _context);
    }
}
```

### Singleton Service Usage
```csharp
// In business service
await _kafkaProducer.ProduceAsync("topic", "key", message, _context);
await _cacheService.GetAsync("key", _context);
```

## Testing
The solution builds successfully with no errors, maintaining all existing functionality while adding comprehensive FIBIContext support throughout the application.
