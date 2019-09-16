module CommonHeaderElements
  # return 'in association with loyalty logo'
  def build_loyalty_logo
    loyalty_logo = []
    loyalty = session[:loyalty_code]

    if loyalty.try(:valid?)
      if offer.try(:basic?)
        if loyalty.try("valid_for_basic")
          loyalty_logo << "<p>#{I18n.t('orders.billing.in_association')} #{image_tag(loyalty.offer_logo_basic(I18n.locale), alt: "basic rewards logo")}</p>"
        end
      else
        if loyalty.try("valid_for_premium")
          loyalty_logo << "<p>#{I18n.t('orders.billing.in_association')} #{image_tag(loyalty.offer_logo_premium(I18n.locale), alt: "premium rewards logo")}</p>"
        end
      end
    end
    loyalty_logo
  end

  # return 'summary' and 'offer description - upgrade/downgrade?'
  def left_offer_header_summary(new_order_path=false)
    headers = []
    promo = session[:promo_code]
    redemption_top_up = promo.try(:is_valid_redemption?) && promo.basic_redemption? && !ENV['redemption_top_up']

    if offer
      headers << summary_text
      offer_desc = !promo.try(:is_valid_redemption?) ? '<strong>' + I18n.t("offers.description.#{offer.offer_id}") + '</strong>' : ""
      if promo.try(:is_valid_redemption?)
        redemption_desc = promo.description.blank? ? '' : "<p>#{promo.description}</p>"
        redemption_desc = "#{redemption_desc}<p>#{I18n.t('header.redemption_code')} #{promo.code}</p>"

      elsif !redemption_top_up
        # only show upgrade/downgrade? in header for new orders (existing orders can use the other upgrade/downgrade link to specifically upgrade/downgrade)
        # don't show the upgrade/downgrade? for redemption top up
        if order.try(:offer_id).nil?
          if offer.basic?
            if promo.nil? || promo.valid_for?('premium')
              change_offer_link = if new_order_path
                                    Rails.application.routes.url_helpers.new_order_path(order: {billing_option:  order.try(:billing_option) || 'cc'}, offer_type: 'premium')
                                  else
                                    Rails.application.routes.url_helpers.new_profile_path(offer_type: 'premium')
                                  end
              change_offer_text = I18n.t('buttons.upgrade_question')
            end
          else
            if promo.nil? || promo.valid_for?('basic')
              change_offer_link = if new_order_path
                                    Rails.application.routes.url_helpers.new_order_path(order: {billing_option:  order.try(:billing_option) || 'cc'}, offer_type: 'basic')
                                  else
                                    Rails.application.routes.url_helpers.new_profile_path(offer_type: 'basic')
                                  end
              change_offer_text = I18n.t('buttons.downgrade_question')
            end
          end

          offer_desc += link_to(change_offer_text, change_offer_link, :class => "btn btn-blk inline upgrade-left-margin lowercase") if change_offer_text.present? && change_offer_link.present?
        end
      end
      headers << offer_desc
      headers << redemption_desc unless redemption_desc.blank?
    end

    headers
  end

  # return 'subtotal' and $9.99 / month
  def right_offer_header_summary
    headers = []
    promo = session[:promo_code]
    session_redemption_top_up = promo.try(:is_valid_redemption?) && promo.basic_redemption?
    profile_redemption_top_up = current_session.try(:profile).try(:can_top_up?) && offer.try(:topup?)

    headers << subtotal_text
    price = if promo.try(:is_valid_redemption?)
              promo.price(offer)
            elsif ENV['redemption_top_up'] && (session_redemption_top_up || profile_redemption_top_up) && offer.try(:topup?)
              Offer.top_up_cost
            else
              offer.try(:price)
            end

    headers << price_text(price, offer.try(:frequency))
    headers
  end

  def summary_text
    '<span class="uppercase">' + I18n.t('header.summary') + '</span>'
  end

  def subtotal_text
    '<span class="uppercase">' + I18n.t('header.subtotal') + '</span>'
  end

  def price_text(price=0.0, freq='')
    "#{number_to_currency(price, separator: '.', delimiter: ',', unit: '$')} #{freq == 'monthly' ? ' / ' + I18n.t('date.month') : ''}"
  end

  def upgrade_to_premium_top_up_text
    offer_description = Offer.find(offer_id: ENV['premium_offer_id']).first.description(I18n.locale)
    "<h4><span class='upgrade_redemption'><p class='sm-t-mg'>#{I18n.t('orders.upgrade_redemption_for_cost_with_description', price: sprintf("%.2f", Offer.top_up_cost), alt_desc: offer_description).html_safe}</p></span></h4>"
  end

  def upgrade_downgrade_link
    # show upgrade/downgrade when the user has an order, is eligible, and does not have redemption in the entitlement
    if current_session.try(:latest_order).try(:order_id) && current_session.profile.try(:eligible?) && (!current_session.profile.has_redemption? || current_session.profile.on_top_up?)
      if basic_profile?
        link_to(I18n.t("buttons.upgrade"), '#update_subscription', role: "button", data: {toggle:'modal', target: '#update_subscription' }, class: 'btn btn-default change_plan_event') if profile_can_upgrade?
      else
        link_to(I18n.t("buttons.downgrade"), '#update_subscription', role: "button", data: {toggle:'modal', target: '#update_subscription' }, class: 'btn btn-cancel blue change_plan_event') if profile_can_downgrade?
      end
    end
    
  end

  def basic_profile?
    current_session.profile.basic?
  end

  def profile_can_upgrade?
    current_session.profile.promotion_valid_for?('premium')
  end

  def profile_can_downgrade?
    current_session.profile.promotion_valid_for?('basic')
  end
  
  def upgrade_basic_redemption_link
    if current_session.try(:user_has_billing_info?)
      link_to(I18n.t("buttons.upgrade"), '#update_subscription', role: "button", data: {toggle:'modal', target: '#update_subscription' }, class: 'btn btn-default change_plan_event')
    elsif current_session.try(:latest_order).try(:order_id) && current_session.try(:profile).try(:eligible?)
      if current_session.try(:has_rogers_account?)
        link_to I18n.t('buttons.upgrade'), Rails.application.routes.url_helpers.new_order_path({order: { billing_option: 'rogersbill', operation: Admin::FeatureFlag.feature_flag(:topup_order_operation) }, offer_type: 'topup' }), class: 'btn btn-default change_plan_event'
      else
        link_to I18n.t('buttons.upgrade'), Rails.application.routes.url_helpers.new_order_path({order: { billing_option: 'cc' }, operation: Admin::FeatureFlag.feature_flag(:topup_order_operation), offer_type: 'topup' }), class: 'btn btn-default change_plan_event'
      end
    end
  end

  def free_thirty_day_free_trial_text
    expiry_date = I18n.t('orders.add_billing_for_extra_free_subscription', expiration: current_session.profile.promotion_expiry_date.try(:strftime, '%d/%m/%Y'))
    "<h4><span class='extra_free_subscription'><p>#{expiry_date}</p></span></h4>"
  end

  def update_billing_info_link
    if current_session.try(:latest_order).blank?
      ''
    elsif current_session.try(:has_rogers_account?)
      link_to I18n.t('buttons.update'), Rails.application.routes.url_helpers.new_order_path({order: { billing_option: 'rogersbill', offer_id: ENV['basic_offer_id'], operation: 'update' }, offer_type: 'basic' }), class: 'btn btn-default'
    else
      link_to I18n.t('buttons.update'), Rails.application.routes.url_helpers.new_order_path({order: { billing_option: 'cc', offer_id: ENV['basic_offer_id'] }, operation: 'update', offer_type: 'basic' }), class: 'btn btn-default'
    end
  end

  def cancel_or_reactivate_link
    if current_session.try(:profile).try(:eligible?)
      if Admin::FeatureFlag.feature_flag(:cancel_survey)
        link_to I18n.t("buttons.cancel_subscription"), Rails.application.routes.url_helpers.cancel_subscription_survey_path, class: 'btn btn-cancel blue change_plan_event'
      else
        link_to I18n.t("buttons.cancel_subscription"), '#cancel_subscription', role: "button", data: { toggle:'modal', target: '#cancel_subscription' }, class: 'btn btn-cancel change_plan_event'
      end
    else
      link_to I18n.t("buttons.reactivate_subscription"), I18n.t("buttons.marketing_links.#{ENV['marketing_env']}.reactivation"), class: 'btn btn-cancel'
    end
  end

  def you_are_subscribed_to_text
    if current_session.try(:profile).try(:eligible?)
      "<h4>#{I18n.t('header.you_are_subscribed')} #{current_session.try(:latest_order).try(:short_description_backwards).to_s}</h4>"
    else
      "<h4>#{I18n.t('header.no_subscriptions')}</h4>"
    end
  end

  def redemption_error_alert
    if flash[:notice_is_promo_code]
      "<p class='cc'>#{I18n.t("register.redemption.#{flash[:notice_is_promo_code] == 'expired' ? 'expired' : 'invalid'}")}</p>"
    end
  end

  def display_free_trial_offer
    return false if !ENV['free_thirty_day_trial']
    promo_expiration = current_session.profile.promotion_expiry_date rescue nil
    promo_expiration && !current_session.profile.user_has_billing_info? && current_session.profile.has_redemption? && promo_expiration > Date.today
  end
end