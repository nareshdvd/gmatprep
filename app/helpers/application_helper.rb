module ApplicationHelper
  def render_index_action(action_name, action_info, object_klass, object = nil, html = {})
    url_params = []
    url_params << object if !object.nil?
    return link_to action_info[0], send(object_klass.get_action_url_function(action_name), *url_params), method: (action_info[2].blank? ? :get : action_info[2]), class: html[:class]
  end

  def bootstrap_row
    content_tag(:div, class: "row") do
      yield
    end
  end

  def bootstrap_col(col, extra_classes="", offset = nil)
    classes = []
    class_protos= "col-sm-__ col-md-__ col-lg-__  col-xs-__"
    classes << extra_classes
    classes << class_protos.gsub("__", col.to_s)
    classes << class_protos.gsub("__", "offset-#{offset.to_s}") if offset.present?
    content_tag(:div, class: classes.join(" ")) do
      yield
    end
  end

  def bootstrap_panel(heading, panel_class="default")
    content_tag(:div, class: "panel panel-#{panel_class}") do
      concat(content_tag(:div, class: "panel-heading") do
        heading
      end)
      concat(content_tag(:div, class: "panel-body") do
        yield
      end)
    end
  end

  def dashboard_panel_row(key)
    bootstrap_row do
      concat(bootstrap_col(6) do
        key
      end)
      concat(bootstrap_col(6, "text-right") do
        yield
      end)
    end
  end
end
