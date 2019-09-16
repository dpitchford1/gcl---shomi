class Cms::SectionsController < CmsController
  layout false

  def preview
    @current_session = session[:session] || Session.new
    Portal.current_session = @current_session
    @session = @current_session  # For modal sign in

    result = {}
    params.each do |k,v|
      next unless v['data']
      @page = Cms::Page[v['data']['pageid']]
      eval @page.controller if @page && !@page.controller.blank?
      locals = {  }
      self.instance_variable_names.each {|v| locals[v.gsub('@', '').to_sym] = self.instance_variable_get(v)}
      # Have to do some hacking for preview, since we have local and instance variables session/@session
      locals[:session] = session
      result[k] = (view_context.render(inline: v['data']['code'].blank? ? v['value'] : v['data']['code'], session: @session, locals: locals) rescue nil) || '-'
    end

    render json: result
  end

  def add_version
    section = Cms::Section.find(name: params[:section]).first
    Cms::Section::Version.create(code: '', section: section, version: Time.now)
    render json: { result: 'ok' }
  end

  def delete_version
    section = Cms::Section.find(name: params[:section]).first
    section.versions.find(version: params[:version]).each { |v| v.delete }
    render json: { result: 'ok' }
  end


  def export
    data = {sections: [], pages: []}
    Cms::Section.all.each do |s|
      versions = []
      s.versions.each do |v|
        versions << v.attributes
      end
      data[:sections] << s.attributes.merge({versions: versions})
    end
    Cms::Page.all.each do |p|
      data[:pages] << p.attributes
    end
    response.header["Content-type"] = 'application/octet-stream'
    response.header["Content-Disposition"] = "attachment; filename=\"portal-cms-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.json\""
    render json: data
  end

  def import
    uploaded_io = params[:file]
    if uploaded_io
      json = JSON.parse uploaded_io.read
      $redis.keys("Cms:*").each { |k| $redis.del(k) }
      json['sections'].each do |s|
        versions = s.delete('versions')
        section = Cms::Section.create(s)
        versions.each do |v|
          Cms::Section::Version.create(v.merge({section: section}))
        end
      end
      json['pages'].each do |p|
        page = Cms::Page.create(p)
      end    
      redirect_to admin_root_path, notice: 'CMS successfully imported'
    else
      redirect_to admin_root_path, notice: 'Choose CMS file first'
    end
  end
  
end