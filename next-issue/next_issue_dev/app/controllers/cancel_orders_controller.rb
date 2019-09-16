class CancelOrdersController < ApplicationController
  before_action :redirect_if_not_logged

  def cancel_subscription_survey
    @question = SurveyQuestion.find(survey_type: 'cancel').first
    @options = @question.survey_options
    default_survey_result_attributes = {survey_id: @question.survey_id, question_id: @question.question_id}

    if params[:survey_result]
      @survey_result = SurveyResult.new(default_survey_result_attributes.merge(survey_result_params))

      if @survey_result.valid?

        background_notice!(t('cancel_order.submitting_survey_message'))
        HardWorker.perform_async(session.id, :submit_cancellation_survey, @survey_result.attributes.merge({current_url: request.referer}))
        respond_to do |format|
          format.js { render 'pages/background_job' }
        end
      else
        respond_to do |format|
          format.json { render json: {name: @survey_result.class.to_s.underscore, errors: @survey_result.errors.messages } }
        end
      end
    else
      @survey_result = SurveyResult.new(default_survey_result_attributes)
    end
  end

  def cancel_order_subscription
    @tos = Tos.get_tos({id: "#{ENV['APP_NAME']}cancelpromo" })

    if session[:cancel_survey_promo] && (@current_session.profile.has_promo_code_in_history?(session[:cancel_survey_promo].code) || !@current_session.profile.user_has_billing_info?)
      session[:cancel_survey_promo] = nil
    end
  end

  def cancel_order
    respond_to do |format|
      if order_params[:order_id].present?
        # Remove promo code from session to send user back to profiles index instead of promo contact
        session[:cancel_survey_promo] = nil
        format.js {
          background_notice!(t('orders.notice.cancelling_subscription'))
          HardWorker.perform_async(session.id, :cancel_order, order_params.merge({ billing_cycle_end_date: @current_session.latest_order.next_billing_cycle_date }))
          render 'pages/background_job'
        }
      else
        messages = {}
        messages[:order_id] = ["missing order id"]
        format.json { render json: {name: 'order', errors: messages } }
      end
    end
  end

  def apply_cancel_promo
    respond_to do |format|
      if order_params[:order_id].present?
        background_notice!(t('cancel_order.applying_cancel_discount'))

        HardWorker.perform_async(session.id, :apply_promo_code, order_params.merge({ promo_code: session[:cancel_survey_promo].code, code_type: session[:cancel_survey_promo].code_type, desc: session[:cancel_survey_promo].desc(I18n.locale) }) )

        format.js { render 'pages/background_job' }
      else
        messages = {}
        messages[:order_id] = ["missing order id"]
        format.json { render json: {name: 'order', errors: messages } }
      end
    end
  end

  def survey_result_params
    params.require(:survey_result).permit(:survey_id, :question_id, :option_id, :comments).symbolize_keys
  end

  def order_params
    params.require(:order).permit(:existing_offer_type, :order_id, :phone_number, :promo_code, :code_type, :desc, :full_name, :first_name, :last_name, :street, :city, :postal_code, :billing_option, :province, :cc_token, :auto_renew, :campaign_identifier,
                                  :cancellation_reason, :loyalty_code, :membership_number, :membership_type, :optin, :optin_account_token, :tos, :tos2, :rogers_account_token, :offer_id, :optin_email, :masked_cc, :cc_type, :validate, :birthdate, birthdate: []).symbolize_keys
  end
end
