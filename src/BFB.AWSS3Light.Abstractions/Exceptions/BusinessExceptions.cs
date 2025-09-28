namespace BFB.AWSS3Light.Abstractions.Exceptions;

/// <summary>
/// Exception thrown when a customer is not found
/// </summary>
public class CustomerNotFoundException : Exception
{
    public CustomerNotFoundException(Guid customerId) 
        : base($"Customer with ID {customerId} was not found.")
    {
        CustomerId = customerId;
    }

    public CustomerNotFoundException(string email) 
        : base($"Customer with email {email} was not found.")
    {
        Email = email;
    }

    public Guid? CustomerId { get; }
    public string? Email { get; }
}

/// <summary>
/// Exception thrown when trying to create a customer with an email that already exists
/// </summary>
public class CustomerEmailAlreadyExistsException : Exception
{
    public CustomerEmailAlreadyExistsException(string email) 
        : base($"A customer with email {email} already exists.")
    {
        Email = email;
    }

    public string Email { get; }
}

/// <summary>
/// Exception thrown when a customer has insufficient balance for a transaction
/// </summary>
public class InsufficientBalanceException : Exception
{
    public InsufficientBalanceException(Guid customerId, decimal currentBalance, decimal requestedAmount) 
        : base($"Customer {customerId} has insufficient balance. Current: {currentBalance:C}, Requested: {requestedAmount:C}")
    {
        CustomerId = customerId;
        CurrentBalance = currentBalance;
        RequestedAmount = requestedAmount;
    }

    public Guid CustomerId { get; }
    public decimal CurrentBalance { get; }
    public decimal RequestedAmount { get; }
}

/// <summary>
/// Exception thrown when a transaction is not found
/// </summary>
public class TransactionNotFoundException : Exception
{
    public TransactionNotFoundException(Guid transactionId) 
        : base($"Transaction with ID {transactionId} was not found.")
    {
        TransactionId = transactionId;
    }

    public Guid TransactionId { get; }
}

/// <summary>
/// Exception thrown when a bank is not found
/// </summary>
public class BankNotFoundException : Exception
{
    public BankNotFoundException(Guid bankId) 
        : base($"Bank with ID {bankId} was not found.")
    {
        BankId = bankId;
    }

    public BankNotFoundException(string identifier, string identifierType) 
        : base($"Bank with {identifierType} '{identifier}' was not found.")
    {
        Identifier = identifier;
        IdentifierType = identifierType;
    }

    public Guid? BankId { get; }
    public string? Identifier { get; }
    public string? IdentifierType { get; }
}

/// <summary>
/// Exception thrown when trying to create a bank with an existing bank code
/// </summary>
public class BankCodeAlreadyExistsException : Exception
{
    public BankCodeAlreadyExistsException(string bankCode) 
        : base($"Bank with code '{bankCode}' already exists.")
    {
        BankCode = bankCode;
    }

    public string BankCode { get; }
}

/// <summary>
/// Generic exception thrown when a resource is not found
/// </summary>
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message)
    {
    }

    public NotFoundException(string resourceType, string identifier) 
        : base($"{resourceType} with identifier '{identifier}' was not found.")
    {
        ResourceType = resourceType;
        Identifier = identifier;
    }

    public string? ResourceType { get; }
    public string? Identifier { get; }
}

/// <summary>
/// Generic exception thrown when there's a conflict with an existing resource
/// </summary>
public class ConflictException : Exception
{
    public ConflictException(string message) : base(message)
    {
    }

    public ConflictException(string resourceType, string identifier) 
        : base($"{resourceType} with identifier '{identifier}' already exists.")
    {
        ResourceType = resourceType;
        Identifier = identifier;
    }

    public string? ResourceType { get; }
    public string? Identifier { get; }
}

/// <summary>
/// Exception thrown for bad request data
/// </summary>
public class BadRequestException : Exception
{
    public BadRequestException(string message) : base(message)
    {
    }

    public BadRequestException(string field, string errorMessage) 
        : base($"Invalid {field}: {errorMessage}")
    {
        Field = field;
        ErrorMessage = errorMessage;
    }

    public string? Field { get; }
    public string? ErrorMessage { get; }
}

/// <summary>
/// Exception thrown when a database operation fails
/// </summary>
public class DatabaseOperationException : Exception
{
    public DatabaseOperationException(string message) : base(message)
    {
    }

    public DatabaseOperationException(string message, Exception innerException) 
        : base(message, innerException)
    {
    }
}
