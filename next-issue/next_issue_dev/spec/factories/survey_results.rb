FactoryGirl.define do
  factory :survey_result do
    survey_id 'testsurvey1234'
    question_id 'testquestion1234'
    option_id 'Too expensive.'
    comment "I can't afford this anymore!"
  end
end