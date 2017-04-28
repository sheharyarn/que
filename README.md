[<img src='https://i.imgur.com/Eec71eh.png' alt='Que' width='200px' />][docs]
=============================================================================

[![Build Status][shield-travis]][travis-ci]
[![Coverage Status][shield-inch]][docs]
[![Version][shield-version]][hexpm]
[![License][shield-license]][hexpm]

> Simple Background Job Processing in Elixir :zap:

Que is a job processing library backed by [`Mnesia`][mnesia], a distributed
real-time database that comes with Erlang / Elixir. That means it doesn't
depend on any external services like `Redis` for persisting job state. This
makes it really easy to use since you don't need to install anything other
Que itself.

See the [Documentation][docs].

<br>




## Installation

Add `que` to your project dependencies in `mix.exs`:

```elixir
def deps do
  [{:que, "~> 0.3.1"}]
end
```

and then add it to your list of `applications`:

```elixir
def application do
  [applications: [:que]]
end
```


### Mnesia Setup

Que runs out of the box, but by default all jobs are stored in-memory
only. To persist jobs across application restarts, specify the DB
path in your `config.exs`:

```elixir
config :mnesia, dir: 'mnesia/#{Mix.env}/#{node()}'        # Notice the single quotes
```

And run the following mix task:

```bash
$ mix que.setup
```

This will create the Mnesia schema and job database for you. For a
detailed guide, see the [Mix Task Documentation][docs-mix]. For
compiled releases where `Mix` is not available
[see this][docs-setup-prod].

<br>




## Usage

Que is very similar to other job processing libraries such as Ku and
Toniq. Start by defining a [`Worker`][docs-worker] with a `perform/1`
callback to process your jobs:

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

The argument here can be any term from a Tuple to a Keyword List
or a Struct. You can also pattern match and use guard clauses like
normal methods:

```elixir
defmodule App.Workers.NotificationSender do
  use Que.Worker

  def perform(type: :like, to: user, count: count) do
    User.notify(user, "You have #{count} new likes on your posts")
  end

  def perform(type: :message, to: user, from: sender) do
    User.notify(user, "You received a new message from #{sender.name}")
  end

  def perform(to: user) do
    User.notify(user, "New activity on your profile")
  end
end
```


### Concurrency

By default, all workers process one Job at a time, but you can
customize that by passing the `concurrency` option:

```elixir
defmodule App.Workers.SignupMailer do
  use Que.Worker, concurrency: 4

  def perform(email) do
    Mailer.send_email(to: email, message: "Thank you for signing up!")
  end
end
```


### Job Success / Failure Callbacks

The worker can also export optional `on_success/1` and `on_failure/2`
callbacks that handle appropriate cases.

```elixir
defmodule App.Workers.ReportBuilder do
  use Que.Worker

  def perform({user, report}) do
    report.data
    |> PDFGenerator.generate!
    |> File.write!("reports/#{user.id}/report-#{report.id}.pdf")
  end

  def on_success({user, _}) do
    Mailer.send_email(to: user.email, subject: "Your Report is ready!")
  end

  def on_failure({user, report}, error) do
    Mailer.send_email(to: user.email, subject: "There was a problem generating your report")
    Logger.error("Could not generate report #{report.id}. Reason: #{inspect(error)}")
  end
end
```

Head over to Hexdocs for detailed [`Worker` documentation][docs-worker].

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
 - [x] Mix Task for creating Mnesia Database
 - [ ] Better Job Failures
    - [ ] Option to set timeout on workers
    - [ ] Add strategies to automatically retry failed jobs
 - [ ] Web UI

<br>




## Contributing

 - [Fork][github-fork], Enhance, Send PR
 - Lock issues with any bugs or feature requests
 - Implement something from Roadmap
 - Spread the word :heart:

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
  [docs-mix]:         https://hexdocs.pm/que/Mix.Tasks.Que.Setup.html
  [docs-setup-prod]:  https://hexdocs.pm/que/Que.Persistence.Mnesia.html#setup!/0

  [github-fork]:      https://github.com/sheharyarn/que/fork

