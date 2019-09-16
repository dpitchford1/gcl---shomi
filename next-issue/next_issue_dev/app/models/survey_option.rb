class SurveyOption < Portal
  attribute :question_id
  attribute :option_id
  attribute :desc_en
  attribute :desc_fr

  index :question_id
  index :option_id

  reference :survey_question, :SurveyQuestion

  def description(lang = 'en')
    try("desc_#{lang}")
  end
end