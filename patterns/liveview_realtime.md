# LiveView Real-Time Patterns

## Overview

Real-time patterns specifically for Phoenix LiveView applications.

## LiveView Streaming

### Streaming Large Datasets

```elixir
defmodule MyAppWeb.LogsLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, 1)
     |> assign(:total, 0)
     |> stream(:logs, [])}
  end

  def handle_event("load_more", %{"page" => page}, socket) do
    page = String.to_integer(page)

    # Fetch logs in chunks
    logs = MyApp.Logs.list_logs(page: page, per_page: 50)

    # Update stream
    socket =
      Enum.reduce(logs, socket, fn log, acc ->
        stream_insert(acc, :logs, log)
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="logs-container">
      <div id="logs" phx-update="stream">
        <%= for {id, log} <- @streams.logs do %>
          <div class="log-entry" id={id}>
            <span class="timestamp"><%= log.inserted_at %></span>
            <span class="level"><%= log.level %></span>
            <span class="message"><%= log.message %></span>
          </div>
        <% end %>
      </div>

      <button phx-click="load_more" phx-value-page={@page + 1}>
        Load More
      </button>
    </div>
    """
  end
end
```

## LiveView Live Actions

### Handle URL Changes Without Full Page Reload

```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  def handle_params(%{"id" => id}, _uri, socket) do
    case MyApp.Blog.get_post(id) do
      {:ok, post} ->
        {:noreply, assign(socket, :post, post)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :post, nil)}
  end

  def handle_event("next_post", _, socket) do
    next_id = socket.assigns.post.id + 1

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, __MODULE__, next_id)
     )}
  end

  def handle_event("previous_post", _, socket) do
    previous_id = max(socket.assigns.post.id - 1, 1)

    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, __MODULE__, previous_id)
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="post-container">
      <div class="navigation">
        <button phx-click="previous_post">Previous</button>
        <button phx-click="next_post">Next</button>
      </div>

      <%= if @post do %>
        <h1><%= @post.title %></h1>
        <div><%= @post.body %></div>
      <% else %>
        <p>No post selected</p>
      <% end %>
    </div>
    """
  end
end
```

## LiveView File Uploads

### Upload with Progress Tracking

```elixir
defmodule MyAppWeb.UploadLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:documents,
        accept: ~w(.pdf .doc .docx),
        max_entries: 5,
        max_file_size: 10_000_000
      )
     |> assign(:uploaded_files, [])}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :documents, ref)}
  end

  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :documents, fn %{path: path}, entry ->
        dest =
          Path.join(
            [Application.app_dir(:my_app), "priv", "static", "uploads"],
            entry.uuid
          )

        File.cp!(path, dest)
        {:ok, Routes.static_path(socket, "/uploads/#{entry.uuid}")}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def render(assigns) do
    ~H"""
    <div class="upload-container">
      <h1>Upload Documents</h1>

      <form id="upload-form" phx-submit="upload">
        <div class="file-dropzone">
          <.live_file_input upload={@uploads.documents} />

          <%= for entry <- @uploads.documents.entries do %>
            <div class="upload-progress">
              <div class="file-info">
                <span><%= entry.client_name %></span>
                <span><%= entry.progress %>%</span>
              </div>

              <progress value={entry.progress} max="100">
                <%= entry.progress %>%
              </progress>

              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
              >
                Cancel
              </button>
            </div>
          <% end %>
        </div>

        <button type="submit" disabled={@uploads.documents.entries == []}>
          Upload
        </button>
      </form>

      <div class="uploaded-files">
        <h2>Uploaded Files</h2>
        <ul>
          <%= for file <- @uploaded_files do %>
            <li>
              <a href={file} target="_blank">
                <%= Path.basename(file) %>
              </a>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
```

## LiveView Optimistic Updates

### Optimistic Form Submissions

