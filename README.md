# BFB.AWSS3Light - Banking System with MongoDB and Kafka Integration

Backend For Business (BFB) template demonstrating complete banking system integration with MongoDB for data persistence and Kafka for real-time cash withdrawal processing and ATM management.

## 📚 Documentation

- **[Complete Documentation](docs/)** - Comprehensive project documentation
- **[Architecture Overview](docs/PROJECT_SUMMARY.md)** - Detailed architecture and design patterns
- **[Performance Guide](docs/PERFORMANCE_OPTIMIZATIONS.md)** - .NET 8 performance optimizations
- **[Redis Implementation](docs/REDIS_IMPLEMENTATION_SUCCESS.md)** - Redis cache setup and usage
- **[Test Results](docs/TEST_EXECUTION_SUMMARY.md)** - Comprehensive testing documentation
- **[Setup Instructions](docs/clone.instructions.md)** - Detailed setup and configuration guide

Backend For Business (BFB) template demonstrating complete banking system integration with MongoDB for data persistence and Kafka for real-time cash withdrawal processing and ATM management.

## Architecture Overview

This template follows a layered architecture with clear separation of concerns:

- **BFB.AWSS3Light.Abstractions** - Contains interfaces, DTOs, entities, and exceptions
- **BFB.AWSS3Light.DataAccess.MongoDB** - MongoDB data access implementation using native MongoDB driver
- **BFB.AWSS3Light.DataAccess.DB2** - DB2 data access implementation using Entity Framework Core
- **BFB.AWSS3Light.BusinessServices** - Business logic layer with service implementations
- **BFB.AWSS3Light.Messaging.Kafka** - Kafka messaging integration for cash withdrawal processing
- **BFB.AWSS3Light.API** - REST API layer with health checks and comprehensive endpoints

## Technology Stack

- **.NET 8.0**
- **ASP.NET Core** - Web API framework
- **MongoDB .NET Driver** - Native MongoDB data access implementation
- **Entity Framework Core** - For DB2 data access
- **Confluent Kafka** - Real-time messaging for cash withdrawal processing
- **MongoDB** - Document database
- **DB2** - Relational database
- **Apache Kafka** - Event streaming platform
- **Docker** - For complete development environment

## Project Structure

```
BFB.AWSS3Light.sln
├── src/
│   ├── BFB.AWSS3Light.Abstractions/          # Domain models, interfaces, DTOs, exceptions
│   ├── BFB.AWSS3Light.DataAccess.MongoDB/    # MongoDB data access layer
│   ├── BFB.AWSS3Light.DataAccess.DB2/        # DB2 data access layer
│   ├── BFB.AWSS3Light.BusinessServices/      # Business logic layer
│   ├── BFB.AWSS3Light.Messaging.Kafka/       # Kafka messaging services for cash withdrawal processing
│   └── BFB.AWSS3Light.API/                   # REST API layer
├── docs/                                   # Project documentation
│   ├── README.md                          # Documentation index
│   ├── PROJECT_SUMMARY.md                 # Complete architecture overview
│   ├── PERFORMANCE_OPTIMIZATIONS.md       # .NET 8 performance guide
│   ├── REDIS_IMPLEMENTATION_SUCCESS.md    # Redis implementation guide
│   ├── TEST_EXECUTION_SUMMARY.md          # Testing documentation
│   └── clone.instructions.md              # Detailed setup instructions
├── docker-compose/
│   ├── docker-compose.mongodb.yml              # MongoDB Docker environment
│   ├── docker-compose.db2.yml                  # DB2 Docker environment
│   ├── docker-compose.kafka.yml               # Kafka Docker environment
├── init-mongo.js                          # MongoDB initialization script
├── scripts/                              # Script organization folder
│   ├── powershell/                       # PowerShell scripts
│   │   ├── manage-mongodb.ps1            # MongoDB management script
│   │   ├── manage-db2.ps1                # DB2 management script
│   │   ├── manage-kafka.ps1              # Kafka management script
│   │   └── test-kafka-integration.ps1    # Kafka integration testing script
│   └── bash/                             # Bash scripts
│       └── test-serilog-config.sh        # Serilog configuration test script
```

## Cash Withdrawal Processing Flow

The system implements a real-time cash withdrawal processing flow using Kafka:

1. **ATM Request** → `bank-machine-cash-withdrawal-requests` topic
2. **Cash Withdrawal Service** processes the request and publishes to:
   - `account-balance-change-request` topic (for account updates)
   - `brinks-cash-management` topic (for ATM cash level monitoring)

### Kafka Topics

