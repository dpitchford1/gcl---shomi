class WelcomeUserSummaryHeader < HeaderPresenter
  attr_accessor :objects

  def initialize(*objects)
    super
    @objects = build_objects_hash(*objects)
    if I18n.locale == :fr
      layout[:column_ratio] = [[2, 4], [4, 2], [6], [6]]
    else
      layout[:column_ratio] = [[3, 3], [3, 3], [6], [6]]
    end
  end

  def inner_div_class(column, row)
    classes = []
    if left_half(column)
      #left side
      if row == 2
        classes << 'float-left'
      end
    else
      # right side
      if row == 0 || row == 1
        classes << 'float-right'
      end
    end
    classes.join(' ')
  end

  def inner_div_content(column, row)
    content = []

    if left_half(column)
      if row == 0
        content << you_are_subscribed_to_text

      elsif row == 1 && order.nil? && display_free_trial_offer
        content << free_thirty_day_free_trial_text

      elsif row == 2
        content << redemption_error_alert if redemption_error_alert.present?

      elsif row == 3 && !current_session.try(:profile).try(:disable_loyalty?) && !current_session.try(:profile).try(:eligible?)
        content += build_loyalty_logo
      end
    else
      # right side
      if row == 0
        content << "<h5>#{upgrade_downgrade_link} #{cancel_or_reactivate_link}</h5>"

      elsif row == 1 && order.nil? && display_free_trial_offer
        content << update_billing_info_link

      end
    end
    content
  end

  def inner_div_partials(column, row)
    partials = []
    latest_order = current_session.try(:latest_order)

    if left_half(column)
      if row == 0
        if current_session.try(:profile).try(:eligible?)
          unless Admin::FeatureFlag.feature_flag(:cancel_survey)
            partials << { name: 'orders/cancel_subscription_modal', locals: { order: latest_order, subscription_desc: latest_order.try(:short_description).to_s, profile: current_session.try(:profile) } }
          end
          partials << { name: 'orders/update_subscription_modal', locals: { existing_offer_type: current_session.profile.basic? ? 'basic' : 'premium' } }
        end
      elsif row == 2
        if !creditcard.nil?
          partials << {name: 'layouts/form_error_header', locals: {object: creditcard}}
        else
          partials << {name: 'layouts/form_error_header', locals: {object: latest_order}} unless latest_order.nil?
        end
      end
    end

    partials
  end

  def headers(column, row)
    headers = []
    if left_half(column)
      if row == 0
        headers << I18n.t('header.hello', name: current_session.try(:username).to_s)
      end
    else
      # right side
    end
    headers
  end

  def col_class(column, row)
    if row == 0
      'col'
    elsif row == 1 || row == 2
      'col no-margin'
    else
      ''
    end
  end

  def row_class(row)
    return '' if !ENV['free_thirty_day_trial']
    if row == 0 && order.nil? && display_free_trial_offer
      'bottom-hr top-bottom-spacing-extra-bottom'
    elsif flash[:notice_type].present? && row == 1
      'bottom-hr top-bottom-spacing extra_free_subscription'
    else
      ''
    end
  end
end