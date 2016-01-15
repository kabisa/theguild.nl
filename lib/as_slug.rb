# require and include this module
# to define as slugged version of an attribute.
module AsSlug
  def as_slug(obj, attr)
    obj.set("#{attr}AsSlug", obj.get(attr).parameterize)
  end
end
