require 'rubygems'
require 'spec'
require 'geo_ruby'
gem 'activerecord', '=2.2.2'
#gem 'activerecord', '=3.0.0'
require 'active_record'

$:.unshift((File.join(File.dirname(__FILE__), '..', 'lib')))

include GeoRuby::SimpleFeatures


def postgis_connection
  ActiveRecord::Base.establish_connection(
    :adapter => 'postgresql',
    :database => 'spatial_adapter'
  )
  # Turn off those annoying NOTICE messages
  ActiveRecord::Base.connection.execute 'set client_min_messages = warning'

  # Don't output migration logging
  ActiveRecord::Migration.verbose = false
end

def mysql_connection
  ActiveRecord::Base.establish_connection(
    :adapter => 'mysql',
    :database => 'spatial_adapter',
    :username => 'root',
    :host => 'localhost'
  )
  
  # Don't output migration logging
  ActiveRecord::Migration.verbose = false
end

def oracle_enhanced_connection
  ActiveRecord::Base.establish_connection(
    :adapter => 'oracle_enhanced',
    :database => '//localhost:1521/orcl',
    :username => 'spatial_adapter',
    :password => 'test'
  )
 
  # Don't output migration logging
  ActiveRecord::Migration.verbose = false
end

class GeometryFactory
  @@default_srid = 4326
  
  class << self
    def default_srid=(new_srid)
      @@default_srid = new_srid
    end
    
    def point
      Point.from_x_y(1.0, 2.0, @@default_srid)
    end
    
    def line_string
      LineString.from_coordinates([[1.4,2.5],[1.5,6.7]], @@default_srid)
    end
    
    def polygon
      Polygon.from_coordinates([[[12.4,-45.3],[45.4,41.6],[4.456,1.0698],[12.4,-45.3]],[[2.4,5.3],[5.4,1.4263],[14.46,1.06],[2.4,5.3]]], @@default_srid)
    end
    
    def multi_point
      MultiPoint.from_coordinates([[12.4,-23.3],[-65.1,23.4],[23.55555555,23.0]], @@default_srid)
    end
    
    def multi_line_string
      MultiLineString.from_line_strings([LineString.from_coordinates([[1.5,45.2],[-54.12312,-0.012]]),LineString.from_coordinates([[1.5,45.2],[-54.12312,-0.012],[45.123,23.3]])], @@default_srid)
    end
    
    def multi_polygon
      MultiPolygon.from_polygons([Polygon.from_coordinates([[[12.4,-45.3],[45.4,41.6],[4.456,1.0698],[12.4,-45.3]],[[2.4,5.3],[5.4,1.4263],[14.46,1.06],[2.4,5.3]]]),Polygon.from_coordinates([[[0.0,0.0],[4.0,0.0],[4.0,4.0],[0.0,4.0],[0.0,0.0]],[[1.0,1.0],[3.0,1.0],[3.0,3.0],[1.0,3.0],[1.0,1.0]]])], @@default_srid)
    end
    
    def geometry_collection
      GeometryCollection.from_geometries([Point.from_x_y(4.67,45.4),LineString.from_coordinates([[5.7,12.45],[67.55,54.0]])], @@default_srid)
    end
    
    def pointz
      Point.from_x_y_z(1.0, 2.0, 3.0, @@default_srid)
    end
    
    def pointm
      Point.from_x_y_m(1.0, 2.0, 3.0, @@default_srid)
    end
      
    def point4
      Point.from_x_y_z_m(1.0, 2.0, 3.0, 4.0, @@default_srid)
    end
  end
end
