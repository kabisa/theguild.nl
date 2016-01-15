module AuthorHelpers

  # @example:
  #   link_to_profile(author) { author.name }
  #   #=> <a href="profiles/eddie-van-halen">Eddie van Halen</a>
  def link_to_profile(author, &block)
    link_to yield, "profiles/#{author.nameAsSlug}", class: 'profile-link'
  end
end
