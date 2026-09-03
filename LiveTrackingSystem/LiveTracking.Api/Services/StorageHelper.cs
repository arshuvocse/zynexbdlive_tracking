using System.Diagnostics;
using System.Security.AccessControl;
using System.Security.Principal;

namespace LiveTracking.Api.Services;

public static class StorageHelper
{
    public static string GetUploadsRoot(IWebHostEnvironment env)
    {
        // Strictly outside wwwroot, directly under application content root
        return Path.Combine(env.ContentRootPath, "uploads");
    }

    public static string GetSelfiesDirectory(IWebHostEnvironment env)
    {
        return Path.Combine(GetUploadsRoot(env), "selfies");
    }

    public static string GetVisitsDirectory(IWebHostEnvironment env)
    {
        return Path.Combine(GetUploadsRoot(env), "visits");
    }

    /// <summary>
    /// Ensures a directory exists and automatically grants full read/write permissions
    /// to Everyone and IIS_IUSRS so IIS / Kestrel never encounters access denied errors.
    /// </summary>
    public static void EnsureDirectoryWithFullPermissions(string path)
    {
        try
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            if (OperatingSystem.IsWindows())
            {
                GrantWindowsPermissions(path);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Storage Warning] Error ensuring directory {path}: {ex.Message}");
        }
    }

    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
    private static void GrantWindowsPermissions(string path)
    {
        // 1. In-process .NET ACL configuration
        try
        {
            var dInfo = new DirectoryInfo(path);
            var dSecurity = dInfo.GetAccessControl();

            var everyoneSid = new SecurityIdentifier(WellKnownSidType.WorldSid, null);
            dSecurity.AddAccessRule(new FileSystemAccessRule(
                everyoneSid,
                FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                PropagationFlags.None,
                AccessControlType.Allow
            ));

            var usersSid = new SecurityIdentifier(WellKnownSidType.BuiltinUsersSid, null);
            dSecurity.AddAccessRule(new FileSystemAccessRule(
                usersSid,
                FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                PropagationFlags.None,
                AccessControlType.Allow
            ));

            dInfo.SetAccessControl(dSecurity);
        }
        catch { }

        // 2. System-level icacls fallback for IIS / Windows Services
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "icacls",
                Arguments = $"\"{path}\" /grant *S-1-1-0:(OI)(CI)F /grant *S-1-5-32-568:(OI)(CI)F /t /q",
                CreateNoWindow = true,
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using var proc = Process.Start(psi);
            proc?.WaitForExit(3000);
        }
        catch { }
    }
}
