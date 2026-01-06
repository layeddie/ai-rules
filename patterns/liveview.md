# Phoenix LiveView Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: Hanso Group + Hex Shift (Medium) + LogRocket + Phoenix LiveView 1.1 release notes

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Building Phoenix LiveView applications
- Optimizing LiveView performance at scale
- Designing reusable LiveComponents
- Handling real-time updates efficiently

❌ **DON'T use this file when**:
- Building single-page applications with JavaScript frameworks
- Using REST APIs without real-time requirements
- Simple static pages without interactivity

**See also**:
- `phoenix_controllers.md` - Controller patterns
- `concurrent_tasks.md` - Offloading long-running tasks
- `error_handling.md` - Error handling in LiveViews

---

## Pattern 1: Offloading Long-Running Tasks

**Problem**: CPU-intensive operations block LiveView process, freezing UI

✅ **Solution**: Use Task.async for background work

```elixir
defmodule ReportLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :start_report_generation)
    end
    {:ok, assign(socket, :generating, false)}
  end

  def handle_info(:start_report_generation, socket) do
    {:noreply, assign(socket, :generating, true)}
  end

  def handle_info({:report_ready, url}, socket) do
    {:noreply, assign(socket, :generating, false, :report_url, url)}
  end
end
```

**Reference**: Hex Shift Medium - "Offloading Long-Running Tasks in Phoenix LiveView: Keeping Your UI Responsive" (2025)

---

## Pattern 2: Optimistic UI Updates

**Problem**: Users wait for slow server operations

✅ **Solution**: Update UI immediately, complete later

```elixir
defmodule TodoLive do
  use MyAppWeb, :live_view

  def handle_event("add_item", %{"item" => item_params}, socket) do
    socket
    |> put_flash(:info, "Adding item...")
    |> assign(:adding, true)
    |> noreply()

    Task.start(fn ->
      case MyApp.Todos.create_item(item_params) do
        {:ok, item} ->
          send(self(), {:item_added, item})
        {:error, reason} ->
          send(self(), {:item_add_failed, reason})
      end
    end)
  end

  def handle_info({:item_added, item}, socket) do
    socket
    |> clear_flash()
    |> assign(:adding, false)
    |> update(:items, fn items -> [item | items])
    |> noreply()
  end
end
```

**Reference**: Hex Shift - "Phoenix LiveView Patterns That Scale" (2025)

---

## Pattern 3: Streaming Large Lists with LiveComponents

**Problem**: N+1 queries for nested relationships

✅ **Solution**: Preload data once, use stream: [] attribute

```elixir
defmodule UserListLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    departments = MyApp.Departments.list_all()
    departments_by_id = Map.new(departments, &{&1.id, &1})
    
    users = MyApp.Users.list_with_departments()
    
    {:ok, 
      socket
      |> assign(:departments_by_id, departments_by_id)
      |> assign(:users, users)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={UserItemComponent}
      stream={@users}
      departments_by_id={@departments_by_id}
    />
    """
  end
end

defmodule UserItemComponent do
  use Phoenix.LiveComponent

  attr :user, :map, required: true
  attr :departments_by_id, :map, required: true

  def render(assigns) do
    ~H"""
    <div>
      <%= @user.name %>
      <%= @departments_by_id[@user.department_id].name %>
    </div>
    """
  end
end
```

**Reference**: Hanso Group - "Phoenix LiveView Best Practices" (2025)

---

## Pattern 4: LiveComponent Reusability

**Problem**: Duplicated component code across LiveViews

✅ **Solution**: Create reusable LiveComponents

```elixir
defmodule MyAppWeb.Components do
  use Phoenix.Component

  def modal(assigns) do
    ~H"""
    <div class="modal">
      <div class="modal-header">
        <%= @title %>
      </div>
      <div class="modal-body">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def button(assigns) do
    ~H"""
    <button phx-click={@on_click} class={@variant}>
      <%= @text %>
    </button>
    """
  end
end

defmodule MyLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.modal title="Confirm" on_click="confirm">
      <p>Are you sure?</p>
      <:inner_block>
        <.button variant="danger" on_click="confirm_delete">Delete</.button>
      </:inner_block>
    </.modal>

    <.button variant="primary" on_click="show_details">View Details</.button>
    """
  end
end
```

**Reference**: Hex Shift - "Advanced LiveComponent Architecture in Phoenix LiveView" (2025)

---

## Pattern 5: File Uploads with LiveView

**Problem**: Uploading files with progress tracking

✅ **Solution**: Use consume_uploaded_entries

```elixir
defmodule UploadLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg), max_entries: 2)
     |> assign(:uploaded_files, [])}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path, entry: entry} ->
        dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path))
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    {:noreply, update(socket, :uploaded_files, uploaded_files)}
  end
end
```

**Reference**: Hex Shift - "How to Add Drag and Drop File Uploads in Phoenix LiveView Without JavaScript Frameworks" (2025)

