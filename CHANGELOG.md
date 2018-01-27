# Changelog

1.2.0
-----
* Add `TurboStreamer#merge!` to merge a hash or array into the current json stream.

1.1.0
-----
* Add `Oj` as an encoder option
* Add ability to pass encoder as an option to `TurboStreamer#new` (symbol or class)
* Ability to set default encoder for mime type with `TurboStreamer#set_default_encoder`
* Add some performance test