```elixir
defmodule MyAppWeb.CommentLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "comments:#{socket.assigns.post_id}")

    {:ok,
     socket
     |> assign(:comments, [])
     |> assign(:pending_comments, [])}
  end

  def handle_event("submit_comment", %{"comment" => comment_params}, socket) do
    # Create pending comment for optimistic update
    temp_comment = %{
      id: nil,
      text: comment_params["text"],
      user: socket.assigns.current_user,
      inserted_at: DateTime.utc_now(),
      pending: true
    }

    # Optimistically update UI
    socket = update(socket, :pending_comments, &(&1 ++ [temp_comment]))

    # Send comment to server
    send(self(), {:create_comment, comment_params, temp_comment})

    {:noreply, socket}
  end

  def handle_info({:create_comment, comment_params, temp_comment}, socket) do
    case MyApp.Comments.create_comment(
           socket.assigns.post_id,
           socket.assigns.current_user.id,
           comment_params
         ) do
      {:ok, comment} ->
        # Remove temp comment, add actual comment
        pending =
          Enum.filter(
            socket.assigns.pending_comments,
            &(!(&1.pending && &1.text == temp_comment.text))
          )

        socket =
          socket
          |> assign(:pending_comments, pending)
          |> update(:comments, &(&1 ++ [comment]))

        {:noreply, socket}

      {:error, _changeset} ->
        # Remove temp comment on error
        pending =
          Enum.filter(
            socket.assigns.pending_comments,
            &(!(&1.pending && &1.text == temp_comment.text))
          )

        {:noreply, assign(socket, :pending_comments, pending)}
    end
  end

  def handle_info({:new_comment, comment}, socket) do
    {:noreply, update(socket, :comments, &(&1 ++ [comment]))}
  end

  def render(assigns) do
    ~H"""
    <div class="comments-container">
      <div class="comments">
        <%= for comment <- @comments do %>
          <div class="comment">
            <div class="comment-header">
              <span class="username"><%= comment.user.username %></span>
              <span class="timestamp"><%= comment.inserted_at %></span>
            </div>
            <div class="comment-body"><%= comment.text %></div>
          </div>
        <% end %>

        <%= for comment <- @pending_comments do %>
          <div class="comment pending">
            <div class="comment-header">
              <span class="username"><%= comment.user.username %></span>
              <span class="timestamp">Sending...</span>
            </div>
            <div class="comment-body"><%= comment.text %></div>
          </div>
        <% end %>
      </div>

      <form phx-submit="submit_comment">
        <textarea
          name="comment[text]"
          placeholder="Write a comment..."
          rows="3"
        ></textarea>
        <button type="submit">Submit</button>
      </form>
    </div>
    """
  end
end
```

## LiveView Pagination

### Cursor-Based Pagination

```elixir
defmodule MyAppWeb.FeedLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:cursor, nil)
     |> assign(:posts, [])
     |> assign(:has_more, true)}
  end

  def handle_event("load_more", _, socket) do
    # Load posts using cursor
    {posts, cursor, has_more} =
      MyApp.Feed.list_posts(
        cursor: socket.assigns.cursor,
        limit: 20
      )

    # Append posts to stream
    socket =
      Enum.reduce(posts, socket, fn post, acc ->
        stream_insert(acc, :posts, post)
      end)

    {:noreply,
     socket
     |> assign(:cursor, cursor)
     |> assign(:has_more, has_more)}
  end

  def render(assigns) do
    ~H"""
    <div class="feed-container">
      <div id="posts" phx-update="stream">
        <%= for {id, post} <- @streams.posts do %>
          <div class="post" id={id}>
            <h2><%= post.title %></h2>
            <p><%= post.body %></p>
          </div>
        <% end %>
      </div>

      <%= if @has_more do %>
        <button phx-click="load_more">
          Load More
        </button>
      <% else %>
        <p>No more posts</p>
      <% end %>
    </div>
    """
  end
end
```

## LiveView Infinite Scroll

### Intersection Observer Integration

```elixir
defmodule MyAppWeb.InfiniteScrollLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "feed")

    # Initial load
    {posts, cursor} = MyApp.Feed.list_posts(limit: 20)

    {:ok,
     socket
     |> assign(:cursor, cursor)
     |> stream(:posts, posts)
     |> assign(:loading, false)}
  end

  def handle_event("load-more", _, socket) do
    if not socket.assigns.loading do
      socket = assign(socket, :loading, true)

      # Load more posts
      {posts, cursor} =
        MyApp.Feed.list_posts(
          cursor: socket.assigns.cursor,
          limit: 20
        )

      socket =
        Enum.reduce(posts, socket, fn post, acc ->
          stream_insert(acc, :posts, post)
        end)

      {:noreply,
       socket
       |> assign(:cursor, cursor)
       |> assign(:loading, false)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="infinite-scroll-container">
      <div id="posts" phx-update="stream">
        <%= for {id, post} <- @streams.posts do %>
          <div class="post" id={id}>
            <h2><%= post.title %></h2>
            <p><%= post.body %></p>
          </div>
        <% end %>
      </div>

      <div id="load-more-trigger" phx-hook="InfiniteScroll">
        <%= if @loading do %>
          <div class="loading">Loading...</div>
        <% else %>
          <button phx-click="load-more">Load More</button>
        <% end %>
      </div>
    </div>

    <script>
      let Hooks = {
        InfiniteScroll: {
          mounted() {
            const observer = new IntersectionObserver(
              (entries) => {
                if (entries[0].isIntersecting) {
                  this.pushEvent("load-more", {});
                }
              },
              { rootMargin: "200px" }
            );

            observer.observe(this.el);
          }
        }
      };
    </script>
    """
  end
end
```

## Related Skills

- [Real-Time Patterns](../skills/realtime-patterns/SKILL.md) - Comprehensive real-time guide

## Related Patterns

- [LiveView Patterns](../liveview.md) - LiveView best practices
- [Real-Time Patterns](../realtime_patterns.md) - General real-time patterns
