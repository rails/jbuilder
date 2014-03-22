# Changelog

2.0.5
-----
* [Fix edgecase when json is defined as a method](https://github.com/rails/jbuilder/commit/ca711a0c0a5760e26258ce2d93c14bef8fff0ead)

2.0.4
-----
* [Add cache_if! to conditionally cache JSON fragments](https://github.com/rails/jbuilder/commit/14a5afd8a2c939a6fd710d355a194c114db96eb2)

2.0.3
-----
* [Pass options when calling cache_fragment_name](https://github.com/rails/jbuilder/commit/07c2cc7486fe9ef423d7bc821b83f6d485f330e0)

2.0.2
-----
* [Fix Dependency Tracking fail to detect single-quoted partial correctly](https://github.com/rails/jbuilder/commit/448679a6d3098eb34d137f782a05f1767711991a)
* [Prevent Dependency Tracker constants leaking into global namespace](https://github.com/rails/jbuilder/commit/3544b288b63f504f46fa8aafd1d17ee198d77536)

2.0.1
-----
* [Dependency tracking support for Rails 3 with cache_digest gem](https://github.com/rails/jbuilder/commit/6b471d7a38118e8f7645abec21955ef793401daf)

2.0.0
-----
* [Respond to PUT/PATCH API request with :ok](https://github.com/rails/jbuilder/commit/9dbce9c12181e89f8f472ac23c764ffe8438040a)
* [Remove Ruby 1.8 support](https://github.com/rails/jbuilder/commit/d53fff42d91f33d662eafc2561c4236687ecf6c9)
* [Remove deprecated two argument block call](https://github.com/rails/jbuilder/commit/07a35ee7e79ae4b06dba9dbff5c4e07c1e627218)
* [Make Jbuilder object initialize with single hash](https://github.com/rails/jbuilder/commit/38bf551db0189327aaa90b9be010c0d1b792c007)
* [Track template dependencies](https://github.com/rails/jbuilder/commit/8e73cea39f60da1384afd687cc8e5e399630d8cc)
* [Expose merge! method](https://github.com/rails/jbuilder/commit/0e2eb47f6f3c01add06a1a59b37cdda8baf24f29)

1.5.3
-----
* [Generators add `:id` column by default](https://github.com/rails/jbuilder/commit/0b52b86773e48ac2ce35d4155c7b70ad8b3e8937)

1.5.2
-----
* [Nil-collection should be treated as empty array](https://github.com/rails/jbuilder/commit/2f700bb00ab663c6b7fcb28d2967aeb989bd43c7)

1.5.1
-----
* [Expose template lookup options](https://github.com/rails/jbuilder/commit/404c18dee1af96ac6d8052a04062629ef1db2945)

1.5.0
-----
* [Do not perform any caching when `controller.perform_caching` is false](https://github.com/rails/jbuilder/commit/94633facde1ac43580f8cd5e13ae9cc83e1da8f4)
* [Add partial collection rendering](https://github.com/rails/jbuilder/commit/e8c10fc885e41b18178aaf4dcbc176961c928d76)
* [Deprecate extract! calling private methods](https://github.com/rails/jbuilder/commit/b9e19536c2105d7f2e813006bbcb8ca5730d28a3)
* [Add array of partials rendering](https://github.com/rails/jbuilder/commit/7d7311071720548047f98f14ad013c560b8d9c3a)

1.4.2
-----
* [Require MIME dependency explicitly](https://github.com/rails/jbuilder/commit/b1ed5ac4f08b056f8839b4b19b43562e81e02a59)

1.4.1
-----
* [Removed deprecated positioned arguments initializer support](https://github.com/rails/jbuilder/commit/6e03e0452073eeda77e6dfe66aa31e5ec67a3531)
* [Deprecate two-arguments block calling](https://github.com/rails/jbuilder/commit/2b10bb058bb12bc782cbcc16f6ec67b489e5ed43)

1.4.0
-----
* [Add quick collection attribute extraction](https://github.com/rails/jbuilder/commit/c2b966cf653ea4264fbb008b8cc6ce5359ebe40a)
* [Block has priority over attributes extraction](https://github.com/rails/jbuilder/commit/77c24766362c02769d81dac000b1879a9e4d4a00)
* [Meaningfull error messages when adding properties to null](https://github.com/rails/jbuilder/commit/e26764602e34b3772e57e730763d512e59489e3b)
* [Do not enforce template format, enforce handlers instead](https://github.com/rails/jbuilder/commit/72576755224b15da45e50cbea877679800ab1398)

1.3.0
-----
* [Add nil! method for nil JSON](https://github.com/rails/jbuilder/commit/822a906f68664f61a1209336bb681077692c8475)

1.2.1
-----
* [Added explicit dependency for MultiJson](https://github.com/rails/jbuilder/commit/4d58eacb6cd613679fb243484ff73a79bbbff2d2

1.2.0
-----
* Multiple documentation improvements and internal refactoring
* [Fixes fragment caching to work with latest digests](https://github.com/rails/jbuilder/commit/da937d6b8732124074c612abb7ff38868d1d96c0)

1.0.2
-----
* [Support non-Enumerable collections](https://github.com/rails/jbuilder/commit/4c20c59bf8131a1e419bb4ebf84f2b6bdcb6b0cf)
* [Ensure that the default URL is in json format](https://github.com/rails/jbuilder/commit/0b46782fb7b8c34a3c96afa801fe27a5a97118a4)

1.0.0
-----
* Adopt Semantic Versioning
* Add rails generators
