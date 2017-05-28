class PapersQuestion < ActiveRecord::Base
  belongs_to :paper
  belongs_to :question
  belongs_to :option
end
