FactoryGirl.define do
  factory :survey_question do
    survey_type 'Cancel'
    survey_id 'testsurvey1234'
    question_id 'testquestion1234'
    desc_en 'Before you go, can you let us know why you are cancelling? This will help us improve our service.'
    desc_fr 'Avant de nous quitter, pourriez-vous nous dire pourquoi vous annulez votre abonnement? Vous nous aideriez ainsi à améliorer notre service.'
  end
end