- `bank-machine-cash-withdrawal-requests` - Incoming withdrawal requests from ATMs
- `account-balance-change-request` - Account balance updates
- `brinks-cash-management` - ATM cash level monitoring and alerts

## Getting Started

### Prerequisites

- .NET 8.0 SDK
- Docker Desktop
- PowerShell (Windows)

### 1. Start MongoDB Environment

```powershell
# Start MongoDB and Mongo Express
.\manage-mongodb.ps1 start

# Check logs
.\scripts\powershell\manage-mongodb.ps1 logs

# Stop when done
.\scripts\powershell\manage-mongodb.ps1 stop
```

This will start:
- **MongoDB** at `mongodb://localhost:27017`
- **Mongo Express** (admin UI) at `http://localhost:8081`

### 2. Build and Run the API

```powershell
# Build the solution
dotnet build

# Run the API
cd src\BFB.AWSS3Light.API
dotnet run
```

The API will be available at:
- **HTTPS**: `https://localhost:7221`
- **HTTP**: `http://localhost:5221`
- **OpenAPI/Swagger**: `https://localhost:7221/swagger`

### 3. Start Kafka Environment (Optional)

For cash withdrawal processing and real-time messaging:

```powershell
# Start Kafka environment
.\manage-kafka.ps1 start

# Check status
.\manage-kafka.ps1 status

# View logs
.\manage-kafka.ps1 logs

# Stop when done
.\manage-kafka.ps1 stop
```

This will start:
- **Kafka** at `localhost:9092`
- **Zookeeper** at `localhost:2181`
- **Kafka UI** at `http://localhost:8080`

## API Endpoints

### MongoDB Customer API (`/api/mongo/mongocustomers`)

#### Customer Management
- `GET /api/mongo/mongocustomers` - Get all active customers
- `GET /api/mongo/mongocustomers/{id}` - Get customer by ID
- `GET /api/mongo/mongocustomers/by-email/{email}` - Get customer by email
- `POST /api/mongo/mongocustomers` - Create new customer
- `PUT /api/mongo/mongocustomers/{id}` - Update customer
- `DELETE /api/mongo/mongocustomers/{id}` - Deactivate customer

#### Transaction Management
- `GET /api/mongo/mongocustomers/{id}/transactions` - Get customer transactions
- `POST /api/mongo/mongocustomers/{id}/transactions` - Process new transaction

### DB2 Banks API (`/api/db2/banks`)

#### Bank Management
- `GET /api/db2/banks` - Get all banks
- `GET /api/db2/banks/{id}` - Get bank by ID
- `POST /api/db2/banks` - Create new bank
- `PUT /api/db2/banks/{id}` - Update bank
- `DELETE /api/db2/banks/{id}` - Delete bank

### Health Checks

- `GET /health` - Detailed health status with database connectivity
- `GET /health/ready` - Simple readiness check

## Kafka Integration

### Cash Withdrawal Processing

The system includes a complete Kafka-based cash withdrawal processing flow:

#### Message Flow
1. **ATM Request** → `bank-machine-cash-withdrawal-requests` topic
2. **Cash Withdrawal Service** processes request and generates:
   - Account balance change → `account-balance-change-request` topic
   - ATM cash management alert → `brinks-cash-management` topic

#### Testing Kafka Integration

```powershell
# Test the complete Kafka integration
.\scripts\powershell\test-kafka-integration.ps1

# Test with verbose output
.\scripts\powershell\test-kafka-integration.ps1 -Verbose

# Skip prerequisite checks
.\scripts\powershell\test-kafka-integration.ps1 -SkipPrerequisites
```

#### Kafka Management Commands

```powershell
# Start Kafka environment
.\manage-kafka.ps1 start

# Check status and topics
.\manage-kafka.ps1 status

# Create topics manually
.\scripts\powershell\manage-kafka.ps1 create-topics

# List all topics
.\scripts\powershell\manage-kafka.ps1 list-topics

# View Kafka logs
.\scripts\powershell\manage-kafka.ps1 logs

# Restart Kafka
.\scripts\powershell\manage-kafka.ps1 restart

# Complete reset (removes all data)
.\scripts\powershell\manage-kafka.ps1 reset

# Stop Kafka
.\scripts\powershell\manage-kafka.ps1 stop
```

#### Kafka Topics Structure

