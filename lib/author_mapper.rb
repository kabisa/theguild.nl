require_relative 'as_slug'

class AuthorMapper < ContentfulMiddleman::Mapper::Base
  include AsSlug

  def map(context, entry)
    super
    as_slug(context, :name)
  end
end
