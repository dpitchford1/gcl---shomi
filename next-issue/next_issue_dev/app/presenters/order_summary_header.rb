class OrderSummaryHeader < HeaderPresenter
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
    redemption_top_up = current_session.profile.can_top_up? && offer.try(:topup?)

    if left_half(column)
      if ENV['redemption_top_up'] && row == 0 && redemption_top_up
        content << "<div><h4>#{I18n.t('orders.redemption_top_up_description')}</h4></div>"
      end

      if row == 1 && !current_session.try(:profile).try(:disable_loyalty?) && !current_session.try(:profile).try(:eligible?)
        content += build_loyalty_logo
      end
    else
      # right side
    end
    content
  end

  def inner_div_partials(column, row)
    partials = []

    if left_half(column) && row == 2
      if !creditcard.nil?
        partials << {name: 'layouts/form_error_header', locals: {object: creditcard}}
      else
        partials << {name: 'layouts/form_error_header', locals: {object: order}} unless order.nil?
      end
    end
    partials
  end

  def headers(column, row)
    headers = []

    if left_half(column)
      if row == 0
        headers += left_offer_header_summary(true)
      end
    else
      # right side
      if row == 0
        headers += right_offer_header_summary
      end
    end
    headers
  end

  def col_class(column, row)
    row == 0 ? 'col' : ''
  end
end