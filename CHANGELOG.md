Changelog
=========


## Version 0.10.0

 - [Enhancement] Add setup/teardown callbacks to workers
 - [Bugfix] `ex_utils` is automatically added to the applications list when
   compiling/building a new release via distillery



## Version 0.9.0

 - Update [Memento][memento] dependency to v0.3.0
     - This fixes issues where Mnesia would throw cyclic abort errors in high
       concurrency, nested worker calls leading to mnesia transaction deadlocks



## Version 0.8.0

 - Enqueuing a job now returns `{:ok, job}` instead of just `:ok`
     - This is possibly a breaking change



## Version 0.7.0

 - Que now uses [`Memento`][memento] instead of [`Amnesia`][amnesia] underneath
     - This does not change Que's API, but could cause unexpected regressions



## Before v0.7.0

I don't remember tbh. Check the [commit history][commits].



  [commits]: https://github.com/sheharyarn/que/commits/master
  [memento]: https://github.com/sheharyarn/memento
  [amnesia]: https://github.com/meh/amnesia/
