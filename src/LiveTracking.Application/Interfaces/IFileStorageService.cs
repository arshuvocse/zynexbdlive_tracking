// File: src/LiveTracking.Application/Interfaces/IFileStorageService.cs
namespace LiveTracking.Application.Interfaces;

public interface IFileStorageService
{
    /// <summary>Saves a file under the given subfolder and returns its relative storage path.</summary>
    Task<string> SaveAsync(Stream content, string subFolder, string fileName, CancellationToken cancellationToken = default);

    /// <summary>Opens a previously saved file for reading. Returns null if it doesn't exist.</summary>
    Stream? Open(string relativePath);
}
