// File: src/LiveTracking.Domain/Entities/BaseEntity.cs
namespace LiveTracking.Domain.Entities;

public abstract class BaseEntity<TKey>
{
    public TKey Id { get; set; } = default!;
}
