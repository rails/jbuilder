object false

node(:article) do
  {
    author: {
      name: $author.name,
      birthyear: $author.birthyear,
      bio: $author.bio,
    },
    title:  "Profiling Jbuilder",
    body:   "How to profile Jbuilder",
    date:   $now,
    references: $arr.map do |ref|
      {
        name: "Introduction to profiling",
        url:  "http://example.com/",
      }
    end,
    comments: $arr.map do |ref|
      {
        author: {
          name: $author.name,
          birthyear: $author.birthyear,
          bio: $author.bio,
        },
        email: "rolf@example.com",
        body: "Great article",
        date:   $now,
      }
    end,
  }
end
