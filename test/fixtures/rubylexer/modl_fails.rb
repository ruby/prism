   modelCode = <<ENDModelCode
   
class #{@modelClassName} < ActiveRecord::Base
  def self.listAll
      find_by_sql("{'0'.CT.''}")
  end
end

ENDModelCode

