module PostHelpers
  # Returns an array of posts from the same category
  def related_posts(post)
    category_ids = Array(post.categories).map(&:id)
    other_posts  = @posts - [post]

    other_posts.select do |p|
      next if (other_categories = p.categories).nil?

      (other_categories.map(&:id) & category_ids).present?
    end
  end

  # Limits the array to 2 elements and adds recent posts
  # if there are not enough related posts
  #
  # (copied from `website-kabisa-nl` and optimized)
  def similar_posts(post)
    related_posts = related_posts(post)
    completion    = (@posts - [post]).first(2)

    (related_posts | completion).first(2)
  end
end
