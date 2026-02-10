
Elixir Examples
All Examples

Get a value from nested maps

The get_in function can be used to retrieve a nested value in nested maps using a list of keys.

nested = %{ one: %{ two: 3} }

3 = get_in(nested, [:one, :two])

# Returns nil for missing value
nil = get_in(nested, [:one, :three])

Documentation:

    Kernel.get_in/2


Else if statement (See cond statement)

The cond keyword can be used like else if found in other languages. See cond statement

Switch statement (See case statement)

Elixir uses the keyword case instead of switch. See case statement

Sum an enumerable

This example shows how to sum a list, map, range, or other enumerable to calculate a total value.

# Enum.sum/1 for numeric values
 6 == Enum.sum([1, 2, 3])
 6 == Enum.sum(1..3)
 
 # reduce to extract/transform a value during sum
 6 = Enum.reduce(%{ a: 1, b: 2, c: 3 }, 0, fn({_k, v}, acc) -> v + acc end)

Documentation:

    Enum.sum/1
    Enum.reduce/3


Get a value from a struct

This example shows how to get a value from a struct field.

# Define a struct for this example
defmodule User do
  defstruct email: nil
end

# dot syntax
"c@c.com" = %User{email: "c@c.com"}.email

# Underlying implementation is a map
# So Map methods work
"c@c.com" = Map.get(%User{email: "c@c.com"}, :email)

# Pattern match to get a value
%{ email: email }   = %User{email: "c@c.com"}
%User{email: email} = %User{email: "c@c.com"}

# Access protocol not available by default
%User{email: "c@c.com"}[:email]
#** (UndefinedFunctionError) undefined function User.fetch/2 (User does not implement the Access behaviour)
#             User.fetch(%User{email: "c@c.com"}, :email)
#    (elixir) lib/access.ex:118: Access.fetch/2
#    (elixir) lib/access.ex:149: Access.get/3


# Enumerable protocol not available by default
Enum.filter( %User{email: "c@c.com"}, fn({key, _}) -> key == :email  end)
#** (Protocol.UndefinedError) protocol Enumerable not implemented for %User{email: "c@c.com"}
#    (elixir) lib/enum.ex:1: Enumerable.impl_for!/1
#    (elixir) lib/enum.ex:116: Enumerable.reduce/3
#    (elixir) lib/enum.ex:1477: Enum.reduce/3
#    (elixir) lib/enum.ex:742: Enum.filter/2

Documentation:

    Structs


Update a struct field

This example shows how to update a struct field.

# Define a struct for this example
defmodule User do
  defstruct email: nil
end

%User{email: "c@c.com"} = struct(%User{}, email: "c@c.com")

# Structs are based on maps
# so map update methods and syntax are valid
%User{email: "a@a.co"} = %{ %User{} | email: "a@a.co" }

%User{email: "b@b.com"} = Map.put(%User{}, :email, "b@b.com")

Documentation:

    Structs
    Kernel.struct/2


Get a value from a keyword list

This example shows different ways to get values from a keyword list.

# [] can be used, first match returned
1 = [a: 1, b: 2, a: 3][:a]

# [] missing value is nil
nil = [a: 1, b: 2, a: 3][:c]

# Keyword get also works
1 = Keyword.get([a: 1, b: 2, a: 3], :a)

# missing value is nil
nil = Keyword.get([a: 1, b: 2, a: 3], :c)

# an optional default value can be specified
# for missing keys
"missing" = Keyword.get([a: 1, b: 2, a: 3], :c, "missing")

# Keyword.take returns a list of matching pairs
[a: 1, a: 3] = Keyword.take([a: 1, b: 2, a: 3], [:a])

[] = Keyword.take([a: 1, b: 2, a: 3], [:c])

# dot syntax does NOT work
# results in compile error
[a: 1, b: 2, a: 3].a

Documentation: Keyword

Add a key and value to a map

Add a key and value to a map.

Map.put(%{a: 1}, :b, 2)
%{a: 1, b: 2}


Boolean operators - and, or, &&, ||

Elixir provides short-circuiting logical boolean operators and, or, &&, and ||. The and and or operators are said to be strict because they only accept booleans and return a boolean result. The pipes || and ampersands && are non-strict/relaxed and can take any value. The values false and nil are the only falsey values and everything else is true.

Use and or or when you have boolean inputs and want a boolean result.

false = false and true
true  = true  and true

true  = true  or false
false = false or false

# A non boolean argument results in an ArgumentError
"hello" and true

# || can be used to assign fallback/default values
"default" = nil || "default"

# short-circuted || result since left side being
# true makes it true
"first" = "first" || "second"

