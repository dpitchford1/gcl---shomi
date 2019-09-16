class TosController < ApplicationController
  layout false, only: [:show, :appinfo]


  def show
    @tos = Tos[params[:id]]
    @tos ||= Tos.latest
  end
end
