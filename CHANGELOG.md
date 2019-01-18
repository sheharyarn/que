Changelog
=========


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