"second" = "first" && "second"
# short-circuted && result, left-side false value returned
false = false && "second"

Documentation: Basic Operators

Behaviours

Behaviours provide a way to define an interface which a module can implement. A module declares that it implements the Behaviour with the @behaviour annotation. The functions in the modules implementing the behaviour will be checked at compile time to see if they match the function specifications in the behavior.

# The @callback annotations below define function specifications that a
# module needs to implement the behaviour. The @callback parameter and
# return types must be specified or a compile error will occur.
defmodule Greeter do
  @callback say_hello(String.t) :: any
  @callback say_goodbye(String.t) :: any
end

# A module uses the @behaviour annotation to indicate
# that it implements a behaviour
defmodule NormalGreeter do
  @behaviour Greeter
  def say_hello(name), do: IO.puts "Hello, #{name}"
  def say_goodbye(name), do: IO.puts "Goodbye, #{name}"
end

defmodule ExcitedGreeter do
  @behaviour Greeter
  def say_hello(name), do: IO.puts "Hello, #{name}!!"
  def say_goodbye(name), do: IO.puts "Goodbye, #{name}!!"
end

# Since the following module does not implement say_goodbye/1
# a compile time warning will occur:
# "warning: undefined behaviour function say_goodbye/1 (for behaviour Greeter)"
defmodule InvalidGreeter do
  @behaviour Greeter
  def say_hello(name), do: IO.puts "Hello, #{name}."
end

Documentation: Behaviours

Phoenix Framework from HTTP Request to Response

This post describes the steps that a HTTP request/response takes in a Phoenix Framework application. The example application described here was generated using the command mix phoenix.new hello_world.

The steps in the HTTP request/response cycle are outlined as follows:

    HTTP Request
    Cowboy
        Plug
            Phoenix Endpoint
                Phoenix Router
                Phoenix Controller
                Phoenix View
                Phoenix Template
    HTTP Response

HTTP Request

A browser user sends an HTTP GET request to http://localhost:4000/.

The request is received by the Cowboy server.
Cowboy

Cowboy is an Erlang based HTTP server which is currently the only server with a Plug adapter implemented.

Cowboy will parse the HTTP request and the first Plug Connection will be created in Plug’s Cowboy adapter.
Plug

Plug is a web server interface for Elixir that provides a way to compose modules in a sequence during a request/response cycle.

Each plug module receives the HTTP request which is called a Plug Connection and often referred to as the variable conn. The plug may transform and update the connection and then return an HTTP response immediately or pass the connection to the next plug in the sequence.

The Plug library has built in plugs that provide CSRF protection, sessions, logging, serving static files, and more.

Phoenix applications themselves are built by composing a series of plugs which are defined in a Phoenix Endpoint.
Phoenix Endpoint

The Phoenix Endpoint is found in the project file lib/hello_world/endpoint.ex. The endpoint defines the plugs that will make up your application. It is the entry and exit point to the Phoenix application.

Each plug will be called in order as defined in the HelloWorld.Endpoint. A plug such as the Plug.Static plug may send a response before the connection is seen by other plugs. Note that the last plug defined is the router.

