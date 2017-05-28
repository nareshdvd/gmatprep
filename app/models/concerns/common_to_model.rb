module CommonToModel
  def get_action_url_function(action_name)
    return self.index_actions[action_name][1]
  end
end