class Alternatechurchname
  include Mongoid::Document

  field :alternate_name, type: String
  embedded_in :church
  #attr_accessible :alternate_name
end
