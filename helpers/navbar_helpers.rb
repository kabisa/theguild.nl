module NavbarHelpers
  def navbar_items
    data.config.navbar
  end

  def navbar_item_class_name(request_path, item)
    # This does not work properly in dev mode
    # but in a built project
    # it looks as expected.
    request_path == "#{item.url}/index.html".gsub('//', '/') ? 'active' : nil
  end
end
