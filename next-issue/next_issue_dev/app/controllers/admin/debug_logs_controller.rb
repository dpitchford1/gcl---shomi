class Admin::DebugLogsController < AdminController
  #get "admin/debug_logs/(type/:type)/(api_call/:api_call)/(error_type/:error_type)"  => 'admin/debug_logs#index'
  require 'csv'
  before_action :get_logs

  def index
  end

  def download_csv
    respond_to do |format|
      format.html
      format.csv { render text: logs_to_csv(@logs) }
    end
  end

  def logs_to_csv(logs=[], options={})
    unless logs.empty?
      column_names = logs.model.column_names rescue []
      CSV.generate(options) do |csv|
        csv << column_names
        logs.each do |log|
          csv << log.attributes.values_at(*column_names)
        end
      end
    end
  end

  def get_logs
    finder_params = {}
    finder_params[:email] = params[:email] if params[:email].present?
    finder_params[:api_call] = '/' + params[:api_call] if params[:api_call].present?
    finder_params[:error_type] = params[:error_type] if params[:error_type].present?

    if params[:type] == 'godzilla'
      if finder_params.empty?
        @logs = DebugGodzilla.all
      else
        @logs = DebugGodzilla.find(finder_params)
      end
    else
      if finder_params.empty?
        @logs = DebugLog.all
      else
        @logs = DebugLog.find(finder_params)
      end
    end
  end
end