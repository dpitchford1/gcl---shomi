require 'spec_helper'

describe SurveyQuestion do
  let(:survey_question) { FactoryGirl.build(:survey_question) }

  context '#description' do
    it 'return english description without params' do
      survey_question.desc_en = 'some test description'
      expect(survey_question.description).to eql 'some test description'
    end

    it 'return french description with fr' do
      survey_question.desc_fr = 'some test description'
      expect(survey_question.description('fr')).to eql 'some test description'
    end

    it 'return nil when not en or fr' do
      expect(survey_question.description('something')).to eql nil
    end
  end
end
