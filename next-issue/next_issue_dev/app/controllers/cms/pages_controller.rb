class Cms::PagesController < CmsController
  layout 'plain'
  before_action :set_page, only: [:show, :edit, :update, :destroy]

  def index
    @pages = Cms::Page.all
  end

  def new
    @page = Cms::Page.new
  end

  def create
    @page = Cms::Page.new(page_params)

    if @page.valid? && @page.save
      DynamicRouter.reload
      redirect_to cms_pages_path, notice: 'Page was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

 def update
    if @page.update(page_params)
      $redis.keys("cache:#{fragment_cache_key(controller: 'cms/pages', action: 'show', id: @page.id)}\\?*").each { |k| $redis.del(k) }

      DynamicRouter.reload
      redirect_to edit_cms_page_path(@page), notice: 'Page was successfully updated.'
    else
      render :edit
    end
  end

  def show
    @current_session = session[:session] || Session.new
    Portal.current_session = @current_session
    @session = @current_session  # For modal sign in

    eval @page.controller unless @page.controller.blank?
    render inline: "<%= section(@page.slug) do %>#{@page.body}<% end %>", layout: @page.layout.blank? ? 'application' : @page.layout
  end

  def destroy
    @page.delete
    redirect_to cms_pages_path, notice: 'Page was successfully destroyed.'
  end

  def mercury_update
    params[:content].each do |k,v|
      Cms::Section.save(k, v)
      $redis.keys("cache:#{fragment_cache_key(controller: "/#{v['data']['controller']}", action: v['data']['action'], id: v['data']['pageid'].blank? ? nil : v['data']['pageid'])}\\?*").each { |k| $redis.del(k) }
    end
    respond_to do |format|
      format.json { render json: {result: 'ok'} }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = Cms::Page[params[:id]]
    end

    # Only allow a trusted parameter "white list" through.
    def page_params
      params.require(:cms_page).permit(:controller, :title, :slug, :body, :layout)
    end

end