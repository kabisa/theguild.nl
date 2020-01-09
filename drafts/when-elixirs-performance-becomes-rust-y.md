# Post title: When Elixir's performance becomes Rust-y

Elixir is a good language to develop fault tolerant and predictable performant systems. However, it lends itself worse to heavy computational demands. What can we do to improve this?

The post assumes basic Elixir knowledge. Rust knowledge is not required.

## The use case

In this use case, we want to calculate the prime numbers in the range of 1 up to 1 million. I'd like to show off something a bit more computation intensive than a simple addition of numbers, and also show that Elixir data types map well into Rust.

The code passes a list of numbers instead of just a integer denoting the maximum, to show off that data structures such as lists also translate fine between Elixir and Rust.

## Starting off with raw elixir

So let's start off with some coding! We'll start off with the Elixir implementation after making a new project. In this example the project is called `rust_nif`.

```Elixir
defmodule RustNif.ElixirPrimes do
  def prime_numbers(numbers) do
    prime_numbers(numbers, [])
  end

  def prime_numbers([], result) do
    {:ok, result |> Enum.reverse()}
  end

  def prime_numbers([number | rest], result) do
    new_result = result
    |> add_if_prime_number(number)

    prime_numbers(rest, new_result)
  end

  defp add_if_prime_number(numbers, 1), do: numbers

  defp add_if_prime_number(numbers, 2) do
    [2 | numbers]
  end

  defp add_if_prime_number(numbers, n) do
    case (numbers |> Enum.any?(fn x -> rem(n, x) == 0 end)) do
      false -> [n | numbers]
      _ -> numbers
    end
  end
end

time = Time.utc_now
elixir_task = Task.async(fn -> RustNif.ElixirPrimes.prime_numbers(Enum.into 1..1000000, []) end)
IO.inspect Task.await(elixir_task, :infinity)
IO.puts "Elixir task finished after #{Time.diff Time.utc_now, time} seconds"
```

Running this, the results on my machine were:

```
{:ok,
 [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
  157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, ...]}
Elixir task finished after 2288 seconds
:ok
```

