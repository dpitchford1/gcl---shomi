class UniquenessValidator < ActiveModel::Validator
  def validate(object)
    options[:attributes].each do |attribute|
      object.errors[attribute] = options[:message] || 'must be unique' if object.class.find(attribute => object.send(attribute)).count > 0
    end
  end
end