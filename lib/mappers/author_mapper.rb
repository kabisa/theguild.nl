# frozen_string_literal: true

require_relative 'as_slug'

# Custom mapper for contentful Author pages
class AuthorMapper < ContentfulMiddleman::Mapper::Base
  include AsSlug

  def map(context, entry)
    super
    as_slug(context, :name)
  end
end
