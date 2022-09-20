# Changelog

1.10.0
-----
* Fixed Rails 6.1 & Ruby 3.0 Compatibility

1.9.0
-----
* Fixed deprecation of using `Proc.new` to capture block; replaced with `&block`

1.8.0
-----
* Make the StreamingRenderer Rails 6 compatible [PR #15](https://github.com/malomalo/turbostreamer/issues/15)
* Update gemspec to require Ruby 2.5+ [PR #14](https://github.com/malomalo/turbostreamer/issues/14)

1.7.0
-----
* Add the ability to set default options for encoders
* Allow setting the `buffer_size` on the OJ encode
* Reduce find_template calls [PR #11](https://github.com/malomalo/turbostreamer/pull/1)
* Don't require a layout to stream template in Rails

1.5.0
-----
* Add Rails 6.0 support
* Drop Rails 4.2 support

1.4.0
-----
* Replace deprecated fragment_cache_key for Rails 5.2 support

1.3.0
-----
* Bump version and update bundler

1.2.0
-----
* Add `TurboStreamer#merge!` to merge a hash or array into the current json stream.

1.1.0
-----
* Add `Oj` as an encoder option
* Add ability to pass encoder as an option to `TurboStreamer#new` (symbol or class)
* Ability to set default encoder for mime type with `TurboStreamer#set_default_encoder`
* Add some performance test
