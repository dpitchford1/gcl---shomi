class DataLayerBuilder
  attr_accessor :layers

  def initialize(params={})
    @layers = []
    @event_text = 'revent'
    @params = params
    @language = params[:language].to_s
    @offer_type = if params[:offer_is_basic].nil? || params[:offer_is_basic]
                   'basic'
                 else
                   'premium'
                 end

    setup_new_user_funnel_layers
    setup_existing_user_funnel_layers
    setup_redemption_funnel_layers
    setup_change_plan_layers
    setup_key_website_action_layers
    setup_error_layers
  end

private

  def setup_new_user_funnel_layers
    category = "#{@language} new user funnel"
    if logged? && !has_rogers_account?
      if @params[:flash] && @params[:flash][:notice] == I18n.t('profiles.new_profile_success')
        @layers << {event: @event_text, eventCategory: category, eventAction: '2 account creation', eventLabel: 'created new account', userId: @params[:current_session].guid }
      end

      if ['/orders', '/orders/new'].include?(@params[:current_path]) && !eligible?
        # user just created account, or logged into new account
        @layers << {event: @event_text, eventCategory: category, eventAction: '3 billing info start', eventLabel: @offer_type, userId: @params[:current_session].guid }
      elsif ['/orders/callback', '/orders/summary'].include?(@params[:current_path]) && !@params[:session][:promo_code].try(:is_valid_redemption?) && !eligible?
        # not redemption flow
        # new user just submitted their info to zuora, or selected a rogers account
        @layers << {event: @event_text, eventCategory: category, eventAction: '5 confirm subscription', eventLabel: @offer_type }
      elsif ['/profiles'].include?(@params[:current_path])
        unless @params[:flash][:notice].blank?
          if latest_order.try(:status).to_s.downcase == 'new' && I18n.t('orders.notice.success') == @params[:flash][:notice]
            # new latest order, and notice says the order was successful (not just regular login)
            event_label = get_event_label_with_loyalty_and_coupon
            couponCode = @params[:current_session].try(:profile).try(:promotion_code).blank? ? '' : @params[:current_session].profile.promotion_code
            loyaltyNumber = @params[:current_session].try(:profile).try(:loyalty_membership_number).blank? ? '' : @params[:current_session].profile.loyalty_membership_number

            @layers << {event: @event_text, eventCategory: category, eventAction: '6 complete subscription', eventLabel: event_label, accountNumber: latest_order.order_id, couponCode: couponCode, loyaltyNumber: loyaltyNumber }
          end
        end
      end
    else
      # unregistered user
      if ['/register'].include?(@params[:current_path]) && !@params[:session][:promo_code].try(:is_valid_redemption?)
        @layers << { event: @event_text, eventCategory: category, eventAction: '1 create account', eventLabel: @offer_type }
      end
    end
  end

  def setup_existing_user_funnel_layers
    category = "#{@language} existing user funnel"
    if logged? && has_rogers_account?
      if @params[:flash] && @params[:flash][:notice] == I18n.t('profiles.new_profile_success')
        @layers << {event: @event_text, eventCategory: category, eventAction: '2 account creation', eventLabel: 'used rogers account', userId: @params[:current_session].guid }
      end

      if ['/orders', '/orders/new'].include?(@params[:current_path]) && !eligible?
        # on the page to update billing
        if @params[:order].try(:billing_option) == 'rogersbill'
          @layers << {event: @event_text, eventCategory: category, eventAction: '3a add to bill or use card', eventLabel: @offer_type, userId: @params[:current_session].guid }
        else
          @layers << {event: @event_text, eventCategory: category, eventAction: '3b add card details', eventLabel: @offer_type, userId: @params[:current_session].guid }
        end
      elsif ['/orders/callback', '/orders/summary'].include?(@params[:current_path]) && !@params[:session][:promo_code].try(:is_valid_redemption?) && !eligible?
        # not redemption flow, credit card or rogers billing order confirmation
        @layers << {event: @event_text, eventCategory: category, eventAction: '4 confirm subscription', eventLabel: @offer_type }
      elsif '/profiles' == @params[:current_path]
        unless @params[:flash][:notice].blank?
          if latest_order.try(:status).to_s.downcase == 'new' && I18n.t('orders.notice.success') == @params[:flash][:notice]
            # new latest order, and notice says the order was successful (not just regular login)
            event_label = latest_order.billing_option == 'cc' ? 'card billing' : 'rogers billing'
            event_label = "#{event_label} : #{get_event_label_with_loyalty_and_coupon}"
            couponCode = @params[:current_session].try(:profile).try(:promotion_code).blank? ? '' : @params[:current_session].profile.promotion_code
            loyaltyNumber = @params[:current_session].try(:profile).try(:loyalty_membership_number).blank? ? '' : @params[:current_session].profile.loyalty_membership_number

            @layers << {event: @event_text, eventCategory: category, eventAction: '5 complete subscription', eventLabel: event_label, accountNumber: latest_order.order_id, couponCode: couponCode, loyaltyNumber: loyaltyNumber }
          end
        end
      end
    else
      # unregistered user
      if '/rogers_sign_in_or_up' == @params[:current_path]
        @layers << { event: @event_text, eventCategory: category, eventAction: '1 email existing or new', eventLabel: @offer_type }
      end
    end
  end

  def setup_redemption_funnel_layers
    category = 'redemption funnel'
    if logged?
      if @params[:flash] && @params[:flash][:notice] == I18n.t('profiles.new_redemption_profile_success')
        @layers << {event: @event_text, eventCategory: category, eventAction: '3 account creation', eventLabel: has_rogers_account? ? 'used rogers account' : 'created new account', userId: @params[:current_session].guid }
      end

      if '/profiles' == @params[:current_path]
        unless @params[:flash][:notice].blank?
          if latest_order.try(:status).to_s.downcase == 'new' && I18n.t('orders.notice.applied_promo_code_success') == @params[:flash][:notice]
            # new latest order, and notice says the order was successful (not just regular login)
            if @params[:current_session].profile.user_orders.size == 1
              # if the user entitlements have redemption, then this is completing a redemption order
              if @params[:current_session].profile.has_redemption?
                @layers << { event: @event_text, eventCategory: category, eventAction: '5 complete subscription', eventLabel: @params[:current_session].profile.promotion_code.to_s.gsub(/\"/, '').gsub(/\'/, ''), userId: @params[:current_session].guid, accountNumber: latest_order.order_id }
              end
            end
          end
        end
      elsif '/orders/promo_contact' == @params[:current_path] && @params[:session] && @params[:session][:promo_code].try(:is_valid_redemption?)
        # logged, on the promo contact form, either the user was just created and entered a redemption code, or they just logged in and entered a redemption code
        @layers << { event: @event_text, eventCategory: category, eventAction: '4 enter personal details', eventLabel: @params[:session][:promo_code].code }
      elsif ['/', '/redemption'].include?(@params[:current_path]) && @params[:session]
        @layers << { event: @event_text, eventCategory: category, eventAction: '1 enter redemption code', eventLabel: @params[:session][:promo_code].try(:valid?) ? @params[:session][:promo_code].code : '', userId: @params[:current_session].guid }
      end
    else
      # unregistered user
      if '/register' == @params[:current_path]
        if  @params[:session] && @params[:session][:promo_code].try(:is_valid_redemption?)
          @layers << { event: @event_text, eventCategory: category, eventAction: '2 enter email', eventLabel: @params[:session][:promo_code].code }
        end
      elsif ['/', '/redemption'].include?(@params[:current_path]) && @params[:session]
        @layers << { event: @event_text, eventCategory: category, eventAction: '1 enter redemption code', eventLabel: @params[:session][:promo_code].try(:is_valid_redemption?) ? @params[:session][:promo_code].code : '' }
      end
    end
  end

  def setup_change_plan_layers
    category = 'change plan'
    if logged? && @params[:flash] && @params[:flash][:notice].present?
      if '/profiles' == @params[:current_path]
        if latest_order.try(:status).to_s.downcase == 'downgraded' && I18n.t('orders.update_offer.basic') == @params[:flash][:notice]
          # Can't know if the '1 opened change plan' event occurs on page load, this would need to be added to the on click event of the 'upgrade/downgrade' button
          # downgraded plan successful event
          @layers << {event: @event_text, eventCategory: category, eventAction: 'change plan', eventLabel: latest_order.status }

        elsif latest_order.try(:status).to_s.downcase == 'upgraded' && I18n.t('orders.update_offer.premium') == @params[:flash][:notice]
          # upgraded plan successful event
          @layers << {event: @event_text, eventCategory: category, eventAction: 'change plan', eventLabel: latest_order.status }

        elsif latest_order.try(:status).to_s.downcase == 'cancelled'
          if Admin::FeatureFlag.feature_flag(:cancel_survey)
            next_billing_date = latest_order.next_billing_cycle_date.strftime('%d/%m/%Y') rescue ''
            if I18n.t('orders.cancel_survey_subscription', date: next_billing_date) == @params[:flash][:notice]
              # cancel survey plan successful event
              @layers << {event: @event_text, eventCategory: category, eventAction: 'change plan', eventLabel: latest_order.status }
            end
          else
            if I18n.t('orders.cancel_subscription') == @params[:flash][:notice]
              # cancel plan successful event
              @layers << {event: @event_text, eventCategory: category, eventAction: 'change plan', eventLabel: latest_order.status }
            end
          end

        elsif I18n.t('cancel_order.successfully_applied_promo') == @params[:flash][:notice]
          # cancel discount promotion successful event
          @layers << {event: @event_text, eventCategory: category, eventAction: 'cancel survey', eventLabel: 'saved_with_promo' }

        end
      elsif '/cancel_order_subscription' == @params[:current_path] && I18n.t('cancel_order.submit_survey_success') == @params[:flash][:notice]
        # cancel survey submission success
        @layers << {event: @event_text, eventCategory: category, eventAction: 'cancel survey', eventLabel: @params[:session][:survey_selection].blank? ? 'skipped' : @params[:session][:survey_selection], userId: @params[:current_session].guid }

      end
    end
  end

  def setup_key_website_action_layers
    category = 'key website actions'
    if logged? && '/profiles' == @params[:current_path] && @params[:flash][:notice] == I18n.t('sessions.logged_in')
      # if the user sees the successfully logged in message, send the sign ins event
      @layers << {event: @event_text, eventCategory: category, eventAction: 'sign ins', eventLabel: '', userId: @params[:current_session].guid }

    elsif !logged? && '/signin' == @params[:current_path] && @params[:flash][:alert] == I18n.t('sessions.notice.legacy_logged_out')
      # If the user just attempted to sign into a legacy rogers account that doesn't have any orders
      @layers << {event: @event_text, eventCategory: category, eventAction: 'errors', eventLabel: 'Legacy rogers account sign in error' }

    end
  end

  def setup_error_layers
    if @params[:flash] && @params[:flash][:alert]
      @layers << {event: @event_text, eventCategory: "errors", eventAction: "error #{@params[:flash][:developer_message].to_s.gsub(/\"/, '').gsub(/\'/, '')}", eventLabel: @params[:flash][:alert].to_s.gsub(/\"/, '').gsub(/\'/, '') }

    elsif  @params[:current_session] && @params[:current_session].errors.full_messages.any?
      @layers << {event: @event_text, eventCategory: "errors", eventAction: "error #{@params[:flash][:developer_message].to_s.gsub(/\"/, '').gsub(/\'/, '')}", eventLabel: I18n.t("form.errors.signin_error_title") }
    end
  end

  def logged?
    @params[:current_session].try(:logged?)
  end

  def latest_order
    @params[:current_session].try(:latest_order)
  end

  def eligible?
    @params[:current_session].profile.eligible?
  end

  def has_rogers_account?
    @params[:current_session].has_rogers_account?
  end

  def get_event_label_with_loyalty_and_coupon
    event_label = @offer_type

    unless @params[:current_session].try(:profile).try(:promotion_code).blank?
      event_label += " : coupon"
    end

    unless @params[:current_session].try(:profile).try(:loyalty_type).blank?
      event_label += " : loyalty : #{@params[:current_session].profile.loyalty_type.downcase.gsub(/\s/, '')}"
    end

    if event_label == @offer_type
      event_label += ' : regular'
    end

    event_label
  end
end