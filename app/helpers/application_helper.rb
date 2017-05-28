module ApplicationHelper
  def render_index_action(action_name, action_info, object_klass, object = nil)
    url_params = []
    url_params << object if !object.nil?
    return link_to action_info[0], send(object_klass.get_action_url_function(action_name), *url_params), method: (action_info[2].blank? ? :get : action_info[2])
  end
end
