# LiveView i18n Patterns

## Overview

Internationalization patterns specifically for Phoenix LiveView applications.

## Locale Initialization

### On_Mount Hook for Locale

```elixir
defmodule MyAppWeb.Locale do
  def on_mount(:default, _params, _session, socket) do
    locale = get_locale(socket)

    socket =
      socket
      |> assign(:locale, locale)
      |> assign(:rtl?, rtl?(locale))
      |> assign(:text_direction, text_direction(locale))
      |> assign(:gettext, fn msg -> Gettext.gettext(MyAppWeb.Gettext, msg) end)

    {:cont, socket}
  end

  defp get_locale(socket) do
    socket.assigns[:locale] || "en"
  end

  defp rtl?(locale), do: locale in ["ar", "he", "fa", "ur"]

  defp text_direction(locale) do
    if rtl?(locale), do: "rtl", else: "ltr"
  end
end

# In router
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  live_session :default, on_mount: [MyAppWeb.Locale] do
    live "/", PageLive, :index
  end
end
```

### Session-Based Locale

```elixir
defmodule MyAppWeb.Locale do
  def on_mount(:from_session, _params, session, socket) do
    locale = Map.get(session, "locale", "en")

    socket =
      socket
      |> assign(:locale, locale)
      |> assign(:gettext, fn msg -> Gettext.gettext(MyAppWeb.Gettext, msg, locale) end)

    {:cont, socket}
  end
end

# In authentication controller (set locale in session)
defmodule MyAppWeb.AuthController do
  def login(conn, %{"locale" => locale}) do
    conn
    |> put_session("locale", locale)
    |> redirect(to: "/")
  end
end
```

## LiveView Template i18n

### Basic Translations in HEEx

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="content" dir={@text_direction}>
      <h1><%= gettext("Welcome") %></h1>
      <p><%= gettext("You have %{count} messages", count: @message_count) %></p>

      <button class="btn-primary">
        <%= gettext("Save changes") %>
      </button>

      <button class="btn-secondary">
        <%= gettext("Cancel") %>
      </button>
    </div>
    """
  end
end
```

### Domain-Specific Translations

```elixir
defmodule MyAppWeb.ProfileLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <h1><%= dgettext("profile", "User Profile") %></h1>
      <p><%= dgettext("profile", "Settings") %></p>

      <h2><%= dgettext("errors", "Error Messages") %></h2>
      <%= for error <- @errors do %>
        <p class="error"><%= dgettext("errors", error) %></p>
      <% end %>
    </div>
    """
  end
end
```

### Conditional Translations

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <%= if @post.published? do %>
        <p><%= gettext("Published") %></p>
      <% else %>
        <p><%= gettext("Draft") %></p>
      <% end %>

      <%= cond do %>
        <% @post.status == :approved -> %>
          <p><%= gettext("Approved") %></p>
        <% @post.status == :pending -> %>
          <p><%= gettext("Pending approval") %></p>
        <% true -> %>
          <p><%= gettext("Unknown status") %></p>
      <% end %>
    </div>
    """
  end
end
```

## LiveComponent i18n

### Locale Passing to Components

```elixir
defmodule MyAppWeb.Components.PostComponent do
  use MyAppWeb, :live_component

  attr :locale, :string, required: true
  attr :post, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="post">
      <h2><%= dgettext("posts", "Title", locale: @locale) %>: <%= @post.title %></h2>
      <p><%= dgettext("posts", "Content", locale: @locale) %>: <%= @post.body %></p>
    </div>
    """
  end
end

# Usage in parent LiveView
defmodule MyAppWeb.PostsLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <%= for post <- @posts do %>
        <.live_component
          module={MyAppWeb.Components.PostComponent}
          id={"post-#{post.id}"}
          locale={@locale}
          post={post}
        />
      <% end %>
    </div>
    """
  end
end
```

### Component-Level Translations

