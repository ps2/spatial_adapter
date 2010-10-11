
ActiveRecord::Base.class_eval do
  #require 'active_record/version'

  def self.spatial_conditions(geom1, relationship, geom2)
    connection.spatial_conditions(geom1, relationship, geom2)
  end

  def self.spherical_distance( geom1, geom2 )
    connection.spherical_distance( geom1, geom2 )
  end
end