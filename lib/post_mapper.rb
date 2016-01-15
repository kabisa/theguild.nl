require_relative 'as_slug'

class PostMapper < ContentfulMiddleman::Mapper::Base
  include AsSlug

  def map(context, entry)
    super
    context.authors.each   { | author | as_slug(author, :name) }
  end
end
