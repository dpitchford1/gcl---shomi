class HeaderPresenter
  # to be able to use 'link_to' within child presenters
  include ActionView::Helpers::UrlHelper
  # to be able to use 'number_to_currency' within child presenters
  include ActionView::Helpers::NumberHelper
  # to be able to use 'image_tag' within child presenters
  include ActionView::Helpers::AssetTagHelper
  # methods to build common header portions between profile & order section
  include CommonHeaderElements

  attr_accessor :layout

  def initialize(*objects)
    # layout - return hash with the type of layout (simple-grid css layout)
    # rows - # of rows in the simple grid
    # column_ratio - ratio of simple grid (Example: 50% width - 50% width = [3,3])
    @layout = {type: 'simple-grid', column_ratio: [[3, 3], [3, 3]]}
  end

  def build_objects_hash(*objects)
    objs = {}

    objects.each do |o|
      unless o.nil?
        objs[o.class.to_s.downcase] = o
      end
    end

    objs
  end

  # specify class on the column divs
  def col_class(column, row)
    column > 0 ? 'col' : ''
  end

  def row_class(row)
    ''
  end

  # return true if we are dealing with the left half of the grid
  def left_half(column)
    column == 0
  end

  # return css classes wrapping the headers, regular div content, & partials
  def inner_div_class(column, row)
    ''
  end

  # return array of html strings to show within the specific column/row
  def inner_div_content(column, row)
    []
  end

  # return array of partial hashes containing name and/or locals
  # example partial: { name: 'path/to/partial', locals: { obj: { test: 'stuff' } } }
  # result in view: <%= render partial: 'path/to/partial', locals: { obj: { test: 'stuff' } } %>
  def inner_div_partials(column, row)
    []
  end

  # return array of html strings that will be wrapped in <h3 class="sm-b-mg">
  def headers(column, row)
    []
  end

  def method_missing(m, *args, &block)
    case m.to_s
      when 'session'
        @objects.fetch('actiondispatch::request::session', nil) || {}
      when 'flash'
        @objects.fetch('actiondispatch::flash::flashhash', nil) || {}
      when 'offer'
        @objects.fetch(m.to_s, nil) || Offer.current_offer({offer_id: ENV["#{session[:offer_type]}_offer_id"]})
      when 'current_session'
        @objects.fetch('session', nil)
      when 'order', 'creditcard', 'surveyresult', 'surveyquestion'
        @objects.fetch(m.to_s, nil)
      else
        super
    end
  end
end