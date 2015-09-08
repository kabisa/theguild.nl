module PostHelpers
  # Returns an array of posts from the same category
  def related_posts(post)
    categories_ids = Array(post.categories).map(&:id)

    @posts.select do |p|
      p != post && (Array(p.categories).map(&:id) & categories_ids).present?
    end
  end

  # Limits the array to 2 elements and adds recent posts
  # if there are not enough related posts
  #
  # (copied from `website-kabisa-nl` and optimized)
  def similar_posts(post)
    related_posts = related_posts(post)
    completion = (@posts - [post]).first(2)

    (related_posts | completion).first(2)
  end
end
