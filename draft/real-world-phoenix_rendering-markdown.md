# Rendering Markdown

Recently, I acquired the domain `realworldphoenix.com` in order to continue my blogging adventure on a separate blog dedicated to writing exclusive content on Phoenix and Elixir (and some related subjects occassionally). I could of course take an off the shelf blogging platform or just use some kind of static site generator. But as I am writing about using Phoenix in the Real World, I figured why not just create a Phoenix application to host my blog. Then I can also do some nice things like make it a bit interactive or even let people sign-up and comment without using a third-party tool for that. We'll see.

## Writing content for a blog.

As most of you would probably agree, writing long-form content using html is a bit of a pain. So most people use markdown to write blogposts and I'm no exception. So let's find out how we can write markdown, put it under version control (just because that is nice to have) and then make sure it gets rendered as html in our Phoenix app.

## Earmark

The go-to way to convert markdown to html in Elixir land is the great library written by Dave Thomas, [Earmark](https://github.com/pragdave/earmark). It is used by [ex_doc](https://github.com/elixir-lang/ex_doc) and is a nice and well maintained library. We could of course convert our markdown in our phoenix controller directly using Earmark and output that in our view, but we can do even better. We can make sure that our Phoenix app can actually render markdown files stored in our template directly to html, just like it render's `eex` to html.

## Phoenix Markdown Library

In fact there is even a library that handles this for us: [Phoenix Markdown](https://github.com/boydm/phoenix_markdown). Now I can just use this and be done with it (and as you are reading this... I am actually already using it ;) ), but my curious mind wants to know more! I'd like to know how this mechanism works so I have a better understanding of how rendering works in Phoenix. So, without further ado, let's crack this baby open and take a look inside. Ooohhh what is that....?

## It's a Template Engine!

Ofcourse, Phoenix has this all figured out. The way that `eex` and `exs` are implemented is as Phoenix Template Engines. It is fairly straightforward to create your own Template Engine by implementing the `Phoenix.Template.Engine` behaviour. This is exactly what [Boyd Multerer](https://github.com/boydm) has created in his library [phoenix_markdown](https://github.com/boydm/phoenix_markdown). Does that name sound familiar? Oh, that's because boyd was also the creator of the awesome [Scenic Library](https://github.com/boydm/scenic). Great stuff!

## How do we create a Template Engine?

So how does one go about and create a template engine? Well, the best way to find out is to see if we can create one for ourselves, right? So let's create a template engine that scrambles all the text that gets rendered by the engine. We'll use the `Cambridge University Scrambled Text` concept. So scramble all letters in words but keep the first and last letters intact. Fun fact, this so-called research was actually never done at Cambridge University! Somehow this internet meme got morphed into being a Cambridge research subject, but was actually never the case. Here's a [nice article](https://www.mrc-cbu.cam.ac.uk/people/matt.davis/cmabridge/) from a Cambridge Professor about this.
This however doesn't hold us back from using the concept to build our awesome scramble engine! So let's get cakrcnig!

## Our scramble Engine

If you want to follow along you can create a fresh phoenix project and put the files in there to test this out yourself.
We'll define our engine in `lib/engine/scrambled.ex`. The `Phoenix.Template.Engine` behaviour requires us to implement `compile/2`. In there we can add our magic formula. :)

This is what I came up with for our use case:

```elixir
defmodule RealWorldPhoenix.Engines.Scrambled do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  def compile(path, _name) do
    path
    |> File.read!()
    |> scramble_words()
    |> Earmark.as_html!()
    |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)
  end

  defp scramble_words(content) do
    content
    |> String.split("\n", trim: true)
    |> Enum.map(&shuffle_words_in_sentence/1)
    |> Enum.join("\n")
  end

  defp shuffle_words_in_sentence(sentence) do
    sentence
    |> String.split(" ")
    |> Enum.map(&shuffle/1)
    |> Enum.join(" ")
  end

  defp shuffle(word) do
    scrambled =
      word
      |> String.split("", trim: true)
      |> Enum.slice(1..-2)
      |> Enum.shuffle()
      |> Enum.join("")

    String.first(word) <> scrambled <> String.last(word)
  end
end
```

And to use this in our Phoenix app, we need to configure the file extension we want to invoke scrambling for. You can see this is the same as I did in my app to configure `phoenix_markdown`. At compile time Phoenix will match any templates with the `.scrambled` extension and will run that source file through our Engine by calling our `compile/2` function defined in our Engine module.

```elixir
# config/config.exs

config :phoenix, :template_engines,
  md: PhoenixMarkdown.Engine,
  scrambled: RealWorldPhoenix.Engines.Scrambled
```

So I am expecting this to scramble content written in markdown. I'm just considering paragraphs of text, just to not complicate things unnecessarily for this use case. That is why I am basically splitting sentences by splitting on the newline character and then processing each sentence and the containing words before joining them together again with newlines. Seems pretty straightforward. Let's see if this works!

## Smartypants... 🤔

Phoenix Markdown has an option to render server_tags, which basically means that you can invoke Elixir inside your markdown page using the standard tags you use in `eex` templates to invoke some Elixir code and evaluate it. I wanted to use this to render the following bit of text to illustrate my `scrambled` engine, but the first pass led to this error while compiling:

```bash
== Compilation error in file lib/real_world_phoenix_web/views/post_view.ex ==
** (SyntaxError) lib/real_world_phoenix_web/templates/post/blogs/2020-01-28/rendering_markdown.html.md:60: unexpected token: "“" (column 39, code point U+201C)
    (eex) lib/eex/compiler.ex:45: EEx.Compiler.generate_buffer/4
    (phoenix) lib/phoenix/template.ex:361: Phoenix.Template.compile/3
    (phoenix) lib/phoenix/template.ex:167: anonymous fn/4 in Phoenix.Template."MACRO-__before_compile__"/2
    (elixir) lib/enum.ex:1948: Enum."-reduce/3-lists^foldl/2-0-"/3
    (phoenix) expanding macro: Phoenix.Template.__before_compile__/1
    lib/real_world_phoenix_web/views/post_view.ex:1: RealWorldPhoenixWeb.PostView (module)
    (elixir) lib/kernel/parallel_compiler.ex:229: anonymous fn/4 in Kernel.ParallelCompiler.spawn_workers/7
```
What? 😕🤷

Ok, so what is happening here. It is seeing an unexpected token and it seems to be a left handed double quote. After banging my head against the wall for about a day, I decided to `rtfm` again and luckily Boyd has us covered. See [here](https://github.com/boydm/phoenix_markdown#unexpected-token-in-server-tags), and I'll quote it below:

_By default Earmark replaces some characters with prettier UTF-8 versions. For example, single and double quotes are replaced with left- and right-handed versions. This may break any server tag which contains a prettified character since EEx cannot interpret them as intended. To fix this, disable smartypants processing._

So it is actually a simple fix in our config:
```elixir
config :phoenix_markdown, :earmark, %{
  smartypants: false
}
```
## Interactive blog...

The example below is rendered using LiveView. You can see this if you head over to my [interactive blog](http://realworldphoenix.com/blog/2020-01-28/rendering_markdown#scramble).

```elixir
<%= Phoenix.LiveView.Helpers.live_render(@conn, RealWorldPhoenixWeb.Live.Scrambled) %>
```

And here is the LiveView component responsible for rendering the scambled text:
```elixir
defmodule RealWorldPhoenixWeb.Live.Scrambled do
  use Phoenix.LiveView
  @moduledoc false

  def render(assigns) do
    ~L"""
      <h2 id="scramble">Let's Scramble!
        <button phx-click="scramble" class="button">
          <%= if @scrambled, do: "un-scramble", else: "scramble" %>
        </button>
      </h2>
      <%= get_scrambled_content(@scrambled) %>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, :scrambled, true)}
  end

  def handle_event("scramble", _value, socket) do
    {:noreply, assign(socket, :scrambled, !socket.assigns.scrambled)}
  end

  defp get_scrambled_content(true) do
    Phoenix.View.render(RealWorldPhoenixWeb.PostView, "blogs/2020-01-28/_scrambled.html", [])
  end

  defp get_scrambled_content(false) do
    Phoenix.View.render(RealWorldPhoenixWeb.PostView, "blogs/2020-01-28/_notscrambled.html", [])
  end
end
```

## Hold on buddy! This can't work!

The above LiveView renders scrambled text and when the button is pressed it unscrambles it.

Ah I was wondering if you would notice. You smartypants out there probably were already wondering how in the world I get this `scrambling` functionality working. No, I'm not fooling you, it is running though our actual template engine. But indeed Phoenix pre-compiles the templates. That is also one of the reasons it is so fast.

So it is not running through our template when you press that button. I confess. I have two versions of the same file it switches between, one with the `.scrambled` extension and one without that are both precompiled by Phoenix when the app gets compiled. You will notice that the scrambling is also the same if you switch back and forth. That is because, once compiled, it does not recompile necessarily.


## Conclusion

Although my Scrambled Engine might not be so useful, I think it does illustrate how easy it can be to create a Template Engine that does something small and works pretty quickly out of the box.

Be sure to check out the Core Example [EEx Engine](https://hexdocs.pm/eex/EEx.html) if you want to dive in some more. And be sure to read the awesome docs about [templating in Phoenix](https://hexdocs.pm/phoenix/Phoenix.Template.html#content)!

I hope this was helpful and that you learned something new.

Until next time!