```json
// bank-machine-cash-withdrawal-requests
{
  "requestId": "guid",
  "accountNumber": "string",
  "amount": "decimal",
  "atmId": "string",
  "requestTimestamp": "datetime",
  "customerPin": "string",
  "currencyCode": "string"
}

// account-balance-change-request
{
  "requestId": "guid",
  "accountNumber": "string",
  "amount": "decimal",
  "transactionType": "string",
  "originalRequestId": "guid",
  "requestTimestamp": "datetime",
  "currencyCode": "string",
  "description": "string"
}

// brinks-cash-management
{
  "requestId": "guid",
  "atmId": "string",
  "currentCashLevel": "decimal",
  "withdrawnAmount": "decimal",
  "newCashLevel": "decimal",
  "minimumThreshold": "decimal",
  "timestamp": "datetime",
  "currencyCode": "string",
  "alertLevel": "string",
  "originalRequestId": "guid"
}
```

## Sample API Usage

### Create a Customer

```bash
curl -X POST "https://localhost:7221/api/mongo/mongocustomers" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890",
    "initialBalance": 1000.00
  }'
```

### Process a Transaction

```bash
curl -X POST "https://localhost:7221/api/mongo/mongocustomers/1/transactions" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "amount": 250.00,
    "type": 1,
    "description": "Deposit from bank transfer"
  }'
```

## Domain Models

### Customer
- Unique business ID and email
- Personal information (name, phone)
- Account balance and status
- Creation and update timestamps

### CustomerTransaction
- Links to customer
- Transaction amount and type (Deposit, Withdrawal, Transfer, Payment)
- Status tracking (Pending, Completed, Failed, Cancelled)
- Timestamps for creation and processing

## Data Access Pattern

The template implements the Repository pattern with clear separation between:

- **Domain Models** (in Abstractions.Entities) - Used by business logic
- **Database Entities** (in DataAccess.MongoDB.Entities) - MongoDB-specific entities with BSON attributes
- **Mapping Logic** - Converts between database entities and domain models

### MongoDB Configuration

#### Connection String Format
```
mongodb://username:password@host:port/database
```

#### Configuration in appsettings.json
```json
{
  "ConnectionStrings": {
    "MongoDB": "mongodb://bfbapp:bfbapp123@localhost:27017/BfbTemplate"
  }
}
```

## Business Logic Features

### Customer Service (MongoCustomerService)
- Email uniqueness validation
- Customer status management
- Business rule enforcement

### Transaction Processing
- Balance validation for withdrawals/payments
- Automatic balance updates
- Transaction status management
- Support for all transaction types

## MongoDB Features Demonstrated

### Native MongoDB .NET Driver Integration
- MongoDB native driver configuration
- BSON attribute mapping
- Collection configuration
- Index creation

### Document Structure
```javascript
// customers collection
{
  "_id": ObjectId("..."),
  "id": 1,
  "email": "john.doe@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "balance": NumberDecimal("1000.00"),
  "isActive": true,
  "createdAt": ISODate("..."),
  "updatedAt": ISODate("...")
}
```

## PowerShell Management Scripts

### manage-mongodb.ps1

```powershell
# Start MongoDB environment
.\scripts\powershell\manage-mongodb.ps1 start

# Stop MongoDB environment
.\scripts\powershell\manage-mongodb.ps1 stop

# Restart MongoDB environment
.\scripts\powershell\manage-mongodb.ps1 restart

# View MongoDB logs
.\scripts\powershell\manage-mongodb.ps1 logs

# Clean all data (with confirmation)
.\scripts\powershell\manage-mongodb.ps1 clean
```

## Extending the Template

### Adding New Entities
1. Create domain model in `Abstractions/Entities`
2. Create MongoDB entity in `DataAccess.MongoDB/Entities`
3. Add repository interface in `Abstractions/Interfaces`
4. Implement repository in `DataAccess.MongoDB/Repositories`
5. Add to `MongoDbContext`

### Adding Business Services
1. Create service interface in `Abstractions/Interfaces`
2. Implement service in `BusinessServices`
3. Register in `ServiceCollectionExtensions`

### Adding Controllers
1. Create controller in `API/Controllers`
2. Follow naming convention: `Mongo{Entity}Controller`
3. Use appropriate route prefix: `/api/mongo/[controller]`

## Troubleshooting

### MongoDB Connection Issues
- Ensure Docker is running
- Check MongoDB container status: `docker ps`
- Verify connection string in appsettings.json
- Check MongoDB logs: `.\scripts\powershell\manage-mongodb.ps1 logs`

### Build Issues
- Ensure all NuGet packages are restored: `dotnet restore`
- Clean and rebuild: `dotnet clean; dotnet build`
- Check .NET 8.0 SDK is installed

### MongoDB Driver Issues
- MongoDB native driver requires specific BSON attributes
- Ensure proper mapping between domain models and MongoDB entities
- Check index configuration for unique constraints

## License

This template is provided as-is for educational and development purposes.
