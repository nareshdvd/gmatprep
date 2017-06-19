class AddScorePercentileToScoreSchemes < ActiveRecord::Migration
  def change
    add_column :score_schemes, :score_percentile, :float
  end
end
