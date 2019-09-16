class String
  # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
  # convert accented characters to valid utf-8
  def to_valid_utf8
    unpack('C*').pack('U*')
  end
end