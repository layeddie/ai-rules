# i18n Patterns

## Overview

Patterns for implementing internationalization and localization in Elixir applications.

## Gettext Setup

### Basic Gettext Configuration

```elixir
# mix.exs
defp deps do
  [
    {:gettext, "~> 0.20"}
  ]
end

# config/config.exs
config :my_app, MyAppWeb.Gettext,
  default_locale: "en",
  priv: "priv/gettext"

# lib/my_app_web/gettext.ex
defmodule MyAppWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.
  """
  use Gettext, otp_app: :my_app
end

# lib/my_app_web.ex (helper functions)
defmodule MyAppWeb do
  def gettext(text, bindings \\ %{}, locale \\ "en") do
    Gettext.put_locale(MyAppWeb.Gettext, locale)
    Gettext.gettext(MyAppWeb.Gettext, text, bindings)
  end

  def dgettext(domain, text, bindings \\ %{}, locale \\ "en") do
    Gettext.put_locale(MyAppWeb.Gettext, locale)
    Gettext.dgettext(MyAppWeb.Gettext, domain, text, bindings)
  end
end
```

### Extracting Strings for Translation

```bash
# Extract translatable strings from codebase
mix gettext.extract

# Merge new translations with existing .po files
mix gettext.merge priv/gettext

# Update .po files with new translations
mix gettext.merge priv/gettext --overwrite
```

## Translation Domain Organization

### By Feature

```elixir
# locales/en/LC_MESSAGES/user.po
msgid "User profile"
msgstr "User profile"

msgid "Profile settings"
msgstr "Profile settings"

# locales/en/LC_MESSAGES/post.po
msgid "Create post"
msgstr "Create post"

msgid "Edit post"
msgstr "Edit post"

# Usage in code
defmodule MyApp.Users do
  def show_profile do
    Gettext.dgettext(MyAppWeb.Gettext, "user", "User profile")
  end
end

defmodule MyApp.Posts do
  def create_post do
    Gettext.dgettext(MyAppWeb.Gettext, "post", "Create post")
  end
end
```

### By Context

```elixir
# locales/en/LC_MESSAGES/errors.po
msgid "Invalid email format"
msgstr "Invalid email format"

msgid "Password too short"
msgstr "Password too short"

# locales/en/LC_MESSAGES/validation.po
msgid "is required"
msgstr "is required"

msgid "must be unique"
msgstr "must be unique"

# Usage in code
defmodule MyApp.Validations do
  def validate_email(email) do
    unless valid_email_format?(email) do
      {:error, Gettext.dgettext(MyAppWeb.Gettext, "errors", "Invalid email format")}
    end
  end
end
```

## Pluralization Patterns

### Simple Pluralization

```elixir
# locales/en/LC_MESSAGES/posts.po
msgid "One post"
msgid_plural "Many posts"
msgstr[0] "One post"
msgstr[1] "Many posts"

# Usage
defmodule MyApp.Posts do
  def show_count(count, locale \\ "en") do
    Gettext.dngettext(
      MyAppWeb.Gettext,
      "posts",
      "One post",
      "Many posts",
      count
    )
  end
end
```

### Complex Pluralization with Variables

```elixir
# locales/en/LC_MESSAGES/messages.po
msgid "You have one message"
msgid_plural "You have %{count} messages"
msgstr[0] "You have one message"
msgstr[1] "You have %{count} messages"

# locales/fr/LC_MESSAGES/messages.po
msgid "You have one message"
msgid_plural "You have %{count} messages"
msgstr[0] "Vous avez un message"
msgstr[1] "Vous avez %{count} messages"

# Usage
defmodule MyApp.Messages do
  def show_message_count(count, locale \\ "en") do
    Gettext.dngettext(
      MyAppWeb.Gettext,
      "messages",
      "You have one message",
      "You have %{count} messages",
      count,
      count: count
    )
  end
end
```

## Locale Detection

### From Accept-Language Header

```elixir
defmodule MyAppWeb.Locale do
  @supported_locales ["en", "fr", "es", "de", "ja"]

  def from_accept_language(conn) do
    conn
    |> get_req_header("accept-language")
    |> hd()
    |> parse_accept_language()
    |> find_supported_locale()
  end

  defp parse_accept_language(header) do
    header
    |> String.split(",")
    |> Enum.map(&parse_locale_entry/1)
    |> Enum.sort_by(fn {_locale, quality} -> quality end, :desc)
    |> Enum.map(fn {locale, _quality} -> locale end)
  end

  defp parse_locale_entry(entry) do
    case String.split(entry, ";") do
      [locale] -> {String.trim(locale), 1.0}
      [locale, "q=" <> quality] ->
        {String.trim(locale), String.to_float(quality)}
    end
  end

  defp find_supported_locale(locales) do
    Enum.find(locales, &(&1 in @supported_locales)) || "en"
  end
end

# Plug to set locale
defmodule MyAppWeb.Plugs.SetLocale do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = MyAppWeb.Locale.from_accept_language(conn)
    Gettext.put_locale(MyAppWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end
end
```

### From URL Path

