# Security Hardening Guide for Elixir/Phoenix Applications

**Last Updated**: 2026-02-19  
**Audience**: Elixir developers, DevOps engineers, security teams

---

## Overview

This guide covers security hardening best practices for Elixir/Phoenix applications, including OWASP Top 10, cryptography, secrets management, and security audit checklists.

---

## 1. OWASP Top 10 for Elixir

### 1.1 Injection Prevention

#### SQL Injection

**✅ DO: Use Ecto parameterized queries**

```elixir
# Safe: Parameterized query
def get_user(email) do
  User
  |> where([u], u.email == ^email)
  |> Repo.one()
end

# Safe: Ecto changeset validation
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end

# ❌ DON'T: String interpolation
def get_user(email) do
  query = "SELECT * FROM users WHERE email = '#{email}'"
  Repo.query!(query)  # VULNERABLE!
end
```

#### Command Injection

**✅ DO: Use proper argument lists**

```elixir
# Safe: Argument list
def convert_pdf(file_path) do
  System.cmd("convert", [file_path, "output.png"])
end

# ❌ DON'T: Shell interpolation
def convert_pdf(file_path) do
  System.cmd("sh", ["-c", "convert #{file_path} output.png"])  # VULNERABLE!
end
```

---

### 1.2 Broken Authentication

**✅ DO: Use battle-tested libraries**

```elixir
# Use Ash authentication or Guardian
defmodule MyApp.Accounts do
  use Ash.Domain

  resources do
    resource MyApp.Accounts.User do
      # Ash handles authentication securely
    end
  end
end

# Secure password hashing with bcrypt
defmodule MyApp.Accounts.User do
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password ->
        hash = Bcrypt.hash_pwd_salt(password)
        put_change(changeset, :password_hash, hash)
    end
  end
end

# ❌ DON'T: Roll your own crypto
defp hash_password(password) do
  :crypto.hash(:sha256, password)  # WEAK!
end
```

---

### 1.3 Sensitive Data Exposure

**✅ DO: Encrypt sensitive data**

```elixir
# Use encrypted fields for PII
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
    field :ssn, MyApp.Encrypted.Binary  # Encrypted field
    field :credit_card, MyApp.Encrypted.Binary
  end
end

# Encryption module
defmodule MyApp.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: MyApp.Vault
end

# Vault configuration
defmodule MyApp.Vault do
  use Cloak.Vault, otp_app: :my_app
end

# ❌ DON'T: Store sensitive data in plain text
defmodule MyApp.Accounts.User do
  schema "users" do
    field :ssn, :string  # VULNERABLE!
  end
end
```

---

### 1.4 XML External Entities (XXE)

**✅ DO: Disable DTD and external entities**

```elixir
def parse_xml(xml_string) do
  # Use safe XML parser
  SweetXml.parse(xml_string, [
    {:parser, SweetXml.Parsers.SweetXmlParser},
    {:entity_expansion, :off}  # Disable entity expansion
  ])
end
```

---

### 1.5 Broken Access Control

**✅ DO: Use policies and authorization**

```elixir
# Use Ash policies
defmodule MyApp.Accounts.User do
  use Ash.Resource

  policies do
    policy action(:read) do
      authorize_if relates_to_actor_via(:tenant)
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  attributes do
    attribute :role, :atom do
      constraints one_of: [:admin, :user]
    end
  end
end

# ❌ DON'T: Client-side authorization
def update(conn, %{"id" => id, "role" => role}) do
  user = Repo.get!(User, id)
  # VULNERABLE: No server-side check!
  {:ok, user} = Accounts.update_user(user, %{role: role})
  json(conn, user)
end
```

---

### 1.6 Security Misconfiguration

**✅ DO: Secure configuration**

```elixir
# config/prod.exs
config :my_app, MyAppWeb.Endpoint,
  http: [
    port: 4000,
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [host: "example.com", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  # Security headers
  force_ssl: [hsts: true]

# Secure session config
config :my_app, MyAppWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SALT")]

# ❌ DON'T: Hardcode secrets
config :my_app, MyAppWeb.Endpoint,
  secret_key_base: "hardcoded_secret_key"  # VULNERABLE!
```

---

### 1.7 Cross-Site Scripting (XSS)

**✅ DO: Let Phoenix escape HTML automatically**

```elixir
# Safe: Phoenix escapes HTML by default
<div><%= @user_input %></div>

# Safe: Use Phoenix.HTML for safe rendering
<%= raw(sanitize_html(@user_input)) %>

# ❌ DON'T: Use raw without sanitization
<%= raw(@user_input) %>  # VULNERABLE!
```

