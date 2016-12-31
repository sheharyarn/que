Que
===

> Simple Background Job Processing in Elixir



## Installation

Add `que` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:que, "~> 0.1.0-alpha.1"}]
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



  [license]:          http://opensource.org/licenses/MIT

  [hexpm]:            https://hex.pm/packages/que
  [docs]:             https://hexdocs.pm/que/Que.html

  [github-fork]:      https://github.com/sheharyarn/que/fork

