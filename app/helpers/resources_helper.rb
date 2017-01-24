module ResourcesHelper
  def print_res_list(collection)
    collection.map do |res|
      next unless res.is_a?(Resource)

      link_to res.name, resource_overview_path(res.username)
    end.compact.join(', ')
  end
end