class Nextissue::RegisterController < ApplicationController

  def rogers_sign_in_or_up
    @offer = Offer.current_offer(offer_id: session[:offer_id])
    @profile = Profile.new
    @session = extract_object(:session) || Session.new
  end

  def redemption
    if @current_session.try(:logged?)
      membership_type = "redemption"
      tos_id = Tos.get_tos_id_for_membership(membership_type)
      tos_params = {id: tos_id}
      tos_params[:version] = @current_session.profile.tos_version if @current_session.try(:profile).try(:tos_version)
      @tos = Tos.get_tos(tos_params)
    end
  end

  def redemption_code_check
    background_notice!(t('profiles.verifying_promo_code'))
    HardWorker.perform_async(session.id, :redemption_code?, {code: params[:redemption_code][:code], current_url: request.referer})
    respond_to do |format|
      format.js { render 'pages/background_job' }
    end
  end
end