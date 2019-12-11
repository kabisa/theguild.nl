# frozen_string_literal: true

module AuthorHelpers
  # Returns a array of posts for an author_id
  #
  # @return [Array<Post>] items written by author_id
  #
  # @param [Author] the author from contentful to look up
  # @param [Array<Post>] post the collection to look for posts by author
  def posts_by_author(author, posts)
    posts.select do |post|
      post.authors.map(&:id).include?(author.id)
    end
  end

  # Create url for author object
  #
  # @return [String] author url
  #
  # @param [Author] single author object retrieved from contentful
  def author_url(author)
    "/authors/#{author.nameAsSlug}"
  end

  # Returns an array of authors of posts
  #
  # @return [Array<Author>]
  def authors
    data.site.author.values.sort_by(&:name)
  end

  def pluralize(singular, count, plural = nil)
    if count == 1
      singular
    elsif plural
      plural
    else
      "#{singular}s"
    end
  end
end