---

## Pattern 6: Client-Side Information in Hooks

**Problem**: LiveView 1.1 supports client-side hooks without separate files

✅ **Solution**: Use phx-hook with collocated hooks (LiveView 1.1+)

```elixir
defmodule LocationLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :request_location)
    end
    {:ok, assign(socket, :location, nil)}
  end

  def handle_info({:location, lat, long}, socket) do
    {:noreply, assign(socket, :location: %{lat: lat, long: long})}
  end
end

defmodule MyAppWeb.LocationHook do
  use Phoenix.LiveView.JS

  @impl true
  def on_mount(:default, _params, _session, socket) do
    send(socket, {:get_location})
    {:cont, socket}
  end

  def handle_event({:location_received, %{lat: lat, long: long}}, socket) do
    {:cont, assign(socket, :location: %{lat: lat, long: long})}
  end
end
```

**Reference**: DockYard - "Implementing a Client Hook in LiveView" (2025)

---

## Pattern 7: Loading States and Skeleton UI

**Problem**: Show loading state during async operations

✅ **Solution**: Assign loading state, show skeleton UI

```elixir
defmodule DataLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :loading, true, :data, nil)}
  end

  def handle_info(:data_loaded, data, socket) do
    {:noreply, assign(socket, :loading, false, :data, data)}
  end

  def render(assigns) do
    ~H"""
    <%= if @loading do %>
      <div class="loading-spinner">Loading...</div>
    <% else %>
      <.data_table data={@data} />
    <% end %>
    """
  end
end
```

**Reference**: Hanso Group - "Phoenix LiveView Best Practices" (2025)

---

## Pattern 8: Real-time Updates with PubSub

**Problem**: Updating UI when data changes in background

✅ **Solution**: Use Phoenix.PubSub for broadcast events

```elixir
defmodule DashboardLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "stats:update")
    end
    {:ok, assign(socket, :stats, %{})}
  end

  def handle_info({:stats_update, new_stats}, socket) do
    {:noreply, assign(socket, :stats, new_stats)}
  end
end

defmodule StatsWorker do
  use GenServer

  def update_metrics(new_stats) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, {:stats_update, new_stats})
  end
end
```

**Reference**: Phoenix LiveView 1.1 release notes (2025)

---

## Pattern 9: Error Handling in LiveViews

**Problem**: Displaying errors to users

✅ **Solution**: Use put_flash for user feedback

```elixir
defmodule FormLive do
  use MyAppWeb, :live_view

  def handle_event("submit", %{"user" => user_params}, socket) do
    case MyApp.Users.create(user_params) do
      {:ok, user} ->
        socket
        |> put_flash(:info, "User created successfully")
        |> redirect(to: ~p"/users/#{user.id}")

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Failed to create user")
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end
end
```

**Reference**: `error_handling.md` - Tuple patterns and error handling

---

## Testing Patterns for This File

### Unit Testing LiveComponents

```elixir
defmodule ButtonComponentTest do
  use Phoenix.ComponentCase
  import Phoenix.LiveViewTest

  test "renders button with text" do
    html = render_component(&Button.button, text: "Click Me", on_click: "clicked")

    assert has_element?(html, "button", "phx-click", "clicked")
    assert text_content(html, "button") =~ "Click Me"
  end
end
```

### Integration Testing LiveViews

```elixir
defmodule UserListLiveTest do
  use MyAppWeb, :live_view
  use MyAppWeb.ConnCase

  test "renders list of users", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/users")

    assert has_element?(html, ".user-list")
  end

  test "creates new user", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/users/new")

    view
    |> form("#user-form")
    |> render_change(%{"user[name" => "Test User"})
    |> render_change(%{"user[email" => "test@example.com"})

    view
    |> element("button[phx-click=\"save\"]")
    |> render_click()

    assert has_element?(view, ".user-item[name=\"Test User\"]")
  end
end
```

---

## References

**Primary Sources**:
- Hanso Group - "Phoenix LiveView Best Practices" (2025-04-10)
- Hex Shift - "Phoenix LiveView Patterns That Scale: Proven Architectures for Real-Time Applications" (2025-08-12)
- Hex Shift - "Optimizing Phoenix LiveView Performance at Scale" (2025-05-30)
- Hex Shift - "Advanced LiveComponent Architecture in Phoenix LiveView" (2025-06-09)
- Hex Shift - "Offloading Long-Running Tasks in Phoenix LiveView" (2025-06-10)
- Phoenix LiveView 1.1 Release Notes

**Related Patterns**:
- `phoenix_controllers.md` - Controller patterns
- `concurrent_tasks.md` - Offloading patterns
- `error_handling.md` - Error handling in LiveViews
- `liveview-patterns/SKILL.md` - Comprehensive LiveView guide

**Community**:
- Phoenix Framework documentation
- Phoenix LiveView documentation
- Hanso Group best practices
