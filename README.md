[<img src='https://i.imgur.com/Eec71eh.png' alt='Que' width='200px' />][docs]
=============================================================================

[![Build Status][shield-travis]][travis-ci]
[![Coverage Status][shield-inch]][docs]
[![Version][shield-version]][hexpm]
[![License][shield-license]][hexpm]

> Simple Background Job Processing in Elixir :zap:

Que is a background job processing library backed by [`Mnesia`][mnesia], a
distributed real-time database that comes with Erlang / Elixir. That means
it doesn't depend on any external services like `Redis` for persisting job
state. This makes it really easy to use since you don't need to install
anything other Que itself.

See the [Documentation][docs].

<br>




## Installation

Add `que` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:que, "~> 0.3.0"}]
end
```

and add it to your list of `applications`:

```elixir
def application do
  [applications: [:que]]
end
```

<br>



## Usage

Que is very similar to other job processing libraries such as Ku, Toniq
and DelayedJob. Start by defining a [`Worker`][docs-worker] with a
`perform/1` callback to process your jobs:

```elixir
defmodule App.Workers.ImageConverter do
  use Que.Worker

  def perform(image) do
    ImageTool.save_resized_copy!(image, :thumbnail)
    ImageTool.save_resized_copy!(image, :medium)
    ImageTool.save_resized_copy!(image, :large)
  end
end
```

You can now add jobs to be processed by the worker:

```elixir
Que.add(App.Workers.ImageConverter, some_image)
#=> :ok
```

<br>




## Roadmap

 - [x] Write Documentation
 - [x] Write Tests
 - [x] Persist Job State to Disk
    - [x] Provide an API to interact with Jobs
 - [x] Add Concurrency Support
    - [x] Make jobs work in Parallel
    - [x] Allow customizing the number of concurrent jobs
 - [x] Success/Failure Callbacks
 - [ ] Delayed Jobs
 - [ ] Allow job cancellation
 - [ ] Better Job Failures
    - [ ] Option to set timeout on workers
    - [ ] Add strategies to automatically retry failed jobs
 - [ ] Web UI

<br>




## Contributing

 - [Fork][github-fork], Enhance, Send PR
 - Lock issues with any bugs or feature requests
 - Implement something from Roadmap
 - Spread the word

<br>




## License

This package is available as open source under the terms of the [MIT License][license].

<br>




  [logo]:             https://i.imgur.com/Eec71eh.png
  [shield-version]:   https://img.shields.io/hexpm/v/que.svg
  [shield-license]:   https://img.shields.io/hexpm/l/que.svg
  [shield-downloads]: https://img.shields.io/hexpm/dt/que.svg
  [shield-travis]:    https://img.shields.io/travis/sheharyarn/que/master.svg
  [shield-inch]:      https://inch-ci.org/github/sheharyarn/que.svg?branch=master

  [travis-ci]:        https://travis-ci.org/sheharyarn/que
  [inch-ci]:          https://inch-ci.org/github/sheharyarn/que

  [license]:          https://opensource.org/licenses/MIT
  [mnesia]:           http://erlang.org/doc/man/mnesia.html

  [hexpm]:            https://hex.pm/packages/que
  [docs]:             https://hexdocs.pm/que
  [docs-worker]:      https://hexdocs.pm/que/Que.Worker.html

  [github-fork]:      https://github.com/sheharyarn/que/fork

