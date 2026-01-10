# Internationalization (i18n) Skill

## Overview

Comprehensive guide to implementing internationalization and localization in Elixir applications.

## When to Use Internationalization

**Use i18n when:**
- Your application serves users from multiple regions/languages
- You need to support right-to-left (RTL) languages
- You need to format dates, numbers, and currencies according to locale
- You need to translate UI elements, error messages, and content

**Skip i18n when:**
- Your application serves a single market with one language
- Content is technical documentation that doesn't need translation
- The cost of translation exceeds the value for your users

## ExCuberets (ex_cldr)

### DO: Use ex_cldr for Number/Date Formatting

```elixir
# mix.exs
defp deps do
  [
    {:ex_cldr, "~> 2.0"},
    {:ex_cldr_numbers, "~> 2.0"},
    {:ex_cldr_dates_times, "~> 2.0"},
    {:ex_cldr_plugs, "~> 1.0"}
  ]
end

# config/config.exs
config :ex_cldr,
  default_locale: "en",
  locales: ["en", "fr", "es", "de", "ja", "ar"],
  gettext: MyApp.Gettext,
  data_dir: "./priv/cldr",
  precompile_number_formats: ["¤#,##0.00"],
  precompile_date_formats: ["YYYY-MM-dd", "YYYY/MM/dd", "dd/MM/YYYY"]

# Usage in code
defmodule MyApp.Numbers do
  def format_currency(amount, currency, locale \\ "en") do
    MyApp.Cldr.Number.to_string(amount,
      currency: currency,
      locale: locale,
      format: :currency
    )
  end

  def format_number(number, locale \\ "en") do
    MyApp.Cldr.Number.to_string(number, locale: locale)
  end
end

# Usage
MyApp.Numbers.format_currency(1234.56, :USD, "en")  # "$1,234.56"
MyApp.Numbers.format_currency(1234.56, :EUR, "fr")  # "1 234,56 €"
MyApp.Numbers.format_number(1234567.89, "de")        # "1.234.567,89"
```

### DON'T: Hard-Number/Date Formats

```elixir
# DON'T: Hard-code formats
def format_money(amount) do
  "$#{:erlang.float_to_binary(amount / 100, decimals: 2)}"
end

def format_date(date) do
  "#{date.month}/#{date.day}/#{date.year}"
end

# DO: Use ex_cldr for locale-aware formatting
def format_money(amount, locale \\ "en") do
  MyApp.Cldr.Number.to_string(amount, currency: :USD, locale: locale)
end

def format_date(date, locale \\ "en") do
  MyApp.Cldr.Date.to_string(date, locale: locale)
end
```

## Gettext for Translations

### DO: Organize Translations by Domain

```elixir
# locales/en/LC_MESSAGES/errors.po
msgid "User not found"
msgstr "User not found"

msgid "Invalid credentials"
msgstr "Invalid credentials"

# locales/fr/LC_MESSAGES/errors.po
msgid "User not found"
msgstr "Utilisateur non trouvé"

msgid "Invalid credentials"
msgstr "Identifiants invalides"

# locales/en/LC_MESSAGES/validation.po
msgid "is required"
msgstr "is required"

msgid "must be at least %{count} characters"
msgstr "must be at least %{count} characters"

# locales/fr/LC_MESSAGES/validation.po
msgid "is required"
msgstr "est requis"

msgid "must be at least %{count} characters"
msgstr "doit contenir au moins %{count} caractères"
```

### DO: Use Named Interpolation Variables

```elixir
# DON'T: Positional variables (harder for translators)
# locales/en/LC_MESSAGES/messages.po
msgid "Welcome %s, you have %d messages"
msgstr "Welcome %s, you have %d messages"

# DO: Named variables (easier for translators)
# locales/en/LC_MESSAGES/messages.po
msgid "Welcome %{name}, you have %{count} messages"
msgid_plural "Welcome %{name}, you have %{count} messages"
msgstr[0] "Welcome %{name}, you have %{count} messages"
msgstr[1] "Welcome %{name}, you have %{count} message"

# locales/fr/LC_MESSAGES/messages.po
msgid "Welcome %{name}, you have %{count} messages"
msgid_plural "Welcome %{name}, you have %{count} messages"
msgstr[0] "Bienvenue %{name}, vous avez %{count} messages"
msgstr[1] "Bienvenue %{name}, vous avez %{count} message"
```

