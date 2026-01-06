# Migration Strategies (Ecto and Ash)

**Last Reviewed**: 2025-01-06  
**Source Material**: codesearch + Ash-HQ documentation (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Designing database migrations
- Handling data preservation during schema changes
- Rollback strategies for failed migrations
- Testing migrations

❌ **DON'T use this file when**:
- Making direct schema changes (use migrations)
- Manual SQL in production (use Ash DSL)
- Dropping columns without data migration

**See also**:
- `ash_resources.md` - Ash resource patterns
- `phoenix_controllers.md` - Controller patterns (for Ecto changes)
- `error_handling.md` - Error handling in migrations

---

## Pattern 1: Ash Automatic Migration Generation

**Problem**: Schema changes require migration files

✅ **Solution**: Use Ash code generation

```elixir
# In config/config.exs
config :my_app, :ash_domains,
  resources: [MyApp.Accounts, MyApp.Blog],
  allow_migrations?: true

# Generate and run migrations
mix ash.generate_migrations
mix ash.install
mix ecto.migrate
```

**Reference**: Ash-HQ - Migration documentation

---

## Pattern 2: Ash Data Preservation

**Problem**: Migration deletes data without warning

✅ **Solution**: Use Ash migration SQL with `change_default`

```elixir
defmodule MyApp.Repo.Migrations.AddNewColumn do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :new_column, :string, default: "default_value"
    end

  def down do
    alter table(:users) do
      remove :new_column
    end
end
```

**Reference**: Ash-HQ - Migration strategies

---

## Pattern 3: Ecto Multi-Step Migrations

**Problem**: Complex schema changes need multiple steps

✅ **Solution**: Use Ecto migration transactions

```elixir
defmodule MyApp.Repo.Migrations.RenameAndAddColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      rename :old_name, to: :new_name
      add :new_field, :string
    end
  end
end
```

**Reference**: Ecto documentation

---

## Pattern 4: Rollback Strategies

**Problem**: Migration fails, need to revert

✅ **Solution**: Use Ecto.rollback/3

```elixir
# Option 1: Automatic with down function
defmodule MyApp.Repo.Migrations.AddColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :new_column, :string
    end

  def down do
    alter table(:users) do
      remove :new_column
    end
end

# Option 2: Manual rollback
mix ecto.rollback --to 20250101000001
```

**Reference**: Ecto documentation

---

## Pattern 5: Testing Migrations

**Problem**: Ensure migration doesn't break app

✅ **Solution**: Use DataCase for isolation

```elixir
defmodule MyApp.Repo.Migrations.AddColumnTest do
  use MyApp.DataCase

  setup do
    {:ok, user} = insert(:user, name: "Test")
  end

  test "new column exists after migration" do
    columns = MyApp.Repo.__meta__(:users).columns
    assert :new_column in columns
  end

  test "can query with new column" do
    users = Repo.all(User)
    assert Enum.all?(users, &(&1.new_column != nil))
  end
end
```

**Reference**: Ash-HQ - Testing documentation

---

## Pattern 6: Zero-Downtime Migrations

**Problem**: Migration blocks application

✅ **Solution**: Use Ecto's SQL-level locking

```elixir
# In migration
def change do
    execute "LOCK TABLE users IN SHARE MODE EXCLUSIVE"
    # ... migration logic
    execute "UNLOCK TABLE users"
  end
```

**Reference**: Ecto documentation

---

## Pattern 7: Ash Migration Extensions

**Concept**: Use Ash extensions for complex migrations

✅ **Example**: Bulk operations

```elixir
defmodule MyApp.Repo.Migrations.BulkUpdate do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :status, :string, default: "active"
    end

  def up do
    # Bulk update Ash
    MyApp.Accounts.User
    |> Ash.Query.filter(status: "inactive")
    |> Ash.Query.update(status: "active")
    |> Ash.bulk_create!()
  end
end
```

**Reference**: Ash-HQ documentation

---

## Pattern 8: Ash vs Ecto Decision Matrix

| Use Case | Recommendation | Reason |
|-----------|----------------|---------|
| New Phoenix app | Ecto (standard) | Full control, familiar patterns |
| Phoenix + Ash | Ash (recommended) | Declarative, API generation, built-in policies |
| Legacy app | Ecto | Minimal disruption, gradual migration |
| Complex domain | Ash | Type-safe, multi-tenancy support |

✅ **Decision Guide**: Choose Ash for new Phoenix + Ash projects

---

## Pattern 9: Index Migration

**Problem**: Reindexing large tables takes hours

✅ **Solution**: Use concurrent index creation

```elixir
# SQL-based approach
def change do
    execute "CREATE INDEX CONCURRENTLY users_email_idx ON users(email)"
  end

# Or use Ash's built-in indexes
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    custom_indexes do
      index :users_email_idx, on: [:email]
    end
end
```

**Reference**: Ash-HQ + Postgres documentation

---

## Pattern 10: Data Migration Between Versions

**Problem**: Moving from Ecto to Ash

✅ **Solution**: Use Ash code-first approach

```elixir
# Step 1: Keep Ecto schema for compatibility
# Step 2: Create Ash resources mirroring Ecto schemas
# Step 3: Implement business logic in Ash actions
# Step 4: Gradually migrate data access to Ash
# Step 5: Deprecate Ecto models once Ash is stable
```

**Reference**: Medium - "Building a SaaS Using Phoenix and Ash Framework" (2024)

---

## Testing Patterns for This File

### Testing Ash Migrations

```elixir
defmodule MyApp.Repo.MigrationsTest do
  use MyApp.DataCase

  test "migration adds column" do
    columns = MyApp.Repo.__meta__(:users).columns
    refute :new_column in columns
  end

  test "can use new column" do
    user = insert(:user, new_column: "test")
    assert user.new_column == "test"
  end
end
```

### Testing Ecto Rollbacks

```elixir
defmodule MyApp.Repo.RollbackTest do
  use MyApp.DataCase

  test "migration fails and rolls back" do
    # Simulate migration failure
    # Then rollback
    # Verify state
  end
end
```

---

## References

**Primary Sources**:
- Ash-HQ - Migration documentation
- codesearch "Elixir migration patterns 2025"
- Medium - "Building a SaaS Using Phoenix and Ash Framework" (2024)

**Related Patterns**:
- `ash_resources.md` - Ash resource patterns
- `phoenix_controllers.md` - Controller patterns
- `error_handling.md` - Error handling patterns

**Deep Dives**:
- Ash Framework Book by Kamaro Lambert
- `docs/igniter-how-to.md` - Igniter usage guide
