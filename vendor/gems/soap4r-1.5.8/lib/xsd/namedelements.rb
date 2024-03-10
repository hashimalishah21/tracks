# XSD4R - WSDL named element collection.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


module XSD


class NamedElements
  include Enumerable

  def initialize
    @elements = []
    @cache = {}
  end

  def dup
    o = NamedElements.new
    o.elements = @elements.dup
    o
  end

  def freeze
    super
    @elements.freeze
    self
  end

  def empty?
    size == 0
  end

  def size
    @elements.size
  end

  def [](idx)
    if idx.is_a?(Numeric)
      @elements[idx]
    else
      @cache[idx] ||= @elements.find { |item| item.name == idx }
    end
  end

  def find_name(name)
    @elements.find { |item| item.name.name == name }
  end

  def keys
    collect { |element| element.name }
  end

  def each
    @elements.each do |element|
      yield(element)
    end
  end

  def <<(rhs)
    @elements << rhs
    self
  end

  def delete(rhs)
    rv = @elements.delete(rhs)
    @cache.clear
    rv
  end

  def +(rhs)
    o = NamedElements.new
    o.elements = @elements + rhs.elements
    @cache.clear
    o
  end

  def concat(rhs)
    @elements.concat(rhs.elements)
    @cache.clear
    self
  end

  def uniq
    o = NamedElements.new
    o.elements = uniq_elements
    o
  end

  def uniq!
    @elements.replace(uniq_elements)
    @cache.clear
  end

  def find_all
    o = NamedElements.new
    each do |ele|
      o << ele if yield(ele)
    end
    o
  end

  Empty = NamedElements.new.freeze

protected

  def elements=(rhs)
    @elements = rhs
  end

  def elements
    @elements
  end

private

  def uniq_elements
    dict = {}
    elements = []
    @elements.each do |ele|
      unless dict.key?(ele.name)
        dict[ele.name] = ele
        elements << ele
      end
    end
    elements
  end
end

end
