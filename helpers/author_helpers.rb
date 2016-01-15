module AuthorHelpers

  def link_to_profile(text, author)
    link_to text, "profiles/#{author.nameAsSlug}"
  end
end