---

### 1.8 Insecure Deserialization

**✅ DO: Validate and sanitize inputs**

```elixir
# Safe: Validate binary format
def parse_json(json_string) do
  case Jason.decode(json_string) do
    {:ok, data} -> 
      # Validate structure
      {:ok, validate_data(data)}
    {:error, _} = error -> 
      error
  end
end

# Safe: Use Ecto changesets
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> validate_required([:email])
  |> Repo.insert()
end

# ❌ DON'T: Use term_to_binary on untrusted input
def load_user(binary) do
  :erlang.binary_to_term(binary)  # DANGEROUS!
end
```

---

### 1.9 Using Components with Known Vulnerabilities

**✅ DO: Regular dependency audits**

```bash
# Check for vulnerable dependencies
mix hex.audit

# Update dependencies regularly
mix deps.update --all

# Use Dependabot or Snyk for automated scanning
```

---

### 1.10 Insufficient Logging & Monitoring

**✅ DO: Comprehensive logging**

```elixir
# Log security events
defmodule MyAppWeb.AuthController do
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        Logger.info("User login successful", 
          user_id: user.id, 
          email: user.email,
          ip: conn.remote_ip)
        
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")

      :error ->
        Logger.warn("Failed login attempt",
          email: email,
          ip: conn.remote_ip)
        
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render(:login)
    end
  end
end

# ❌ DON'T: Log sensitive data
Logger.info("User login: #{user.password}")  # VULNERABLE!
```

---

## 2. Cryptography Best Practices

### 2.1 Password Hashing

```elixir
# Use bcrypt or argon2
defmodule MyApp.Accounts.User do
  import Bcrypt, only: [hash_pwd_salt: 1, verify_pass: 2]

  def verify_password(user, password) do
    verify_pass(password, user.password_hash)
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password ->
        put_change(changeset, :password_hash, hash_pwd_salt(password))
    end
  end
end

# ❌ DON'T: Use weak hashing
defp hash_password(password) do
  :crypto.hash(:md5, password)  # BROKEN!
end
```

---

### 2.2 Token Generation

```elixir
# Secure random tokens
defmodule MyApp.Tokens do
  def generate_token(bytes \\ 32) do
    :crypto.strong_rand_bytes(bytes)
    |> Base.url_encode64(padding: false)
  end

  def generate_uuid do
    UUID.uuid4()
  end
end

# ❌ DON'T: Use predictable tokens
def generate_token do
  to_string(:rand.uniform(1_000_000))  # PREDICTABLE!
end
```

---

### 2.3 Encryption at Rest

```elixir
# Use Cloak or envelope encryption
defmodule MyApp.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: MyApp.Vault
end

defmodule MyApp.Vault do
  use Cloak.Vault, otp_app: :my_app

  @impl true  def init(config) do
    config = Keyword.put(config, :ciphers, [
      default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: :crypto.strong_rand_bytes(32)}
    ])
    {:ok, config}
  end
end

# ❌ DON'T: Store secrets in plain text
def store_secret(secret) do
  File.write!("secrets.txt", secret)  # VULNERABLE!
end
```

---

### 2.4 HTTPS/TLS Configuration

```elixir
# Enforce SSL
config :my_app, MyAppWeb.Endpoint,
  force_ssl: [hsts: true, expires: 31_536_000]

# Secure headers
defmodule MyAppWeb.Plugs.SecurityHeaders do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("strict-transport-security", "max-age=31536000; includeSubDomains")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("content-security-policy", "default-src 'self'")
  end
end
```

---

## 3. Secrets Management

### 3.1 Environment Variables

```elixir
# Use environment variables
config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "10")

config :my_app, MyAppWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# ❌ DON'T: Hardcode secrets
config :my_app, MyApp.Repo,
  password: "secret123"  # VULNERABLE!
```

---

### 3.2 Vault Integration (HashiCorp Vault)

```elixir
# Use vault for secrets
defmodule MyApp.Vault do
  use Vault

  def get_secret(path) do
    Vault.read(__MODULE__, path)
  end
end

# Dynamic database credentials
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app

  def init(_, config) do
    case get_vault_credentials() do
      {:ok, user, password} ->
        config = Keyword.merge(config, [
          username: user,
          password: password
        ])
        {:ok, config}
      :error ->
        {:ok, config}
    end
  end

  defp get_vault_credentials do
    # Fetch dynamic credentials from Vault
    MyApp.Vault.get_secret("database/creds/myapp")
  end
end
```

