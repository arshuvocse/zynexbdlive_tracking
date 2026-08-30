// File: src/LiveTracking.Infrastructure/Files/LocalFileStorageService.cs
using LiveTracking.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace LiveTracking.Infrastructure.Files;

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _wwwrootPath;

    public LocalFileStorageService(IConfiguration configuration)
    {
        var configuredRoot = configuration["Storage:WwwrootPath"];
        _wwwrootPath = string.IsNullOrWhiteSpace(configuredRoot)
            ? Path.Combine(AppContext.BaseDirectory, "wwwroot")
            : configuredRoot;
    }

    public async Task<string> SaveAsync(Stream content, string subFolder, string fileName, CancellationToken cancellationToken = default)
    {
        var directory = Path.Combine(_wwwrootPath, "uploads", subFolder);
        Directory.CreateDirectory(directory);

        var fullPath = Path.Combine(directory, fileName);

        await using (var fileStream = new FileStream(fullPath, FileMode.Create, FileAccess.Write))
        {
            await content.CopyToAsync(fileStream, cancellationToken);
        }

        return Path.Combine("uploads", subFolder, fileName).Replace('\\', '/');
    }

    public Stream? Open(string relativePath)
    {
        var normalized = relativePath.Replace('/', Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(_wwwrootPath, normalized);

        return File.Exists(fullPath) ? File.OpenRead(fullPath) : null;
    }
}