## Pluralization

### DO: Use Gettext Pluralization

```elixir
# locales/en/LC_MESSAGES/posts.po
msgid "You have one post"
msgid_plural "You have %{count} posts"
msgstr[0] "You have one post"
msgstr[1] "You have %{count} posts"

# locales/fr/LC_MESSAGES/posts.po
msgid "You have one post"
msgid_plural "You have %{count} posts"
msgstr[0] "Vous avez un article"
msgstr[1] "Vous avez %{count} articles"

# Usage in code
defmodule MyApp.Posts do
  def show_post_count(count, locale \\ "en") do
    Gettext.dgettext(MyApp.Gettext, "posts", "You have one post", "You have %{count} posts", count, count: count)
  end
end
```

### DON'T: Manually Handle Plurals

```elixir
# DON'T: Manual pluralization
def show_post_count(count) do
  case count do
    1 -> "You have one post"
    _ -> "You have #{count} posts"
  end
end

# DO: Use Gettext's pluralization
def show_post_count(count, locale \\ "en") do
  Gettext.dngettext(MyApp.Gettext, "posts", "You have one post", "You have %{count} posts", count, count: count)
end
```

## Context-Aware Translations

### DO: Use Domains for Context

```elixir
# locales/en/LC_MESSAGES/errors.po
msgid "save"
msgstr "save"

# locales/en/LC_MESSAGES/actions.po
msgid "save"
msgstr "Save"

# locales/en/LC_MESSAGES/buttons.po
msgid "save"
msgstr "Save"

# Usage: Different translations in different contexts
defmodule MyApp.Translations do
  # From errors domain
  defp error_message, do: dgettext("errors", "save")

  # From actions domain
  defp action_label, do: dgettext("actions", "save")

  # From buttons domain
  defp button_text, do: dgettext("buttons", "save")
end
```

## RTL (Right-to-Left) Support

### DO: Support RTL Languages

```elixir
defmodule MyApp.RTL do
  def rtl_locales, do: ["ar", "he", "fa", "ur"]

  def rtl?(locale \\ "en") do
    locale in rtl_locales()
  end

  def text_direction(locale \\ "en") do
    if rtl?(locale), do: "rtl", else: "ltr"
  end
end

# Usage in Phoenix LiveView
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    locale = get_locale(socket)

    {:ok,
     socket
     |> assign(:rtl?, MyApp.RTL.rtl?(locale))
     |> assign(:text_direction, MyApp.RTL.text_direction(locale))}

  end
end

# In HEEx template
<div dir={@text_direction} class="container">
  <%= gettext("Welcome") %>
</div>
```

## LiveView Internationalization

### DO: Pass Locale Through Assigns

```elixir
defmodule MyAppWeb.Layouts do
  use MyAppWeb, :html

  def on_mount(:default, _params, _session, socket) do
    locale = get_locale_from_session(socket)

    {:cont,
     socket
     |> assign(:locale, locale)
     |> assign(:rtl?, MyApp.RTL.rtl?(locale))
     |> assign(:gettext, fn msg -> Gettext.gettext(MyApp.Gettext, msg) end)}
  end

  defp get_locale_from_session(socket) do
    socket.assigns[:locale] || "en"
  end
end

# Use in LiveView templates
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="content">
      <h1><%= gettext("Welcome") %></h1>
      <p><%= gettext("You have %{count} messages", count: @message_count) %></p>
    </div>
    """
  end
end
```

### DON'T: Hard-Code Locale in Components