---

### 3.3 .gitignore Configuration

```gitignore
# .gitignore - Prevent committing secrets
.env
.env.*
*.pem
*.key
credentials.json
secrets.json
```

---

## 4. Security Audit Checklist

### Pre-Deployment Checklist

#### Authentication & Authorization
- [ ] Use strong password hashing (bcrypt/argon2)
- [ ] Implement password complexity requirements
- [ ] Enable multi-factor authentication (MFA)
- [ ] Implement rate limiting on login endpoints
- [ ] Use secure session management
- [ ] Implement proper role-based access control (RBAC)
- [ ] Validate all authorization on server-side

#### Data Protection
- [ ] Encrypt sensitive data at rest
- [ ] Use HTTPS everywhere
- [ ] Implement proper TLS configuration
- [ ] Validate and sanitize all user inputs
- [ ] Use parameterized queries (Ecto)
- [ ] Implement data retention policies
- [ ] Regular backup encryption

#### Session Management
- [ ] Use secure, random session IDs
- [ ] Set secure cookie flags (Secure, HttpOnly, SameSite)
- [ ] Implement session timeout
- [ ] Regenerate session ID on login
- [ ] Implement proper logout

#### API Security
- [ ] Implement API authentication
- [ ] Use rate limiting
- [ ] Validate API input parameters
- [ ] Implement CORS properly
- [ ] Use API versioning
- [ ] Log all API access

#### Infrastructure Security
- [ ] Keep dependencies updated
- [ ] Run regular security audits (`mix hex.audit`)
- [ ] Use security scanning tools (Snyk, Dependabot)
- [ ] Implement proper firewall rules
- [ ] Use VPN for internal services
- [ ] Regular security patching

#### Logging & Monitoring
- [ ] Log security events
- [ ] Monitor for suspicious activity
- [ ] Set up alerting for security events
- [ ] Implement intrusion detection
- [ ] Regular security log review

#### Error Handling
- [ ] Implement proper error handling
- [ ] Don't expose stack traces in production
- [ ] Log errors securely
- [ ] Implement graceful degradation

---

## 5. Security Tools

### Static Analysis

```bash
# Run sobelow for Phoenix security analysis
mix sobelow --verbose

# Run mix hex.audit for dependency vulnerabilities
mix hex.audit

# Run dialyzer for type checking
mix dialyzer
```

### Dynamic Analysis

```bash
# Use OWASP ZAP for web application scanning
# Use Burp Suite for API security testing
# Use Nikto for web server scanning
```

### Monitoring

```elixir
# Use Sentry for error tracking
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# Use Prometheus for metrics
defmodule MyAppWeb.Plugs.Metrics do
  use Prometheus.Plug
end
```

---

## 6. Incident Response Plan

### Immediate Actions

1. **Assess**: Determine scope and severity
2. **Contain**: Isolate affected systems
3. **Communicate**: Notify stakeholders
4. **Document**: Record all actions taken

### Post-Incident

1. **Analyze**: Root cause analysis
2. **Remediate**: Fix vulnerabilities
3. **Review**: Update security policies
4. **Train**: Educate team on lessons learned

---

## 7. Security Resources

### Tools
- **sobelow**: Phoenix security analysis
- **hex.audit**: Dependency vulnerability scanner
- **Snyk**: Automated security scanning
- **Dependabot**: Automated dependency updates

### References
- **OWASP Top 10**: https://owasp.org/Top10/
- **Phoenix Security Guide**: https://hexdocs.pm/phoenix/security.html
- **Ecto Security**: https://hexdocs.pm/ecto/Ecto.html
- **Ash Security**: https://hexdocs.pm/ash/security.html

---

## 8. Secure Development Workflow

### Code Review Checklist

- [ ] No hardcoded secrets
- [ ] All inputs validated
- [ ] All queries parameterized
- [ ] Proper error handling
- [ ] Security tests included
- [ ] Logging implemented
- [ ] Documentation updated

### CI/CD Security

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Run security audit
        run: mix hex.audit
      
      - name: Run sobelow
        run: mix sobelow --exit
```

---

## Related Patterns

- `skills/security-patterns/SKILL.md` - Security patterns
- `skills/otp-patterns/SKILL.md` - OTP security considerations
- `patterns/error_handling.md` - Secure error handling

---

**Last Updated**: 2026-02-19

**Next Review**: Quarterly or after major security updates
