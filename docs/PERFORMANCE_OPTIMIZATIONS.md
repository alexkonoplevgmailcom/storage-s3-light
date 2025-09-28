# .NET 8 Performance Optimizations for BFB AWSS3Light

This document outlines the performance optimizations implemented in the BFB AWSS3Light API using .NET 8 features.

## 🚀 Performance Features Enabled

### 1. ReadyToRun (R2R) Compilation
**Location**: `BFB.AWSS3Light.API.csproj`
```xml
<PublishReadyToRun>true</PublishReadyToRun>
<PublishReadyToRunUseCrossgen2>true</PublishReadyToRunUseCrossgen2>
```
- **Benefit**: Pre-JITted assemblies for faster application startup
- **Impact**: Reduces cold start time by up to 30-50%
- **Trade-off**: Larger deployment size but faster startup

### 2. Dynamic Profile Guided Optimization (PGO)
**Location**: `BFB.AWSS3Light.API.csproj`
```xml
<TieredPGO>true</TieredPGO>
```
- **Benefit**: Runtime profile collection improves hot path performance
- **Impact**: Better throughput for frequently executed code paths
- **How it works**: Collects execution profiles and re-optimizes hot code

### 3. Tiered Compilation & OSR
**Location**: `BFB.AWSS3Light.API.csproj`
```xml
<TieredCompilation>true</TieredCompilation>
```
- **Benefit**: Multi-tier JIT optimization with On-Stack Replacement
- **Impact**: Better performance for long-running methods
- **How it works**: Quick Tier 0 JIT, then optimized Tier 1 compilation

### 4. Server Garbage Collection
**Location**: `BFB.AWSS3Light.API.csproj` and `runtimeconfig.template.json`
```xml
<ServerGarbageCollection>true</ServerGarbageCollection>
```
- **Benefit**: Optimized for throughput over latency
- **Impact**: Better memory management under high load
- **Best for**: Server applications with multiple cores

### 5. Assembly Trimming
**Location**: `BFB.AWSS3Light.API.csproj`
```xml
<PublishTrimmed>true</PublishTrimmed>
<TrimMode>partial</TrimMode>
```
- **Benefit**: Removes unused code from assemblies
- **Impact**: Smaller deployment footprint and faster loading
- **Mode**: Partial trimming (safer than full trimming for complex apps)

### 6. Invariant Globalization
**Location**: `BFB.AWSS3Light.API.csproj`
```xml
<InvariantGlobalization>true</InvariantGlobalization>
```
- **Benefit**: Eliminates culture-specific data and operations
- **Impact**: Faster string operations and smaller memory footprint
- **Suitable**: For APIs that don't need localization

## 🌐 Kestrel & HTTP Optimizations

### HTTP Protocol Support
**Location**: `Program.cs`
```csharp
options.ConfigureEndpointDefaults(listenOptions =>
{
    listenOptions.Protocols = HttpProtocols.Http1AndHttp2AndHttp3;
});
```
- **HTTP/2**: Multiplexing, header compression, server push
- **HTTP/3**: QUIC protocol for lower latency connections

### Connection Optimization
```csharp
options.Limits.MaxConcurrentConnections = 1000;
options.Limits.MaxConcurrentUpgradedConnections = 1000;
```
- **Benefit**: Higher concurrent connection handling
- **Impact**: Better performance under high load

### Response Compression
```csharp
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});
```
- **Brotli**: Superior compression ratio for text content
- **Gzip**: Fallback for older clients
- **Impact**: Reduced bandwidth usage and faster transfers

## ⚙️ Runtime Configuration

### Runtime Settings
**Location**: `runtimeconfig.template.json`
```json
{
  "configProperties": {
    "System.GC.Server": true,
    "System.GC.Concurrent": true,
    "System.GC.RetainVM": true,
    "System.Threading.ThreadPool.MinWorkerThreads": 4,
    "System.Threading.ThreadPool.MinCompletionPortThreads": 4
  }
}
```

### Environment Variables for Maximum Performance
**Location**: `Properties/launchSettings.json` (production-optimized profile)
```json
{
  "DOTNET_TieredPGO": "1",
  "DOTNET_TieredCompilation": "1", 
  "DOTNET_ReadyToRun": "1",
  "DOTNET_gcServer": "1",
  "DOTNET_gcConcurrent": "1"
}
```

## 📊 Performance Testing

### Running Performance Tests
Use the provided PowerShell script to test different performance configurations:

```powershell
# Run all performance tests
.\scripts\powershell\test-net8-performance.ps1

# Or run specific tests:
# 1. Build with optimizations
# 2. Test standard development run
# 3. Test optimized production run  
# 4. Test published application with ReadyToRun
# 5. Run all tests
```

### Measuring Performance Impact

1. **Startup Time**: ReadyToRun reduces cold start by 30-50%
2. **Throughput**: PGO improves steady-state performance by 10-20%
3. **Memory**: Server GC optimizes for high-throughput scenarios
4. **Network**: Response compression reduces payload size by 60-80%

## 🚀 Deployment Commands

### Development (with debugging)
```bash
dotnet run --configuration Debug
```

### Production (maximum performance)
```bash
dotnet run --configuration Release --launch-profile production-optimized
```

### Optimized Publish
```bash
dotnet publish --configuration Release --output ./publish
```

## 📈 Expected Performance Improvements

| Metric | Improvement | Description |
|--------|-------------|-------------|
| **Startup Time** | 30-50% faster | ReadyToRun pre-JITted assemblies |
| **Steady-State Throughput** | 10-20% higher | Dynamic PGO optimizations |
| **Memory Usage** | 15-25% reduction | Server GC + trimming |
| **Network Bandwidth** | 60-80% reduction | Brotli/Gzip compression |
| **CPU Usage** | 5-15% reduction | Optimized JIT compilation |

## ⚠️ Considerations

### Trade-offs
- **Publish Size**: ReadyToRun increases deployment size by ~30%
- **Build Time**: Optimizations increase build time
- **Debugging**: Some optimizations reduce debug information

### Compatibility
- **Trimming Warnings**: Expected for complex frameworks like ASP.NET Core
- **Native AOT**: Not enabled (requires extensive compatibility work)
- **Third-party Libraries**: Most libraries are compatible with these optimizations

## 🔧 Customization

### Disabling Specific Optimizations
To disable any optimization, remove or set to `false` in the project file:

```xml
<!-- Disable ReadyToRun -->
<PublishReadyToRun>false</PublishReadyToRun>

<!-- Disable PGO -->
<TieredPGO>false</TieredPGO>

<!-- Disable trimming -->
<PublishTrimmed>false</PublishTrimmed>
```

### Environment-Specific Settings
Different optimizations can be applied per environment using MSBuild conditions:

```xml
<PropertyGroup Condition="'$(Configuration)' == 'Release'">
    <PublishReadyToRun>true</PublishReadyToRun>
    <TieredPGO>true</TieredPGO>
</PropertyGroup>
```

## 📚 References

- [.NET 8 Performance Improvements](https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-8/)
- [ReadyToRun Deployment](https://docs.microsoft.com/en-us/dotnet/core/deploying/readytorun)
- [Dynamic PGO](https://devblogs.microsoft.com/dotnet/dynamic-pgo-in-net-6/)
- [Assembly Trimming](https://docs.microsoft.com/en-us/dotnet/core/deploying/trimming/trim-self-contained)
- [ASP.NET Core Performance Best Practices](https://docs.microsoft.com/en-us/aspnet/core/performance/performance-best-practices)
