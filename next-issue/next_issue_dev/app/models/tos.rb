class Tos < Portal
  attribute :tos_id
  attribute :tos_version
  attribute :content_type
  attribute :tos_en
  attribute :tos_fr

  index :tos_id
  index :tos_version

  def self.get_tos(params = {})
    if !params[:version] && params[:id]
      # get the latest version of the given id
      Tos.find(tos_id: params[:id]).first(by: :tos_version, limit: [0, 1], order: 'DESC')
    elsif params[:version] || params[:id]
      # get the given version and/or id
      # Redis search doesn't work for 1.0, has to be 1
      tos_version =   params[:version] == params[:version].to_i ?  params[:version].to_i : params[:version]
      tos_id = params[:id] || ENV['tos_id'].to_s.split(',').first
      Tos.find(tos_id: tos_id, tos_version: tos_version).first
    else
      # get the latest version
      Tos.all.first(by: :tos_version, limit: [0, 1], order: 'DESC')
    end
  end

  def self.latest
    get_tos
  end

  # return tos id from loyalty type, or the app name
  def self.get_tos_id_for_membership(membership_type=nil)
    prefix = ENV['APP_NAME']
    if membership_type == 'Air Miles'
      prefix.to_s + 'airmiles'
    elsif membership_type == 'Scene'
      prefix.to_s + 'scene'
    elsif membership_type == 'VIA Préférence'
      prefix.to_s + 'via'
    elsif membership_type == 'redemption'
      prefix.to_s + 'promotion'
    elsif membership_type == 'applyredemption'
      prefix.to_s + 'applypromotion'
    elsif membership_type == 'Charger'
      prefix.to_s + 'blockfreetrial'
    else
      prefix.to_s
    end
  end
end