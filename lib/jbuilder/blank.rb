class Jbuilder
  class Blank
    def ==(other)
      super || Blank === other
    end
  end
end
