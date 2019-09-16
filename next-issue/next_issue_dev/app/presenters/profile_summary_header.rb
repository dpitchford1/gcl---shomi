class ProfileSummaryHeader < HeaderPresenter
  attr_accessor :objects

  def initialize(*objects)
    super
    @objects = build_objects_hash(*objects)
    layout[:column_ratio] = [[3, 3], [6], [6]]
  end

  def inner_div_class(column, row)
    classes = []
    if left_half(column)
      if row == 1
        classes << 'float-right'
      end
    else
      # right side
      if row == 0
        classes << 'float-right'
      end
    end
    classes.join(' ')
  end

  def inner_div_content(column, row)
    content = []
    if left_half(column)
      if row == 1
        content += build_loyalty_logo
      end
    else
      # right side
    end
    content
  end

  def headers(column, row)
    headers = []

    if left_half(column)
      if row == 0
        headers += left_offer_header_summary
      end
    else
      # right side
      if row == 0
        headers += right_offer_header_summary
      end
    end
    headers
  end

  def inner_div_partials(column, row)
    partials = []

    if left_half(column) &&  row == 2
      partials << {name: 'layouts/messages'}
    end

    partials
  end

  def col_class(column, row)
    row == 0 ? 'col' : ''
  end
end