class Question < Portal
  attribute :question_id
  attribute :question_fr
  attribute :question_en

  index :question_id

  def self.collection(lang='en')
    all.map {|q| [q.send("question_#{lang}"), q.question_id]}
  end

  def question(lang='en')
  	q = (lang == 'en') ? question_en : question_fr
  end


end