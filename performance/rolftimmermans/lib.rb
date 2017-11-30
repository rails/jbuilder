$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'active_support'
require "active_support/core_ext"

struct = Struct.new(:name, :birthyear, :bio, :url)
$author = struct.new("Rolf", 1920, "Software developer", "http://example.com/")
$author.instance_eval { undef each } # Jbuilder doesn't like #each on non-arrays.
$now = Time.now
$arr = 100.times.to_a
