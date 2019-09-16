class SurveyResult < Portal
  attribute :survey_id
  attribute :question_id
  attribute :option_id
  attribute :comments

  index :option_id

  def remote_save
    result = api_client.submit_cancellation_survey(self.attributes.merge({option_id: option_id.blank? ? '' : option_id }))

    if result && result[:result_code] == 0
      if result[:save_customer_survey_response] && result[:save_customer_survey_response][:promo_offer]
        promo = result[:save_customer_survey_response][:promo_offer]
        product = if promo[:valid_products].to_s.match(/nextissue/i)
                    'nextissue'
                  elsif promo[:valid_products].to_s.match(/shomi/i)
                    'shomi'
                  elsif promo[:valid_products].to_s.match(/gcl/i)
                    'gcl'
                  end
        cancel_survey_promo = PromoCode.new({code: promo[:coupon_code],
                                             desc_en: promo[:desc_en].to_s.to_valid_utf8, desc_fr: promo[:desc_fr].to_s.to_valid_utf8,
                                             valid_for_offer_type: promo[:valid_tiers],
                                             valid_for_product: product,
                                             code_type: promo[:promo_type], image_url: promo[:image_url]})
        cancel_survey_promo.save
        background_params[:cancel_survey_promo] = cancel_survey_promo
      end

      background_params[:survey_selection] = option_id.to_s
      background_params[:redirect], background_params[:notice_type] = [cancel_order_subscription_path, :notice]
      background_params[:notice] = option_id.blank? ? '' : I18n.t('cancel_order.submit_survey_success')
    elsif result.nil?
      background_params[:redirect], background_params[:notice_type], background_params[:notice] = [cancel_subscription_survey_path, :alert, I18n.t('pages.background.service_unavailable')]
      return false
    else
      background_params[:redirect], background_params[:notice_type], background_params[:notice], background_params[:developer_message] = [cancel_subscription_survey_path, :alert, result["msg_#{lang}".to_sym], result[:msg_dev]]
      return false
    end
    true
  end
end