defmodule HelloWorld.Endpoint do
  use Phoenix.Endpoint, otp_app: :hello_world

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :hello_world, gzip: false,
    only: ~w(css images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_hello_world_key",
    signing_salt: "0yg9mHDO"

  plug :router, HelloWorld.Router
end

Phoenix Router

A Router defines an application’s pipelines and paths. If the given URL path matches based on the HTTP verb and path, the indicated controller action will be run.

Pipelines are defined using the pipeline macro which describes a sequence of plugs to run on the connection. The scope macros define which pipelines to run using the pipe_through macro.

In this example, our GET request to http://localhost:4000/ will match get "/" definition so the PageController.index function will be called after the :browser pipeline plugs are called with the connection. The :browser pipeline is called because the get "/" is defined inside a scope that specifies a pipeline using pipe_through.

The Phoenix Router is analogous to the routes.rb file in Ruby on Rails. The mix phoenix.routes command will list the routes and path helpers defined by the router.

defmodule HelloWorld.Router do
  use HelloWorld.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWorld do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWorld do
  #   pipe_through :api
  # end
end

Phoenix Controller

The controller is where application logic is done. Often this will include running SQL queries using the Ecto database library which is not covered in this article.

The params variable will contain a string keyed map of request parameters. Next, Phoenix.Controller.render/2 is called with the conn and template name index.html. Often, Phoenix.Controller.render/3 will be called with additional data to render like this: render conn, "index.html", [data: "data"].

The Phoenix.Controller.render/2 method will lookup the template file which by convention should be located in web/templates/page/index.html.eex and will then call the Phoenix.View.render_to_iodata/3 function.

defmodule HelloWorld.PageController do
  use HelloWorld.Web, :controller

  plug :action

  def index(conn, _params) do
    render conn, "index.html"
  end
end

Phoenix View

Aside from rendering the template, the view also can provide helper functions and path helpers which will automatically be available to the template.

defmodule HelloWorld.PageView do
  use HelloWorld.Web, :view
end

Phoenix Template

By default, an html formatted EEx template was generated. EEx means Embedded Elixir which allows Elixir code to be included in template files.

The index.html.eex file that was generated only contains html by default. So, an alternative template example is shown here.

<div>
  <p><%= "This is Elixir code" %></p>
</div>

HTTP Response

After the view renders the template, the controller will then call the Plug send_resp method with the rendered template data to return the HTTP response.

The user receives the rendered template in the browser.
Links

    Phoenix Framework
    Plug
    Cowboy
    Ecto


Write a string to file

This example shows how to write to a file using File.write.

:ok = File.write("example.txt","Hello File!")

# Error tuple for failure
{:error, reason} = File.write("example.txt","Hello File!")

# write!/3 Raises exception
:ok = File.write!("example2.txt","Hello File!")

Documentation: File.write/3

Pattern match a list

This example shows examples of how a list can be pattern matched.

[head|tail] = [1, 2, 3]
head = 1
tail = [2, 3]

[head|tail] = [1]
head = 1
tail = []

[] = []

# This does not match, no value for head
[head|tail] = []

# match head value
[1 | tail ]= [1, 2, 3]
tail = [2, 3]

# use underscore to ignore a variable
[head | _ ]= [1, 2, 3]


Pipe operator

The pipe operator |> is used to chain together a sequence of function calls. The result of the expression on the left side of the operator is passed as the first argument to the function in the right side of the operator.

["A", "B", "C"] = "a,b,c"
                   |> String.split(",") # split takes 2 arguments but here
                                        # the first argument is omitted
                                        # in the parentheses and
                                        # the left side of the |> operator
                                        # will be the first argument implicitly
                   |> Enum.map( &String.upcase/1 )

# This is equivalent to:
Enum.map(String.split("a,b,c", ","), &String.upcase/1)


Alias, Use, Import, and Require

The special forms alias, use, import, and require are ways of accessing functions or macros outside of the current module. The forms alias and import are used to be able to refer to functions without having to use their fully qualified names. The form use is used to add functionality to the current module by running a macro from another module. When macros are used from an external module, require is needed to make the macros available to the compiler at compile time.
Alias

Used to shorten the references to a specific module.

# Fully qualified User struct
%Application.User{}

# alias is used to shorten the fully qualified name
alias Application.User, as: User

# After aliasing
%User{}

# alias without `:as` option will automatically use the last
# part of the module name after the last period
alias Application.User
# is the same as
alias Application.User, as: User

Use

Adds functionality to the current module by calling another module’s __using__ macro.

defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def say_hello do
        IO.puts "Hello"
      end
    end
  end
end

defmodule MyModule do
  use Hello
end

# prints "Hello"
MyModule.say_hello

Import

Imports specific functions into the current module so they can be called without using their module name.

# Without import functions need to be called
# by their full name including the module
"ABC" = String.upcase("abc")

# Import a single function with the form
# import Module, only: [function_name: arity]
import String, only: [upcase: 1]

# upcase can now be used without the module name
"ABC" = upcase("abc")

# Imports all functions in the String module.
# It is recommend to use only option above to
# only import the functions you need.
import String

Require

Makes a macro from an external module available to the compiler at compile time.

defmodule Hello do
  # Example macro to add say_hello function to the module
  defmacro hello_macro do
    quote do
      def say_hello do
        IO.puts "Hello"
      end
    end
  end

end


defmodule MyModule do
  # Without require here results in the following error:
  # (CompileError) iex:37: you must require Hello before invoking the macro Hello.hello_macro/0
  require Hello
  Hello.hello_macro

end

# Prints Hello
MyModule.say_hello

See documentation for more information: Alias, require and import

Mix list all tasks command

The mix help command can be used to list all available commands. Available commands will vary depending if there is a mix.exs file in the current directory.

$ mix help
mix                   # Runs the default task (current: "mix run")
mix app.start         # Starts all registered apps
mix archive           # Lists all archives
mix archive.build     # Archives this project into a .ez file
mix archive.install   # Installs an archive locally
mix archive.uninstall # Uninstalls archives
mix clean             # Deletes generated application files
mix cmd               # Executes the given command
mix compile           # Compiles source files
mix deps              # Lists dependencies and their status
mix deps.clean        # Deletes the given dependencies' files
mix deps.compile      # Compiles dependencies
mix deps.get          # Gets all out of date dependencies
mix deps.unlock       # Unlocks the given dependencies
mix deps.update       # Updates the given dependencies
mix do                # Executes the tasks separated by comma
mix escript.build     # Builds an escript for the project
mix help              # Prints help information for tasks
mix hex               # Prints Hex help information
mix hex.build         # Builds a new package version locally
mix hex.config        # Reads or updates Hex config
mix hex.docs          # Publishes docs for package
mix hex.info          # Prints Hex information
mix hex.key           # Hex API key tasks
mix hex.outdated      # Shows outdated Hex deps for the current project
mix hex.owner         # Hex package ownership tasks
mix hex.publish       # Publishes a new package version
mix hex.registry      # Hex registry tasks
mix hex.search        # Searches for package names
mix hex.user          # Hex user tasks
mix loadconfig        # Loads and persists the given configuration
mix local             # Lists local tasks
mix local.hex         # Installs Hex locally
mix local.public_keys # Manages public keys
mix local.rebar       # Installs rebar locally
mix new               # Creates a new Elixir project
mix phoenix.new       # Create a new Phoenix v0.13.1 application
mix profile.fprof     # Profiles the given file or expression with fprof
mix run               # Runs the given file or expression
mix test              # Runs a project's tests
iex -S mix            # Starts IEx and run the default task


Get the last item in a list

This example shows how to get the last item in a list. Keep in mind that it is more effecient to get the head of a list than the last item when processing lists.

:c = List.last([:a, :b, :c])

# nil is returned for an empty list
nil = List.last([])

Documentation: List.last/1

Pin operator

The normal behavior of the match operator is to rebind variables on the left side of the operator if there is a match. The pin operator ^ is used on the left side of the match operator when you don’t wish to rebind and would like to match against the value of the pinned variable.

a = 1

# rebind a to 2, then 3
a = 2
a = 3

# Match error because a is pinned to 3
^a = 4

Documentation: Pin Operator

Function capturing

Elixir often refers to functions in the format Module.function/arity. For example the to_atom function in the String module which takes one argument would be referred to as String.to_atom/1 in the documentation. When a reference to a function is needed, we can use the function capture syntax, using the capture operator &, as shown below to get a reference to a function.

fun_to_atom = &String.to_atom/1

:a = fun_to_atom.("a")

true = is_function(fun_to_atom)

# Function capturing is often used to pass functions as parameters
# to another function
[:a] = Enum.map(["a"], &String.to_atom/1)

The capture operator & can also be used to create anonymous functions.

Documentation: Function Capturing

Define a Protocol

A Protocol is a way to dispatch to a particular implementation of a function based on the type of the parameter.

The macros defprotocol and defimpl are used to define Protocols and Protocol implementations for different types in the following example.

defprotocol Double do

  def double(input)

end

defimpl Double, for: Integer do

  def double(int) do
    int * 2
  end

end


defimpl Double, for: List do

  def double(list) do
    list ++ list
  end

end

4 = Double.double(2)
[1, 2, 1, 2] = Double.double([1, 2])

Documentation: Protocols

Map an enumerable

The map function enumerates an enumerable while applying a transform function and collects the results into a list. Enum.map can be used to map a list, map a map, or map any enumerable.

[2, 4, 6] = Enum.map([1, 2, 3], fn(i) -> i * 2 end)

# map a map
[:one, :two] = Enum.map(%{ one: 1, two: 2}, fn({k, v}) -> k end)

# map a keyword list
[1, 2] = Enum.map([c: 1, d: 2], fn({k, v}) -> v end)

# map to a keyword list
[a: 2, a: 4, a: 6] = Enum.map([1, 2, 3], fn(i) -> {:a , i * 2} end)

Documentation: Enum.map/2

With statement

The special form with is used to chain a sequence of matches in order and finally return the result of do: if all the clauses match. However, if one of the clauses does not match, its result is immediately returned.

6 = with { parsed, _ } <- Integer.parse("3.0"),
         do: parsed * 2

# if a clause doesn't match
# it's result is immediately returned
6 = with 2 <- 2,
         1 <- 6,
         do: 11       

:error = with { parsed, _ } <- Integer.parse("WORD"),
         do: parsed * 2

Documentation: Kernel.SpecialForms.with/1

String to list of single character strings

This example shows how to convert a String into a list of single characters. This could be used to enumerate a string.

Elixir calls each character a grapheme so we use the String.graphemes/1 method.

["T", "e", "s", "t"] = String.graphemes("Test")

# Contrast this with codepoints which may return
# multiple codepoints for a single character
["ö"]      = String.graphemes("ö")
["o", "̈"] = String.codepoints("ö")

Documentation: String.graphemes/1

Repeat a String a number of times

This example shows how to repeat a String a given number of times.

"AAA" = String.duplicate("A", 3)

"HELLO HELLO " = String.duplicate("HELLO ", 2)


Multiline Strings / Heredocs

This example shows how to create a multiline string.
First line break is removed

"  1\n  2\n  3\n" = """
  1
  2
  3
"""

# Whitespace before trailing `"""` will remove
# whitespace up to the same indentation
# on each line
  "1\n2\n3\n" = """
                1
                2
                3
                """  

# Heredoc sigils can also be used
# Interpolated
~s"""
\"#{1}\"
\"#{2}\"
"""
# Not Interpolated
~S"""
"1"
"2"
"""


Lowercase all characters in a string

This example shows how to lowercase every letter in a string.

"hello world!" = String.downcase("Hello World!")

Documentation: String.downcase/1

Get the first character in a string

This example shows how to get the first character in a string.

"H" = String.at("Hello",0)

Documentation: String.at/2

Test if a string ends with another string

This example shows how to check if a string ends with a given suffix.

true = String.ends_with?("Period.", ".")

# True if any of list values match:
true  = String.ends_with?("Period.", [".","?"])
false = String.ends_with?("      !", [".","?"])

Documentation: String.ends_with?/2

Uppercase all characters in a string

This example shows how to uppercase every letter in a string.

"HELLO WORLD!" = String.upcase("Hello World!")

Documentation: String.upcase/1

Read file using File.stream!

This example shows how to read a file using File.stream!/3.

stream = File.stream!("scratch.txt")

# The stream is read by each line when Enumerated
Enum.each(stream, fn(x) -> IO.puts x end)

["Line 1\n", "Line 2\n"] = Enum.into(stream, [])

2 = Enum.reduce(stream, 0, fn(x, acc) -> acc + 1 end)

See documentation for more information: File.stream!/3

Read file into a string

This example shows how to read a file to a string.

{:ok, contents} = File.read("exists.txt")
{:error, reason} = File.read("doesnt_exist.txt")

contents = File.read!("exists.txt")

# Raises a File.Error
contents = File.read!("doesnt_exist.txt")


In operator

The in operator tests for membership using === within an enumerable.

true = "one" in ["one", "two"]

# `in` is equivalent to calling Enum.member?/2
Enum.member?(["one", "two"], "one")

true = {:a, 1} in %{a: 1, b: 2}
true = 1 in 1..4


Check if a file exists

The File module provides an exists?/1 to check if a file exists.

true  = File.exists?("exists.txt")
false = File.exists?("doesnt_exist.txt")


Word list

Word lists can be created using the ~w sigil.

["one", "two", "three"] = ~w(one two three)


Get the type of a variable

Elixir provides a number of functions to test the type of a variable.

is_atom(variable)
is_binary(variable)
is_bitstring(variable)
is_boolean(variable)
is_float(variable)
is_function(variable)
is_function(variable, arity)
is_integer(variable)
is_list(variable)
is_map(variable)
is_number(variable)
is_pid(variable)
is_port(variable)
is_reference(variable)
is_tuple(variable)


Return early

There is no return keyword so code must be organized to return early. The follow example shows how to organize code to return early in Elixir.

For example, the early return in ruby:

def hello
  if some_condition
     return "Goodbye"
  end
  do_this()
  do_something()
end

Could look like this in Elixir:

def hello do
  if some_condition do
    "Goodbye"
  else
     do_this()
     do_something()
  end
end

Case and cond can also be used to return different values based on a condition.

See Also:

    Case Statement
    Cond Statement


Truth table

The truth table for if/cond/unless statements in Elixir is simple: only nil and false evaluate to false. All other values are true.

# Only nil and false are falsey everything else is truthy
nil
false


Nil

This example shows example nil usage. Nil is frequently used as a return value to represent no value.

nil

true = is_nil(nil)

# nil is falsey
"ok" = unless nil do
         "ok"
       end


Get a value from a map

This example shows different ways to get values from a map.

# dot syntax can be used if key is atom
1 = %{c: 1}.c

# Raises a key error for missing key
%{c: 1}.a

# [] works for non-atom values
1 = %{"a" => 1}["a"]

# [] returns nil for missing values
nil = %{"a" => 1}["b"] 

# Pattern matching can be used
%{c: value} = %{c: 1}

1   = Map.get(%{c: 1}, :c)
nil = Map.get(%{c: 1}, :a)

# Default value can be specified
# for when the key is misssing
"default" = Map.get(%{c: 1}, :a, "default")

{:ok, value} = Map.fetch(%{c: 1}, :c)
:error       = Map.fetch(%{c: 1}, :a)

1 = Map.fetch!(%{c: 1}, :c)

# Raises a key error
Map.fetch!(%{c: 1}, :a)


Range of characters

Character literals like ?a can be used to create a range of the ASCII integers of these characters. This example could represent a range from a to z.

97..122 = ?a..?z


Range syntax

This example shows the literal syntax used to create a range.

# range is inclusive start to end
1..4

[1, 2, 3, 4] = Enum.to_list( 1..4 )

# can be defined high to low
4..1

Documentation: Range

Optional parameters

You can define a method with default arguments using the \\ syntax. The default arguments are used when the argument is not provided.

def hello(name \\ "Unknown" ) do
  # name value is "Unknown" when name argument not provided
  "Hello #{name}"
end


Ecto model calculated field

This example shows a common approach to having a calculated field for a model.

defmodule User do
  use Ecto.Schema

  schema "users" do
    field :first_name, :string
    field :last_name,  :string
  end

  # Example calculated field
  def full_name(user) do
      user.first_name <> " " <> user.last_name
  end

end


Elixir and Ruby Comparison

The following is a guide to help compare Elixir and Ruby syntax and implementations.
</tr> </tr> </tr>
	Ruby 	Elixir
Characteristics 	Object-oriented, Imperative, Metaprogramming 	Functional, Actor Concurrency, Macros
Typing 	Dynamic 	Dynamic
Concurrency 	N/A 	Lightweight Processes
Static Analysis 	Not Available 	Optional Typespecs
Interfaces 	Duck Typing 	Behaviours & Protocols
Package Manager 	RubyGems 	Hex
Task Runner 	rake 	mix
Interactive Shell 	irb 	iex
Testing 	RSpec, test-unit, minitest 	ExUnit
Web Framework 	Rails 	Phoenix
Virtual Machine 	YARV 	BEAM
Distributed Computing 	N/A 	Open Telecom Platform (OTP)
Define a method/function 	

def hello
  "result"
end

	

def hello do
  "result"
end

Variable assignment/Capture 	

#
a = "hello"

	

# match operator
a = "hello"

Hash/Map Syntax 	

{a: 1}

	

%{a: 1}

Array/Tuple 	

[1, 2, 3, 4]

	

{1, 2, 3, 4}

List Syntax 	

# Not Available

	

[1, 2, 3, 4]

Map an Array/List 	

[1, 2, 3, 4].map { |x| x * x }

	

Enum.map([1, 2, 3, 4], &(&1 * &1))

Range Syntax 	

1..4

	

1..4

String Interpolation 	

"#{2 + 2}"

	

"#{2 + 2}"

Reverse a String 	

"hello".reverse

	

String.reverse("hello")

Define a class 	

class Hello
end

	

# Not Applicable
# Modules, Structs, Protocols are used

Anonymous Functions 	

square = lambda { |x| x * x }

	

square = fn(x) -> x * x end

Call Anonymous Function 	

square.call(2)
square.(2)

	

square.(2)

Define Module 	

module Example
end

	

defmodule Example
end

Atoms 	

#
:one

	

# not garbage collected
:one

Division 	

#
5 / 2 == 2

	

# use div/2 for integer division
 5 / 2 == 2.5

If 	

if true
end

	

if true do
end

Else If 	

result = if 0 > 1
           "No"
         elsif 0 > 2
           "Nope"
         else
           "fallback"
         end

	

result = cond do
           0 > 1 -> "No"
           0 > 2 -> "Nope"
           true  -> "fallback"
         end
#
#

Printing 	

puts "Hello World"

	

IO.puts "Hello World"

Looping 	

[1, 2, 3, 4].each { |i| puts i }

	

Enum.each([1, 2, 3, 4], &(IO.puts &1))

		
Pattern Matching 	

# Not available
#
#
#
#

	

[a, b] = [1, 2]
%{a: value} = %{a: 1}
# pattern matching can match against literals
# and be used in function definitions,
# case statements, list comprehensions and more

Guard Clauses 	

# not available
#

	

def hello( v ) when is_atom(v) do
end

Metaprogramming 	

method_missing
define_method
# et al

	

# Macros
#
#

		
		

Regex basics

Here are a few examples on how to use regular expressions in Elixir.

# A regex sigil to match 'foo'
~r/foo/

# Interpolation can be used
~r/foo/ = ~r/#{"foo"}/

# Test if a string matches
true = Regex.match?( ~r/foo/ , "Hello foo")

# Run returns first match
["foo1", "1"] = Regex.run(~r/foo([0-9])/, "foo1 foo2")

# Scan returns all matches
[["foo1", "1"], ["foo2", "2"]] = Regex.scan(~r/foo([0-9])/, "foo1 foo2")

# Replace matches in a string
"one_two_three" = Regex.replace(~r/-/, "one-two-three", "_")

Documentation: Regex

Unless statement

Unless statement

"ok" = unless false do
         "ok"
       end

See Also: if

Filter list

Filter a list

[3, 4] = Enum.filter( [1, 2, 3, 4], fn(x) -> x > 2 end )


Ternary

Ternary operator

# There currently is no ternary operator like  true ? "yes" : "no"
# So the following is suggested
"no" = if 1 == 0, do: "yes", else: "no"


Keyword list syntax

Keyword list syntax

[{:one, 1}, {:two, 2}] = [one: 1, two: 2]


Map to keyword list

Convert a map to keyword list

[one: 1, two: 2] = Map.to_list(%{one: 1, two: 2})


Map to struct

Map to struct

# given the struct
defmodule User do
  defstruct username: nil
end

%User{username: "test" } = struct(User, %{username: "test", password: "secret"})

# struct! raises KeyError if un-matching keys provided
%User{username: "test" } = struct!(User, %{username: "test", password: "secret"})


Pattern match a map

Pattern match a map

%{ b: value, d: value2 } = %{ a: 1, b: 2, d: 3 }

# Matches keys on the left side
# There may be more keys on the right side
%{ a: value } = %{ a: 1, b: 2, d: 3 }

# raises a match error if key is missing
%{ c: value } = %{ a: 1, b: 2 }


Module definition

How to define a module in Elixir:

defmodule Example do
end

# periods are allowed in module names
defmodule Example.Specific do
end

Documentation:

    Modules Guide
    Kernel.defmodule/2


Tuple syntax

This example shows the literal syntax to create a tuple and also how to pattern match.

{:ok, 1, "a"}

# pattern match
{:ok, result} = {:ok, "good"}

# this raises a match error
{:ok, result} = {:ok, "good", "one more"}

# empty tuple
{}


function definition

How to define a function/method in elixir:

# functions are defined inside Modules
defmodule Examples do

  # basic defintion
  def do_stuff( params ) do
      "result"
  end

  #shorthand syntax
  def shorthand(), do: "result"

  # defp is for private functions
  defp private_method, do: "private"

  # params can pattern match
  def match_this(%{:key => value}), do: value

  # the first matching function is called (order matters)
  def test(test), do: "matches any param"
  def test([]), do: "never matched"

end


Anonymous functions

These examples show two syntaxes available to create anonymous functions.

square = fn(x) -> x * x end

# calling an anonymous function uses a period
# before the parentheses
4 = square.(2)


# pattern matching the arguments can be used
first = fn([head|rest]) -> head end
1 = first.([1, 2])

# anonymous functions are commonly used as arguments
# to other functions
[1, 4, 9] = Enum.map([1, 2, 3], square)
[3, 4, 5] = Enum.map([1, 2, 3], fn(x) -> x + 2 end)

The shorthand syntax to create anonymous functions with the capture operator. The syntax wraps an expression with &() and each argument is indexed starting at 1 identified by &1, &2, and so on.

square = &( &1 * &1 )
4 = square.(2)

# This results in a compile error with
# the capture operator
# because at least one argument must be used
four = &(2 + 2)

Documentation Capture operator

Cond statement

cond - similar to if, else if, else in other languages

"true is always true" = cond do
                           0 > 1 -> "No"
                           0 > 2 -> "Nope"
                           true  -> "true is always true"
                        end


Concatenate lists

List concatenation

[1, 2] = [1] ++ [2]


Map syntax

Map syntax

# empty map
%{}

# map arrow syntax
%{"one" => 1, "two" => 2}

# shorthand when keys are atoms
%{ one: 1, two: 2}


String concatenation

Concatenate strings

"Hello World" = "Hello" <> " " <> "World"

Documentation: Kernel.<>/2

Integer modulo

Modulo/Remainder of integer division

1 = rem(5, 2)

# same sign as dividend
-1 = rem(-5, 2)


Mix generate Ecto migration

Phoenix/Mix generate Ecto migration

mix ecto.gen.migration add_author_to_post

Documentation: Mix.Tasks.Ecto.Gen.Migration

See Also:

    mix ecto.migrate
    mix ecto.rollback


Mix Ecto Rollback Command

This mix task reverts migrations which were previously run.

mix ecto.rollback

Documentation: mix ecto.rollback

See Also:

    mix ecto.migrate
    mix ecto.gen.migration


Mix Ecto Migrate Command

This mix task runs any pending migrations against the repository.

mix ecto.migrate

Documentation: mix ecto.migrate

See Also:

    mix ecto.rollback
    mix ecto.gen.migration


If statement

If statement

"good" = if true do
 			"good"
   		 else
 			"This will"
   		 end

# nil is default when else is missing
nil = if false do
 			"good"
   		   end 		 

# alternative, one line syntax  		 
"good" = if true, do: "good"
"else"  = if false, do: "good", else: "else"

Documentation: Kernel.if/2

See Also: unless

case statement

Case statement (similar to switch in other languages)

"Good" = case {:ok, :data} do
              {:ok, result} -> "Good"
           {:error, result} -> "Bad"
                          _ -> "Nothing matched"
         end

Documentation: Kernel.SpecialForms.case/2

Size of a tuple

Get the size/length of a tuple

3 = tuple_size({1, 2, 3})  

Documentation: Kernel.tuple_size/1

Size of a map

Get the size/length of a map

1 = map_size(%{a: 1})

Documentation: Kernel.map_size/1

Length of list

Length of list

3 = length([1, 2, 3])  

Documentation: Kernel.length/1

Keyword list to map

Keyword list to map

%{a: 1, b: 2, c: 3} = Enum.into( [a: 1, b: 2, c: 3], %{} )

Documentation: Enum.into/2

Tuple to list

Tuple to list

[:a, :b, :c] = Tuple.to_list({:a, :b, :c})

Documentation: Tuple.to_list/1

Range to list

Range to list

[1, 2, 3, 4] = Enum.to_list( 1..4 )

Documentation: Enum.to_list/1

List comprehension

List comprehension

[2, 4, 6] = for n <- [1, 2, 3], do: n + n

Related Documentation: Comprehensions

Print map

Prints a map

%{key: 42} = IO.inspect(%{key: 42})
# prints "%{key: 42}"

Related Documentation: Inspect Protocol

Print list

Prints a list

[1, 2, 3] = IO.inspect([1, 2, 3])
# prints "[1, 2, 3]"

Related Documentation: Inspect Protocol

Print to console

Print to console

:ok = IO.puts("Hello World")


String interpolation

String interpolation

"Hello 42" = "Hello #{21 + 21}"


Atom to string

Convert an atom to a string

"hello" = Atom.to_string(:hello)

Documentation: Atom.to_string/1

Join a list of strings

Join a list of strings

 "1,2,3" = Enum.join(["1","2","3"], ",")

Documentation: Enum.join/2

Raise number to a power (exponent)

Raise number to a power (exponent)

8.0 = :math.pow(2, 3)

Documentation: math.pow/2

Strip leading and trailing whitespace from a string

Remove/trim leading and trailing whitespace from a string

"a" = String.trim("   a   ")

Documentation: String.trim/1

Replace character in a string

Replace character in a string

"123" = String.replace("1.2.3", ".", "")  

Documentation: String.replace/4

Split a string

This example shows how to split a string on whitespace or split on a string.

["1", "2", "3"] = String.split("1,2,3" , ",")

# String.split/1 is useful to split on and strip whitespace
["1", "2"] = String.split("   1  \n \t   2 \n")

Documentation:

    String.split/3
    String.split/1


Prepend to list

Prepend to list

[1, 2, 3, 4] = [1 | [2, 3, 4]]


Parse string to float

Parse string to float

{3.14, ""} = Float.parse("3.14")

Documentation: Float.parse/1

Parse string to integer

Parse string to integer

{4, ""} = Integer.parse("4")

Documentation: Integer.parse/2

Integer division

Integer division

2 = div(11, 4)


Head of a list

Get the head of a list

1 = hd([1, 2, 3, 4])

# alternatively use pattern matching
[head | tail] = [1, 2, 3, 4]
# head contains 1


Update a map value

Update a map value

%{a: "New Value"} = %{  %{ a: "Old Value" } | a: "New Value" }

# Note that this does not work to add a new key
%{ %{} | new_key: 1}
# Raises (KeyError) key :new_key not found in: %{}

# Map.put/3 will add a key if it does not exist
%{new_key: 1} = Map.put(%{}, :new_key, 1)
# or update the value if it does exist
%{new_key: 2} = Map.put(%{new_key: 1}, :new_key, 2)


Reverse a string

Reverse a string

"olleh" = String.reverse("hello")


    elixir-examples
    elixirexamples

A collection of small Elixir programming language examples.

CC0
RSS