```elixir
# routes.ex
scope "/:locale", MyAppWeb do
  pipe_through [:browser, :set_locale]

  get "/", PageController, :index
  resources "/posts", PostController
end

# Plug
defmodule MyAppWeb.Plugs.SetLocaleFromPath do
  import Plug.Conn

  @supported_locales ["en", "fr", "es"]

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = conn.params["locale"]

    if locale in @supported_locales do
      Gettext.put_locale(MyAppWeb.Gettext, locale)
      assign(conn, :locale, locale)
    else
      # Redirect to default locale
      conn
      |> redirect(to: "/en#{conn.request_path}")
      |> halt()
    end
  end
end
```

### From User Preferences

```elixir
defmodule MyApp.Accounts do
  def update_locale(user, locale) do
    user
    |> Ecto.Changeset.cast(%{locale: locale}, [:locale])
    |> Repo.update()
  end
end

# Plug to set locale from user
defmodule MyAppWeb.Plugs.SetUserLocale do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn  # No user, use default locale

      user ->
        Gettext.put_locale(MyAppWeb.Gettext, user.locale)
        assign(conn, :locale, user.locale)
    end
  end
end
```

## Context-Aware Translations

### Domain-Specific Translations

```elixir
# locales/en/LC_MESSAGES/buttons.po
msgid "save"
msgstr "Save"

msgid "cancel"
msgstr "Cancel"

# locales/en/LC_MESSAGES/actions.po
msgid "save"
msgstr "save"

msgid "cancel"
msgstr "cancel"

# Usage
defmodule MyAppWeb.Components do
  def button_save(text \\ "save", domain \\ "buttons") do
    Gettext.dgettext(MyAppWeb.Gettext, domain, text)
  end

  def action_cancel(text \\ "cancel", domain \\ "actions") do
    Gettext.dgettext(MyAppWeb.Gettext, domain, text)
  end
end
```

### Gender-Aware Translations

```elixir
# locales/en/LC_MESSAGES/profile.po
msgid "Male doctor"
msgid_plural "%{count} male doctors"
msgstr[0] "Male doctor"
msgstr[1] "%{count} male doctors"

msgid "Female doctor"
msgid_plural "%{count} female doctors"
msgstr[0] "Female doctor"
msgstr[1] "%{count} female doctors"

# Usage
defmodule MyApp.Profile do
  def show_doctor(count, gender, locale \\ "en") do
    domain = case gender do
      :male -> "male_doctor"
      :female -> "female_doctor"
    end

    Gettext.dngettext(
      MyAppWeb.Gettext,
      domain,
      "Male doctor",
      "%{count} male doctors",
      count
    )
  end
end
```

## Date/Time Localization

### Using ex_cldr

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

  def format_relative_time(datetime, locale \\ "en") do
    MyApp.Cldr.Relative.to_string(datetime, locale: locale)
  end
end

# Usage examples
MyApp.Dates.format_date(~D[2026-01-10], "en")  # "January 10, 2026"
MyApp.Dates.format_date(~D[2026-01-10], "fr")  # "10 janvier 2026"
MyApp.Dates.format_date(~D[2026-01-10], "ja")  # "2026年1月10日"

MyApp.Dates.format_relative_time(DateTime.utc_now(), "en")  # "now"
MyApp.Dates.format_relative_time(DateTime.utc_now() |> DateTime.add(-3600, :second), "en")  # "1 hour ago"
```

## Number/Currency Localization

### Using ex_cldr

```elixir
defmodule MyApp.Numbers do
  def format_number(number, locale \\ "en") do
    MyApp.Cldr.Number.to_string(number, locale: locale)
  end

  def format_currency(amount, currency \\ :USD, locale \\ "en") do
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

# Usage examples
MyApp.Numbers.format_number(1234567.89, "en")  # "1,234,567.89"
MyApp.Numbers.format_number(1234567.89, "fr")  # "1 234 567,89"

MyApp.Numbers.format_currency(1234.56, :USD, "en")  # "$1,234.56"
MyApp.Numbers.format_currency(1234.56, :EUR, "fr")  # "1 234,56 €"

MyApp.Numbers.format_percent(0.85, "en")  # "85%"
MyApp.Numbers.format_percent(0.85, "fr")  # "85 %"
```

## RTL (Right-to-Left) Support

### RTL Detection

```elixir
defmodule MyApp.RTL do
  @rtl_locales ["ar", "he", "fa", "ur"]

  def rtl?(locale \\ "en"), do: locale in @rtl_locales

  def text_direction(locale \\ "en") do
    if rtl?(locale), do: "rtl", else: "ltr"
  end

  def html_direction(locale \\ "en") do
    ~s(dir="#{text_direction(locale)}")
  end
end
```

### RTL CSS Support

```elixir
# In HTML template
<html dir={MyApp.RTL.text_direction(@locale)} lang={@locale}>
  <body>
    <div class="content">
      <%= gettext("Welcome") %>
    </div>
  </body>
</html>

# In CSS (if using a framework like Tailwind)
# Use logical properties instead of physical properties
.content {
  /* Physical properties */
  margin-left: 1rem;  # Don't use

  /* Logical properties */
  margin-inline-start: 1rem;  # Use instead
  padding-inline-end: 1rem;
}
```

## Related Skills

- [Internationalization](../skills/internationalization/SKILL.md) - Comprehensive i18n guide
- [LiveView Patterns](../liveview.md) - LiveView-specific i18n patterns

## Related Patterns

- [Phoenix Controllers](../phoenix_controllers.md) - Accept-Language header handling
- [HTML/CSS](../html-css/SKILL.md) - RTL CSS patterns
