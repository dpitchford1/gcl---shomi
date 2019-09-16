require 'spec_helper'

describe SurveyOption do
  let(:survey_option) { FactoryGirl.build(:survey_option) }

  context '#description' do
    it 'return english description without params' do
      survey_option.desc_en = 'some test description'
      expect(survey_option.description).to eql 'some test description'
    end

    it 'return french description with fr' do
      survey_option.desc_fr = 'some test description'
      expect(survey_option.description('fr')).to eql 'some test description'
    end

    it 'return nil when not en or fr' do
      expect(survey_option.description('something')).to eql nil
    end
  end
end