```elixir
defmodule MyAppWeb.Components do
  def button(assigns) do
    assigns =
      assigns
      |> assign_new(:locale, fn -> "en" end)
      |> assign_new(:text, fn -> "Submit" end)

    ~H"""
    <button type={@type} class={@class}>
      <%= Gettext.gettext(MyAppWeb.Gettext, @text, @locale) %>
    </button>
    """
  end

  def error_message(assigns) do
    assigns =
      assigns
      |> assign_new(:locale, fn -> "en" end)
      |> assign_new(:message, fn -> "An error occurred" end)

    ~H"""
    <div class="error" dir={MyApp.RTL.text_direction(@locale)}>
      <%= Gettext.dgettext(MyAppWeb.Gettext, "errors", @message, @locale) %>
    </div>
    """
  end
end

# Usage in LiveView
defmodule MyAppWeb.FormLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <.button type="submit" locale={@locale} text="Submit form" />
      <.button type="button" locale={@locale} text="Cancel" />

      <%= if @error do %>
        <.error_message locale={@locale} message={@error} />
      <% end %>
    </div>
    """
  end
end
```

## Dynamic Locale Switching

### Locale Switcher Component

```elixir
defmodule MyAppWeb.LocaleSwitcher do
  use MyAppWeb, :live_component

  @available_locales [
    {"English", "en"},
    {"Français", "fr"},
    {"Español", "es"},
    {"Deutsch", "de"},
    {"日本語", "ja"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="locale-switcher">
      <form phx-target={@myself} phx-change="change_locale">
        <select name="locale">
          <%= for {label, locale} <- @available_locales do %>
            <option value={locale} selected={locale == @current_locale}>
              <%= label %>
            </option>
          <% end %>
        </select>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("change_locale", %{"locale" => locale}, socket) do
    send_update(__MODULE__, id: socket.assigns.id, current_locale: locale)

    # Notify parent LiveView of locale change
    send(self(), {:locale_changed, locale})

    {:noreply, socket}
  end
end

# Parent LiveView
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={MyAppWeb.LocaleSwitcher}
        id="locale-switcher"
        current_locale={@locale}
      />

      <h1><%= gettext("Welcome") %></h1>
    </div>
    """
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    socket =
      socket
      |> assign(:locale, locale)
      |> assign(:rtl?, MyApp.RTL.rtl?(locale))
      |> assign(:text_direction, MyApp.RTL.text_direction(locale))

    {:noreply, socket}
  end
end
```

## Server-Side Error Translation

### Translating Changeset Errors

```elixir
defmodule MyAppWeb.Helpers do
  def translate_errors(changeset, locale \\ "en") do
    Ecto.Changeset.traverse_errors(changeset, &translate_error(&1, locale))
  end

  defp translate_error({msg, opts}, locale) do
    if count = opts[:count] do
      Gettext.dngettext(
        MyAppWeb.Gettext,
        "errors",
        msg,
        msg,
        count,
        opts
      )
    else
      Gettext.dgettext(
        MyAppWeb.Gettext,
        "errors",
        msg,
        opts
      )
    end
  end
end

# Usage in LiveView
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <form phx-submit="save">
        <%= for error <- @errors do %>
          <p class="error"><%= error %></p>
        <% end %>

        <input type="email" name="email" value={@email} />
        <button type="submit"><%= gettext("Save") %></button>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"email" => email}, socket) do
    case Accounts.create_user(%{email: email}, socket.assigns.locale) do
      {:ok, _user} ->
        {:noreply, put_flash(socket, :info, gettext("User created successfully"))}

      {:error, changeset} ->
        errors = MyAppWeb.Helpers.translate_errors(changeset, socket.assigns.locale)

        socket =
          socket
          |> assign(:errors, Enum.flat_map(Map.values(errors), & &1))
          |> assign(:email, email)

        {:noreply, socket}
    end
  end
end
```

## Flash Message Translation

### Translated Flash Messages

