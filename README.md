[<img src='https://i.imgur.com/Eec71eh.png' width='200px' />][docs]
===================================================================

[![Build Status][shield-travis]][travis-ci]
[![Coverage Status][shield-inch]][inch-ci]
[![Version][shield-version]][hexpm]
[![License][shield-license]][hexpm]

> Simple Background Job Processing in Elixir :zap:

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

  [license]:          https://opensource.org/licenses/MIT
  [travis-ci]:        https://travis-ci.org/sheharyarn/que
  [inch-ci]:          https://inch-ci.org/github/sheharyarn/que

  [hexpm]:            https://hex.pm/packages/que
  [docs]:             https://hexdocs.pm/que

  [github-fork]:      https://github.com/sheharyarn/que/fork

