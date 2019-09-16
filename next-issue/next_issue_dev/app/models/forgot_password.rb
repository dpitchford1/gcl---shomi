class ForgotPassword < Portal
  attr_accessor :email_address, :password_hint, :password_answer

  validates_presence_of :email_address, :if => -> { !password_hint }
  validates_format_of :email_address, with: RubyRegex::Email, :if => -> { !password_hint }
  validates_presence_of :password_answer, :if => -> { password_hint }

  def password_hint!
    begin
      result = api_client.password_hint(uid_or_email: email_address)
      question = Question.find(question_id: result[:hint_question]).first
      @password_hint = question.send("question_#{lang}") if question
      background_params[:redirect] = forgot_password_hint_path
    rescue GodzillaApi::Exception => e
      api_error = e.error
      err_msg = (api_error[:code] == 4048) ? I18n.t('form.error_label.username_no_match') : api_error[lang.to_sym]
      self.errors[:base] << err_msg
      background_params[:redirect]    = forgot_password_path
      background_params[:notice]      =  I18n.t('profiles.error.not_found')
      background_params[:notice_type] = :alert
      background_params[:developer_message] = api_error[:dev]
    end
    self
  end

  def password_answer?
    begin
      api_client.forget_password(uid_or_email: email_address, answer: password_answer)
      profile = Portal.current_session.profile
      if profile
        profile.login_attempts = 0
        profile.last_login_attempt = Time.now
        profile.save
      end
    rescue GodzillaApi::Exception => e
      api_error = e.error
      err_msg = (api_error[:code] == 3075) ? I18n.t('form.error_label.wrong_security_answer') : api_error[lang.to_sym]
      self.errors[:base] << err_msg
      background_params[:redirect] = forgot_password_hint_path
      background_params[:developer_message] = api_error[:dev]
      return false
    end
    background_params[:email_address] =  email_address
    background_params[:msg_type]      = :password_email_confirmation
    background_params[:redirect]      = msg_path
    background_params[:notice_type]   = :notice
    background_params[:notice]        =  I18n.t('pages.email_sent.check')
    true
  end

end