module TextHelpers
  # Show the length and average reading time of
  # the passed `content`
  #
  # @param [String] content the content
  # @return [String] text showing the length and average reading time
  #
  # @example
  #   content_length_and_average_reading_time Array.new(500, 'lorem')
  #   #=> "500 words in about 2 minutes"
  def content_length_and_average_reading_time(content)
    content_length       = content_length content
    average_reading_time = average_reading_time content

    "#{content_length} in about #{average_reading_time}"
  end

  # Show the average reading time of
  # the passed `content`
  #
  # @param [String] content the content
  # @return [String] text showing average reading time
  #
  # @example
  #   average_reading_time Array.new(500, 'lorem')
  #   #=> "2 minutes"
  def average_reading_time(content)
    words_per_minute = 250
    word_count       = word_count content
    minutes          = (word_count / Float(words_per_minute)).ceil
    unit             = minutes == 1 ? 'minute' : 'minutes'

    "#{minutes} #{unit}"
  end

  # Show the length of the passed `content`
  #
  # @param [String] content the content
  # @return [String] text showing the length
  #
  # @example
  #   content_length Array.new(500, 'lorem')
  #   #=> "• 500 words"
  def content_length(content)
    word_count = word_count content
    "#{word_count} words"
  end

  def word_count(content)
    content.split.count
  end
end
