[![logo][logo]][docs]
=====================

[![Build Status][shield-travis]][travis-ci]
[![Coverage Status][shield-inch]][inch-ci]
[![Version][shield-version]][hexpm]
[![License][shield-license]][hexpm]

> Simple Background Job Processing in Elixir




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




## Roadmap

 - [ ] Write Documentation
 - [ ] Write Tests
 - [ ] Persist Job State to Disk
 - [ ] Allow setting Job priority
 - [ ] Add Concurrency Support
    - [x] Make jobs work in Parallel
    - [ ] Allow customizing the number of concurrent jobs
 - [ ] Event Handlers
    - [x] Success/Failure
    - [ ] Start/Finish
 - [ ] Better Job Failures
    - [ ] Option to set timeout on workers
    - [ ] Set up Job Retries (w/ Exponential Backoff)
    - [ ] Allow customizing Job Retries in `handle_failure` block




## Contributing

 - [Fork][github-fork], Enhance, Send PR
 - Lock issues with any bugs or feature requests
 - Implement something from Roadmap
 - Spread the word




## License

This package is available as open source under the terms of the [MIT License][license].



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

