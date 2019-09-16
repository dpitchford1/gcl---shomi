module Mercury
  module Authentication

    def can_edit?
      session[:can_edit]
    end

  end
end