Well, that's a bit on the long side. Surely we can do better than that.
Yes we can. The current implementation prepends each new prime number to the start of the list. This list is reversed in the end. See [list handling](http://erlang.org/doc/efficiency_guide/listHandling.html) as to why we do this.

Most likely, the first divisible number for non prime numbers will reside at the start of the list (the number 2 comes to mind). So let's start our `any?` comparison at the reverse of the list.

```Elixir
defp add_if_prime_number(numbers, n) do
  # Enum.reverse() is added
  case (numbers |> Enum.reverse() |> Enum.any?(fn x -> rem(n, x) == 0 end)) do
    false -> [n | numbers]
    _ -> numbers
  end
end
```

After this change, the results are

```
time = Time.utc_now
elixir_task = Task.async(fn -> RustNif.ElixirPrimes.prime_numbers(Enum.into 1..1000000, []) end)
IO.inspect Task.await(elixir_task, :infinity)
IO.puts "Elixir task finished after #{Time.diff Time.utc_now, time} seconds"

{:ok,
 [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
  157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, ...]}
Elixir task finished after 328 seconds
:ok
```

Well that's a lot better! But it's still quite long.

## So what are our alternatives?

### Ports & Nifs

There's a good summary of ports and nifs here: https://spin.atomicobject.com/2015/03/16/elixir-native-interoperability-ports-vs-nifs/

In short:

Ports:
+ Safety
+ Error trapping
+ Flexible communication
+ No external erlang/elixir specific libraries required
- Communication via STDIN and STDOUT

NIFS:
+ Fast and simple implementationn
+ No context switch required
+ Simple debugging
- Not very safe
- NIF-specific C libraries
- Native implementation can leak into Elixir code

### (Web) service

We could define a separate web service, exposing an API that could handle this, in a language better suited for this. We'd need to add a new service to our stack though, and also account for potential network failures and sending potentially large payloads.

### Background job

Depending on the case, this time would be fine and could perhaps be moved into a background task. But for this example, this will not do.

### Summary

A NIF looks nice at a glance, but we'd need to eliminate the risk of the NIF being able to crash the beam VM. But what if I told you that we can do that?

## Introducing Rust

This is where Rust comes in. Rust is a low level language, like C, developed by Mozilla. It's designed to provide better memory safety than C does, while also maintaining solid performance.

There's a library which allows creating Elixir/Erlang NIF's which make use of Rust, called [rustler](https://github.com/rusterlium/rustler). One of its main features is that its safety should prevent the Beam from crashing if something unexpected happens. In the meanwhile, we get to leverage Rust's performance in our Elixir apps!

### Writing the Rust code

Disclaimer: I don't have much prior knowledge with Rust, I'm sure this code can be improved. We have to start somewhere!

We'll go through the code piece by piece, the total solution will be posted below.

The first thing we need to do is add rustler to the project, so let's do that!
Let's add `{:rustler, "~> 0.21.0"}`, to our dependencies in `mix.exs` and install it with `mix deps.get`.

That'll allow us to run `mix rustler.new`. Let's call our module `PrimeNumbers` (which will call the rust crate `primenumbers` by default, which is fine).

We'll also need to add rustler as compiler in the project, and define our Rust crate.

```Elixir
def project
  [
    compilers: [:rustler, :phoenix, :gettext] ++ Mix.compilers(),
    rustler_crates: [
      primenumbers: []
    ],
    ... # other project options
  ]
```

Let's start writing the Rust code! there will be a rust file at `native/primenumbers/src/lib.rs`, which looks like this currently:

```Rust
use rustler::{Encoder, Env, Error, Term};

mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler::rustler_export_nifs! {
    "Elixir.PrimeNumbers",
    [
        ("add", 2, add)
    ],
    None
}

fn add<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let num1: i64 = args[0].decode()?;
    let num2: i64 = args[1].decode()?;

    Ok((atoms::ok(), num1 + num2).encode(env))
}
```

The first statement imports the Encoder, Env, Error and Term types from rustler, so we can make use of them.
The atoms section declares atoms which will map to Elixir's :ok annd :error atoms, so we can provide an interface similar to elixir.

methods defined in the `rustler::rustler_export_nifs!` statement are made available to Elixir, in the PrimeNumbers module. In the example, add is exported and defined with an arity of 2.

The add function decodes the arguments that are provided, adds them together and yields them back to Elixir as `{:ok, <result>}`. (Although I won't dive deeper into it, rustler makes this possible by implementing the [External Term Format](http://erlang.org/doc/apps/erts/erl_ext_dist.html)).

So let's modify that so we can get us some prime numbers.

```Rust
use rustler::{Encoder, Env, Error, Term};

mod atoms {
    rustler::rustler_atoms! { // <- We actually prefixed this with rustler! it's a small oversight in the template generation. see https://github.com/rusterlium/rustler/issues/260
        atom ok;
        atom error;
    }
}
```

The first part remains the same, we'll declare the ok and error atoms for use with Elixir.

```Rust
rustler::rustler_export_nifs! {
    "Elixir.RustNif.PrimeNumbers",
    [
        ("prime_numbers", 1, prime_numbers)
    ],
    None
}
```

We'll define a `prime_numbers` method with an arity of 1 to be exported.

```Rust
fn is_prime_number(numbers: &Vec<i64>, x: i64) -> bool {
    if x == 1 {
        false
    } else if x == 2 {
        true
    } else {
        !numbers.iter()
          .any(|&num| x % num == 0)
    }
}
```

We'll define a method to define whether a number is a prime number. It'll be supplied the current list of prime numbers we know, and the number we want to check. We'll define 1 and 2 as separate cases to allow a starting point for us.

```Rust
fn prime_numbers<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let is_list: bool = args[0].is_list();

    if !is_list {
      Ok((atoms::error(), "No list supplied").encode(env))
    } else {
      let numbers: Vec<i64> = args[0].decode()?;
      let mut vec = Vec::new();

      for number in numbers {
          if is_prime_number(&vec, number) {
              vec.push(number)
          }
      }

      Ok((atoms::ok(), &*vec).encode(env))
    }
}
```

We can use the same function signature that the example add function used (note the <'a> are [lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html), not generics or similar).

In this case we will verify whether the first argument is a list, and stop the function and yield `{:error, "No list suppled"}` if it's not.

Afterwards, we use rustler's `decode()` method to convert the data type into a Vec of `i64`. We'll make a mutable Vec (you need to specify mutability explicitely in Rust), and loop through the numbers to determine the prime number.

### Glueing Elixir and Rust together

We'll need a module in Elixir that will be the interface to the Rust code.

```Elixir
# prime_numbers.ex
defmodule RustNif.PrimeNumbers do
  use Rustler, otp_app: :rust_nif, crate: :primenumbers

  # Overriden when module is loaded
  def prime_numbers(_nums), do: :erlang.nif_error(:nif_not_loaded)
end
```

We define the OTP app we use, and the Rust crate we're loading, and that's it essentially.

## Comparison of performance

Now that we have both the Elixir and Rust(Elixir) versions of the code, let's compare them on their execution speed!

```Elixir
defmodule NaiveBenchmark do
  def benchmark_elixir do
    time = Time.utc_now
    elixir_task = Task.async(fn -> RustNif.ElixirPrimes.prime_numbers(Enum.into 1..1000000, []) end)
    IO.inspect Task.await(elixir_task, :infinity)
    IO.puts "Elixir task finished after #{Time.diff Time.utc_now, time} seconds"
  end

  def benchmark_rust do
    time = Time.utc_now
    rust_task = Task.async(fn -> RustNif.PrimeNumbers.prime_numbers(Enum.into 1..1000000, []) end)
    IO.inspect Task.await(rust_task, :infinity)
    IO.puts "Rust task finished after #{Time.diff Time.utc_now, time} seconds"
  end
end

iex(1)> NaiveBenchmark.benchmark_elixir
{:ok,
 [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
  157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, ...]}
Elixir task finished after 328 seconds
:ok

{:ok,
 [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
  157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, ...]}
Rust task finished after 29 seconds
```

Well that's quite a lot better!

## Do other people do this?

Yes! An example of a company having this setup is Discord, see [Using Rust to Scale Elixir for 11 Million Concurrent Users](https://blog.discordapp.com/using-rust-to-scale-elixir-for-11-million-concurrent-users-c6f19fc029d3)

## Conclusion

Let me preface the conclusion by stating you shouldn't just introduce Rust in your Elixir stack like this because you think you'll need it.

It's great to see the ease in which a low level, but safe language such as Rust, can be added to our stack to overcome one of Elixir's weaker points with relative ease.

I'm sure both implementations can be further refined. The point that I want to make is that it's easy to resort to a more performant language when need does arise.

## The full code samples

```Elixir
# elixir_primes.ex
defmodule RustNif.ElixirPrimes do
  # http://erlang.org/doc/efficiency_guide/listHandling.html
  def prime_numbers(numbers) do
    prime_numbers(numbers, [])
  end

  def prime_numbers([], result) do
    {:ok, result |> Enum.reverse() }
  end

  def prime_numbers([number | rest], result) do
    new_result = result
    |> add_if_prime_number(number)

    prime_numbers(rest, new_result)
  end

  defp add_if_prime_number(numbers, 1), do: numbers

  defp add_if_prime_number(numbers, 2) do
    [2 | numbers]
  end

  defp add_if_prime_number(numbers, n) do
    case (numbers |> Enum.reverse() |> Enum.any?(fn x -> rem(n, x) == 0 end)) do
      false -> [n | numbers]
      _ -> numbers
    end
  end
end
```

```Elixir
# prime_numbers.ex
defmodule RustNif.PrimeNumbers do
  use Rustler, otp_app: :rust_nif, crate: :primenumbers

  # Overriden when module is loaded
  def prime_numbers(_nums), do: :erlang.nif_error(:nif_not_loaded)
end
```

```Rust
// lib.rs
use rustler::{Encoder, Env, Error, Term};

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
    }
}

rustler::rustler_export_nifs! {
    "Elixir.RustNif.PrimeNumbers",
    [
        ("prime_numbers", 1, prime_numbers)
    ],
    None
}

fn is_prime_number(numbers: &Vec<i64>, x: i64) -> bool {
    if x == 1 {
        false
    } else if x == 2 {
        true
    } else {
        !numbers.iter()
          .any(|&num| x % num == 0)
    }
}

fn prime_numbers<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let is_list: bool = args[0].is_list();

    if !is_list {
      Ok((atoms::error(), "No list supplied").encode(env))
    } else {
      let numbers: Vec<i64> = args[0].decode()?;
      let mut vec = Vec::new();

      for number in numbers {
          if is_prime_number(&vec, number) {
              vec.push(number)
          }
      }

      Ok((atoms::ok(), &*vec).encode(env))
    }
}
```