module PostHelpers
  # Returns an array of posts from the same category
  def related_posts(post, posts)
    category_ids = Array(post.categories).map(&:id)
    other_posts  = posts - [post]

    other_posts.select do |p|
      next if (other_categories = p.categories).nil?

      (other_categories.map(&:id) & category_ids).present?
    end
  end

  # Limits the array to 2 elements and adds recent posts
  # if there are not enough related posts
  #
  # (copied from `website-kabisa-nl` and optimized)
  def similar_posts(post, posts, limit=2)
    related_posts = related_posts(post, posts)
    # In case we found < limit:
    completion    = (posts - [post]).first(limit)

    (related_posts | completion).first(limit)
  end
end
