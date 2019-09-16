class RedemptionSummaryHeader < HeaderPresenter
  attr_accessor :objects

  def initialize(*objects)
    super
    @objects = build_objects_hash(*objects)
    layout[:column_ratio] = [[6], [6], [6]]
  end

  def inner_div_class(column, row)
    classes = []
    if left_half(column)
      if row == 0
        classes << 'text-center'
      elsif row == 1
        classes << 'region form-errors text-center'
      elsif row == 2
        if flash[:notice_is_promo_code]
          classes << 'hidden'
        end
      end
    else
      # right side
    end
    classes.join(' ')
  end

  def inner_div_content(column, row)
    content = []
    if left_half(column)
      if row == 0
        content << I18n.t('header.register.redeem_your')
      elsif row == 1
        if flash[:notice_is_promo_code]
          content << "<p class='cc'>#{I18n.t("register.redemption.#{flash[:notice_is_promo_code] == 'expired' ? 'expired' : 'invalid'}")}</p>"
          content << "#{I18n.t('orders.or')} #{link_to I18n.t("profiles.profile_form.new_user_question"), Rails.application.routes.url_helpers.profile_email_check_path}" unless current_session.try(:logged?)
        end
      end
    else
      # right side
    end
    content
  end

  def inner_div_partials(column, row)
    partials = []
    if left_half(column)
      if row == 2
        partials << { name: 'layouts/messages' }
      end
    else
      # right side
    end
    partials
  end
end