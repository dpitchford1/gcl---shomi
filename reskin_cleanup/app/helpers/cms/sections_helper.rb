module Cms::SectionsHelper
  def section(name, args ={auto_generate: true}, &block)
    key = args[:auto_generate] ? "#{params[:controller]}-#{params[:action]}-#{name}" : name.to_s
    key.gsub! /\//, '-'
    version = Cms::Section.current_version(key)
    begin
      content = ERB.new(version.try(:code)).result(binding).html_safe  if version
    rescue SyntaxError => e
      content = 'Syntax error'
    end
    content ||= capture(&block)
    if params['mercury_frame']
      "<div class='clear' id='#{key}' data-version='#{version.try(:version)}' data-mercury='markdown' data-controller='#{params[:controller]}' data-action='#{params[:action]}' data-pageid='#{params[:id]}' data-code='#{ERB::Util.html_escape version.try(:code)}'>#{content}</div>".html_safe
    else
      content
    end
  end


end
