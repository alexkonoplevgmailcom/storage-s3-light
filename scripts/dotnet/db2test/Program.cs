using System.Globalization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using BFB.AWSS3Light.DataAccess.DB2;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Entities;

namespace DB2TestApp;

/// <summary>
/// Simple console application to test DB2 connectivity using BFB.AWSS3Light.DataAccess.DB2 project
/// </summary>
class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("=== BFB AWSS3Light DB2 Connectivity Test ===");
        Console.WriteLine();

        try
        {
            // CRITICAL: Set culture for DB2 compatibility
            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
            CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

            // Build configuration
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .Build();

            // Setup dependency injection
            var services = new ServiceCollection();
            
            // Add logging
            services.AddLogging(builder =>
            {
                builder.AddConfiguration(configuration.GetSection("Logging"));
                builder.AddConsole();
            });

            // Add DB2 services
            services.AddDB2DataAccess(configuration);
            services.AddDB2HealthCheck();

            // Build service provider
            var serviceProvider = services.BuildServiceProvider();

            // Get logger
            var logger = serviceProvider.GetRequiredService<ILogger<Program>>();

            logger.LogInformation("Starting DB2 connectivity test...");

            // Test DB2 Health Check
            await TestDB2HealthCheck(serviceProvider, logger);

            // Test DB2 Repository Operations
            await TestDB2Repository(serviceProvider, logger);

            Console.WriteLine();
            Console.WriteLine("=== DB2 Connectivity Test Completed Successfully ===");
        }
        catch (Exception ex)
        {
            Console.WriteLine();
            Console.WriteLine($"❌ DB2 Test Failed: {ex.Message}");
            Console.WriteLine($"Stack Trace: {ex.StackTrace}");
            Environment.Exit(1);
        }
    }

    /// <summary>
    /// Test DB2 Health Check functionality
    /// </summary>
    private static async Task TestDB2HealthCheck(ServiceProvider serviceProvider, ILogger logger)
    {
        Console.WriteLine("🔍 Testing DB2 Health Check...");
        
        try
        {
            // Get health check from DI container
            var healthCheck = serviceProvider.GetService<BFB.AWSS3Light.DataAccess.DB2.HealthChecks.DB2HealthCheck>();
            
            if (healthCheck != null)
            {
                // Perform health check
                var healthCheckContext = new Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckContext();
                var result = await healthCheck.CheckHealthAsync(healthCheckContext);
                
                if (result.Status == Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Healthy)
                {
                    Console.WriteLine("✅ DB2 Health Check: PASSED");
                    logger.LogInformation("DB2 health check passed successfully");
                }
                else
                {
                    Console.WriteLine($"❌ DB2 Health Check: FAILED - {result.Description}");
                    logger.LogError("DB2 health check failed: {Description}", result.Description);
                }
            }
            else
            {
                Console.WriteLine("⚠️ DB2 Health Check: Not available (service not registered)");
                logger.LogWarning("DB2 health check service not found in DI container");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ DB2 Health Check Exception: {ex.Message}");
            logger.LogError(ex, "Exception during DB2 health check");
            throw;
        }
    }

    /// <summary>
    /// Test DB2 Repository operations
    /// </summary>
    private static async Task TestDB2Repository(ServiceProvider serviceProvider, ILogger logger)
    {
        Console.WriteLine("🔍 Testing DB2 Repository Operations...");
        
        try
        {
            // Get bank repository from DI container
            var bankRepository = serviceProvider.GetService<IBankRepository>();
            
            if (bankRepository != null)
            {
                Console.WriteLine("✅ DB2 Bank Repository: Successfully resolved from DI");
                logger.LogInformation("DB2 Bank Repository successfully resolved from dependency injection");

                // Test repository connection and data retrieval using GetOrdinal implementation
                try
                {
                    // Test 1: Get all banks to verify GetOrdinal works with multiple records
                    Console.WriteLine("  📋 Testing GetAllBanksAsync (GetOrdinal implementation)...");
                    var allBanks = await bankRepository.GetAllBanksAsync();
                    var banksList = allBanks.ToList();
                    Console.WriteLine($"     ✅ Retrieved {banksList.Count} banks using GetOrdinal");
                    
                    // Test 2: Get active banks
                    Console.WriteLine("  📋 Testing GetActiveBanksAsync (GetOrdinal implementation)...");
                    var activeBanks = await bankRepository.GetActiveBanksAsync();
                    var activeBanksList = activeBanks.ToList();
                    Console.WriteLine($"     ✅ Retrieved {activeBanksList.Count} active banks using GetOrdinal");
                    
                    // Test 3: Get by bank code if we have data
                    if (banksList.Count > 0)
                    {
                        var testBank = banksList.First();
                        Console.WriteLine($"  📋 Testing GetByBankCodeAsync with code '{testBank.BankCode}'...");
                        var retrievedBank = await bankRepository.GetByBankCodeAsync(testBank.BankCode);
                        
                        if (retrievedBank != null)
                        {
                            Console.WriteLine($"     ✅ Retrieved: {retrievedBank.Name} (Active: {retrievedBank.IsActive})");
                        }
                    }
                    
                    // Test 4: Test connection with non-existent bank (should return null gracefully)
                    var testBankId = Guid.NewGuid();
                    var nonExistentBank = await bankRepository.GetByIdAsync(testBankId);
                    
                    Console.WriteLine("✅ DB2 Repository Connection: SUCCESSFUL");
                    Console.WriteLine($"   💾 Total Banks: {banksList.Count}, Active: {activeBanksList.Count}");
                    Console.WriteLine("   🎯 All GetOrdinal(\"{column_name}\") operations completed successfully!");
                    logger.LogInformation("DB2 repository connection test completed successfully");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ DB2 Repository Connection: FAILED - {ex.Message}");
                    logger.LogError(ex, "DB2 repository connection test failed");
                    throw;
                }
            }
            else
            {
                Console.WriteLine("❌ DB2 Bank Repository: Failed to resolve from DI");
                logger.LogError("Failed to resolve DB2 Bank Repository from dependency injection");
                throw new InvalidOperationException("DB2 Bank Repository not registered in DI container");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ DB2 Repository Test Exception: {ex.Message}");
            logger.LogError(ex, "Exception during DB2 repository test");
            throw;
        }
    }
}
