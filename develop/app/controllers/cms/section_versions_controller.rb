class Cms::SectionVersionsController < CmsController
  layout false
  
  def index
    @section = Cms::Section.find(name: params[:section]).first
    @versions = @section ? @section.versions.sort_by(:version, order: 'DESC') : []
  end

  private

  def account_search_params
    params.require(:account_search).permit(:account_number, :postal_code, :first_name, :last_name, :birthdate, :account_pin, :search_type).symbolize_keys
  end

end