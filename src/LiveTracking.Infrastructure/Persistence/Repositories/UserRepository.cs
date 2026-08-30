// File: src/LiveTracking.Infrastructure/Persistence/Repositories/UserRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly LiveTrackingDbContext _context;

    public UserRepository(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => _context.Users.Include(u => u.OfficeLocation).FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default)
        => _context.Users.FirstOrDefaultAsync(u => u.Username == username, cancellationToken);

    public Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default)
        => _context.Users.AsNoTracking().Include(u => u.OfficeLocation).OrderBy(u => u.Name).ToListAsync(cancellationToken);

    public Task<bool> UsernameExistsAsync(string username, int? excludeUserId = null, CancellationToken cancellationToken = default)
    {
        var query = _context.Users.Where(u => u.Username == username);
        if (excludeUserId.HasValue)
        {
            query = query.Where(u => u.Id != excludeUserId.Value);
        }
        return query.AnyAsync(cancellationToken);
    }

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
        => await _context.Users.AddAsync(user, cancellationToken);

    public void Update(User user)
        => _context.Users.Update(user);

    public void Remove(User user)
        => _context.Users.Remove(user);
}
