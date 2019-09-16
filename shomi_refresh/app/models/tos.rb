class Tos < Portal
  attribute :tos_id
  attribute :tos_version
  attribute :content_type
  attribute :tos_en
  attribute :tos_fr

  index :tos_id
  index :tos_version

  def self.get_tos(params = {})
    if params[:version]
      # Redis search doesn't work for 1.0, has to be 1
      tos_version =   params[:version] == params[:version].to_i ?  params[:version].to_i : params[:version]
      Tos.find(tos_id: ENV["tos_id"], tos_version: tos_version).first
    else
      Tos.all.first(by: :tos_version, limit: [0, 1], order: 'DESC')
    end
  end

  def self.latest
    get_tos
  end


end