```elixir
# DON'T: Hard-coded locale
defmodule MyAppWeb.Components do
  def button(assigns) do
    ~H"""
    <button><%= gettext("Save", locale: "en") %></button>
    """
  end
end

# DO: Pass locale from parent
defmodule MyAppWeb.Components do
  attr :locale, :string, default: "en"

  def button(assigns) do
    ~H"""
    <button><%= Gettext.gettext(MyApp.Gettext, "Save", @locale) %></button>
    """
  end
end
```

## Database-Level Internationalization

### DO: Store Translatable Content Separately

```elixir
# Schema for translatable content
defmodule MyApp.Content.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :locale, :string
    field :field_name, :string
    field :content, :string

    belongs_to :translatable, MyApp.Content.Translatable

    timestamps()
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:locale, :field_name, :content])
    |> validate_required([:locale, :field_name, :content])
    |> unique_constraint([:translatable_id, :locale, :field_name])
  end
end

# Usage
defmodule MyApp.Content.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body, :string

    has_many :translations, MyApp.Content.Translation
  end

  def get_translated_title(%__MODULE__{translations: translations} = _post, locale) do
    Enum.find(translations, fn t -> t.locale == locale && t.field_name == "title" end)
    |> case do
      nil -> nil  # Fallback to default language
      translation -> translation.content
    end
  end
end
```

## Date/Time Localization

### DO: Use ex_cldr for Date/Time Formatting

```elixir
defmodule MyApp.Dates do
  def format_date(date, locale \\ "en") do
    MyApp.Cldr.Date.to_string(date, locale: locale)
  end

  def format_time(time, locale \\ "en") do
    MyApp.Cldr.Time.to_string(time, locale: locale)
  end

  def format_datetime(datetime, locale \\ "en") do
    MyApp.Cldr.DateTime.to_string(datetime, locale: locale)
  end

  def relative_time(datetime, locale \\ "en") do
    MyApp.Cldr.Relative.to_string(datetime, locale: locale)
  end
end

# Usage
MyApp.Dates.format_date(~D[2026-01-10], "en")  # "January 10, 2026"
MyApp.Dates.format_date(~D[2026-01-10], "fr")  # "10 janvier 2026"
MyApp.Dates.format_date(~D[2026-01-10], "ja")  # "2026年1月10日"
```

## Number/Currency Localization

### DO: Use ex_cldr for Currency Formatting

```elixir
defmodule MyApp.Currency do
  def format_money(amount, currency \\ :USD, locale \\ "en") do
    MyApp.Cldr.Number.to_string(amount,
      currency: currency,
      locale: locale,
      format: :currency
    )
  end

  def format_percent(value, locale \\ "en") do
    MyApp.Cldr.Number.to_string(value,
      format: :percent,
      locale: locale
    )
  end
end

# Usage
MyApp.Currency.format_money(1234.56, :USD, "en")  # "$1,234.56"
MyApp.Currency.format_money(1234.56, :EUR, "fr")  # "1 234,56 €"
MyApp.Currency.format_money(1234.56, :JPY, "ja")  # "¥1,235"
MyApp.Currency.format_percent(0.85, "en")          # "85%"
MyApp.Currency.format_percent(0.85, "fr")          # "85 %"
```

## Common Pitfalls

### DON'T: Store Translated Strings in Database

```elixir
# DON'T: Store translated strings in database
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
  |> case do
    {:ok, user} ->
      # Error message is translated before storing
      error = Gettext.gettext(MyApp.Gettext, "User created successfully", user.locale)
      {:ok, %{user | error_message: error}}
  end
end

# DO: Store message keys, translate on display
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
  |> case do
    {:ok, user} ->
      # Store message key only
      {:ok, %{user | message_key: "user.created.success"}}
  end
end

# Translate on display
def display_message(user, locale \\ "en") do
  Gettext.gettext(MyApp.Gettext, user.message_key, locale)
end
```

## Related Skills

- [API Design](../api-design/SKILL.md) - Internationalized API responses
- [Phoenix Controllers](../../patterns/phoenix_controllers.md) - Accept-Language header handling

## Related Patterns

- [LiveView Patterns](../liveview.md) - LiveView-specific i18n patterns
- [HTML/CSS](../html-css/SKILL.md) - RTL CSS patterns
