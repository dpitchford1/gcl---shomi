class CancelSubscriptionHeader < HeaderPresenter
  attr_accessor :objects

  def initialize(*objects)
    super
    @objects = build_objects_hash(*objects)
    layout[:column_ratio] = [[4, 2], [6], [6]]
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
      if row == 0
        if surveyresult.nil?
          content << "<div><h4>#{I18n.t('cancel_order.cancel_or_allow_desc')}</h4></div>" if session[:cancel_survey_promo].try(:valid?)
        else
          content << "<div><h4>#{surveyquestion.try(:description, I18n.locale)}</h4></div>"
        end
      end
    else
      # right side
      if row == 0

        if surveyresult.nil?
          content << "<div><h4>#{I18n.t('cancel_order.step_2')}</h4></div>"
        else
          content << "<div><h4>#{I18n.t('cancel_order.step_1')}</h4></div>"
        end
      end
    end
    content
  end

  def headers(column, row)
    headers = []

    if left_half(column)
      if row == 0
        if surveyresult.nil?
          headers << "<div class='tiny-b-p'>#{session[:cancel_survey_promo].try(:valid?) ? I18n.t('cancel_order.top_header_title') : I18n.t('cancel_order.top_header_title_no_promo')}</div>"
        else
          headers << "<div class='tiny-b-p'>#{I18n.t('cancel_order.cancellation')}</div>"
        end
      end
    else
      # right side
    end
    headers
  end

  def col_class(column, row)
    row == 0 ? 'col' : ''
  end

end