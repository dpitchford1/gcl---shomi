class SurveyQuestion < Portal
  attribute :survey_type
  attribute :survey_id
  attribute :question_id
  attribute :desc_en
  attribute :desc_fr

  index :survey_type
  index :survey_id
  index :question_id

  set :survey_options, :SurveyOption

  def description(lang = 'en')
    try("desc_#{lang}")
  end
end