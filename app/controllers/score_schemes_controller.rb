class ScoreSchemesController < ApplicationController
  def index
    @score_schemes = ScoreScheme.order("deduction").all
  end

  def update_all
    respond_to do |format|
      scheme_update_params[:score_scheme].each do |score_scheme_params|
        if score_scheme_params[:id].present?
          if score_scheme_params[:_destroy].present?
            ScoreScheme.where(id: score_scheme_params[:id]).first.destroy
          else
            ScoreScheme.where(id: score_scheme_params[:id]).first.update_attributes(score_scheme_params.except(:id))
          end
        elsif score_scheme_params[:_destroy].blank?
          ScoreScheme.create(deduction: score_scheme_params[:deduction], score: score_scheme_params[:score], score_percentile: score_scheme_params[:score_percentile])
        end
      end
      format.html {redirect_to index_score_schemes_path}
    end
  end

  private

  def scheme_update_params
    params.require :score_scheme
    params.permit score_scheme: [:id, :deduction, :score, :score_percentile, :_destroy]
  end
end