```elixir
defmodule MyAppWeb.FlashTranslations do
  def translate_flash({:info, message}, locale \\ "en") do
    key = flash_message_key(message)
    {:info, Gettext.gettext(MyAppWeb.Gettext, key, locale)}
  end

  def translate_flash({:error, message}, locale \\ "en") do
    key = flash_message_key(message)
    {:error, Gettext.gettext(MyAppWeb.Gettext, key, locale)}
  end

  defp flash_message_key("User created successfully"), do: "user.created.success"
  defp flash_message_key("Invalid credentials"), do: "auth.invalid.credentials"
  defp flash_message_key(message), do: message
end

# Usage in LiveView
defmodule MyAppWeb.AuthLive do
  use MyAppWeb, :live_view

  @impl true
  def handle_event("login", params, socket) do
    case Accounts.login(params, socket.assigns.locale) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:current_user, user)
          |> put_flash(:info, gettext("Login successful"))

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid credentials"))}
    end
  end
end
```

## RTL (Right-to-Left) LiveView Support

### RTL-Aware LiveView

```elixir
defmodule MyAppWeb.RTL do
  def on_mount(:detect_rtl, _params, _session, socket) do
    locale = get_locale(socket)
    rtl? = rtl?(locale)
    text_direction = if rtl?, do: "rtl", else: "ltr"

    socket =
      socket
      |> assign(:rtl?, rtl?)
      |> assign(:text_direction, text_direction)

    {:cont, socket}
  end

  defp get_locale(socket), do: socket.assigns[:locale] || "en"

  defp rtl?(locale), do: locale in ["ar", "he", "fa", "ur"]
end

# Usage
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container" dir={@text_direction}>
      <header class="header">
        <%= if @rtl? do %>
          <div class="logo rtl-logo"></div>
        <% else %>
          <div class="logo"></div>
        <% end %>

        <nav class="nav">
          <%= gettext("Home") %>
          <%= gettext("About") %>
          <%= gettext("Contact") %>
        </nav>
      </header>

      <main class="main">
        <%= render_content(@rtl?) %>
      </main>
    </div>
    """
  end

  defp render_content(true) do
    ~H"""
    <div class="content-rtl">
      <%= gettext("Welcome to our Arabic website") %>
    </div>
    """
  end

  defp render_content(false) do
    ~H"""
    <div class="content">
      <%= gettext("Welcome to our website") %>
    </div>
    """
  end
end
```

## LiveView i18n Best Practices

### DO: Use Assigns for Locale

```elixir
# Good: Locale in assigns
defmodule GoodExample do
  def render(assigns) do
    ~H"""
    <h1><%= Gettext.gettext(MyAppWeb.Gettext, "Welcome", @locale) %></h1>
    """
  end
end

# Bad: Hard-coded locale
defmodule BadExample do
  def render(assigns) do
    ~H"""
    <h1><%= Gettext.gettext(MyAppWeb.Gettext, "Welcome", "en") %></h1>
    """
  end
end
```

### DO: Translate on Server Side

```elixir
# Good: Server-side translation
defmodule GoodExample do
  def handle_event("save", _params, socket) do
    {:noreply, put_flash(socket, :info, gettext("Saved successfully", socket.assigns.locale))}
  end
end

# Bad: Client-side translation
defmodule BadExample do
  def render(assigns) do
    ~H"""
    <button phx-click="save">
      <%= gettext("Save") %>
    </button>
    <script>
      // Don't translate on client side
      alert("<%= gettext("Saved successfully") %>");
    </script>
    """
  end
end
```

## Related Skills

- [Internationalization](../skills/internationalization/SKILL.md) - Comprehensive i18n guide
- [LiveView Patterns](../liveview.md) - LiveView best practices

## Related Patterns

- [i18n Patterns](../i18n_patterns.md) - General i18n patterns
- [Phoenix Controllers](../phoenix_controllers.md) - API-level i18n
