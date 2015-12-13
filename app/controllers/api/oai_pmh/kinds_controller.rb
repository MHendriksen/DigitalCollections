class Api::OaiPmh::KindsController < Api::OaiPmh::BaseController

  def get_record
    @record = locate(params[:identifier])
    render :template => "api/oai_pmh/get_record"
  end

  protected

    def records
      Kind.scoped
    end

    def base_url
      api_oai_pmh_kinds_url
    end

    def earliest_timestamp
      model = records.order(:created_at).first
      model ? model.created_at : super
    end

end