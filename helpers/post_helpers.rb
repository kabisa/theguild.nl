module PostHelpers
  # Limits the array to 2 elements and adds recent posts
  # if there are not enough related posts
  #
  # @return [Array<Post>] `limit` items, somehow related to `post`
  #
  # @param [Post] post the object we need related posts for
  # @param [Array<Post>] posts the collection to look for related posts
  # @param [FixNum] limit The number of items to return
  #
  # @example
  #   post = @posts.first
  #   similar_posts post, @posts
  def similar_posts(post, posts, limit=2)
    related_posts = related_posts(post, posts)
    # In case we found < limit:
    completion    = (posts - [post]).first(limit)

    (related_posts | completion).first(limit)
  end

  # Returns an array of posts from the same category
  #
  # @return [Array<Post>] items somehow related to `post`
  #
  # @param [Post] post the object we need related posts for
  # @param [Array<Post>] posts the collection to look for related posts
  #
  # @example
  #   post = @posts.first
  #   related_posts post, @posts
  def related_posts(post, posts)
    category_ids = Array(post.categories).map(&:id)
    other_posts  = posts - [post]

    other_posts.select do |p|
      next if (other_categories = p.categories).nil?

      (other_categories.map(&:id) & category_ids).present?
    end
  end

  def posts
    data.site.post.values.sort_by(&:created_on).reverse
  end
end
