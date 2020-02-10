# Using Phoenix Presence in LiveView |> A Simple Example

Normally I'm not a big fan of things that seem like magic, but in the case of Phoenix Presence I actually love it. I love the way you can very simply add Phoenix Presence to your Phoenix app and you suddenly get tracking info on who's online at any given time. Amazing! I will definitely dig into the internals at some point in the future, but for now I wanted to show a very simple example of using Phoenix Presence inside LiveView!

Let's see how that would work.

## Who's reading?

We are going to build a very simple but powerful feature for the blog you are currently reading. We will add an indicator at the top of the page that shows how many people are currently reading this page. So where do we want this indicator? Preferable this would reside on the same page as a blog post so that it would indicate for every individual blog post how many users are currently reading that article. To do this, we'll create a very small LiveView component inserted in the markdown of our post. Just like we did in my [last post](https://realworldphoenix.com/blog/2020-01-28/rendering_markdown) when I rendered scrambled text. At a later stage I will probably want to make it more generic, but for now let's focus on getting this to work for this blog post.

If you head over to my [interactive blog](https://realworldphoenix.com/blog/2020-02-11/simple_phoenix_presence), you can see this counter in action!

## LiveView or LiveView Component?

LiveView is maturing quickly and currently also has a concept of Components. Which basically are small building blocks that either are stateful or stateless. I am definitely planning on doing a writeup on using LiveView components, but for our usecase we simply need the basic LiveView.

Let's create a basic LiveView boilerplate:

```elixir
defmodule RealWorldPhoenixWeb.Live.ReaderCount do
  use Phoenix.LiveView

  @moduledoc """
    A small LiveView that shows the number of readers of a post using Phoenix Presence
  """

  def render(assigns) do
    ~L"""
      Readers: <\%= @reader_count %>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, :reader_count, 0)}
  end
end
```

Ok, so now we need to hook up Presence. Let's see how that would work. First we'll head over to the [docs](https://hexdocs.pm/phoenix/Phoenix.Presence.html) and see how it is setup. The first thing I notice is this: _Provides Presence tracking to processes and channels._. We are not really using Channels, but our LiveView is a process so I guess that should work, right?

## Presence Setup

Let's first setup Presence using the guide provides by the Phoenix Team:

### 1. Setup a Presence Module in our app:

```elixir
defmodule RealWorldPhoenix.Presence do
  use Phoenix.Presence, otp_app: :real_world_phoenix,
                        pubsub_server: MyApp.PubSub
end
```

### 2.  Add this module to our supervision tree:

```elixir
# lib/real_world_phoenix/application.ex

defmodule RealWorldPhoenix.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      RealWorldPhoenix.Repo,
      RealWorldPhoenixWeb.Endpoint,
      RealWorldPhoenix.Presence # <= Add This!
    ]

    opts = [strategy: :one_for_one, name: RealWorldPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    RealWorldPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

## I don't have any Channels... ?

So the next and last step in the guide shows an example of adding Presence tracking to a channel implementation. But we are not using channels! So how do we go about and add this to our LiveView. Presence uses a PubSub (Publish-Subscribe) mechanism to perform it's magic. So what we should do in our LiveView is make sure we subscribe to the topic of the current page. Once we do that we can add a callback that will track any presence_diff where we will update the counter if someone leaves or joins the current topic.

In our `mount/2` function we'll subscribe to the page topic. Basically using a topic such as `blog:simple_phoenix_presence`. So in essence a general category with a post slug after the colon. Here are the updates to our LiveView module:

```elixir
defmodule RealWorldPhoenixWeb.Live.ReaderCount do
  ...

  @topic "blog:simple_phoenix_presence"

  def mount(_session, socket) do
    # before subscribing, let's get the current_reader_count
    initial_count = Presence.list(@topic) |> map_size

    # Subscribe to the topic
    RealWorldPhoenixWeb.Endpoint.subscribe(@topic)

    # Track changes to the topic
    Presence.track(
      self(),
      @topic,
      socket.id,
      %{}
    )

    {:ok, assign(socket, :reader_count, initial_count)}
  end
  # ...
end
```

## Track diff of topic

Now the only left for us to do is implement a callback in our live_view to catch any diffs happening on th etopic we are tracking. The folling function will do the trick:

```elixir
...
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{reader_count: count}} = socket
      ) do
    reader_count = count + map_size(joins) - map_size(leaves)

    {:noreply, assign(socket, :reader_count, reader_count)}
  end
...
```

We pattern match on the "presence_diff" event and also use pattern matching to get the current values for joins, leaves and count respectively. When someone subscribes to the topic, there will be change in the `joins` and when they leave a similar change in `leaves`. The `reader_count` is something we update ourselves in the socket whenever someone joins or leaves.

That is really all we need to do to get realtime updates of the number of readers of our page. That is quite easy and really cool to be able to see that data. Currently we don't ask user for information once they enter our blog, but once we add login or even just their name, we would be able to show that data as part of the presence_diff as well. But, let's leave that for another time.

## Conclusion

I hope that I showed you how easy it is to add Phoenix Presence to a LiveView component. I was pleasantly surprised as to how little effort this actually takes.

Hope you learned something new!

Until next time!