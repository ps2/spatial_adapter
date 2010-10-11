require 'spec_helper'
require 'shared_examples'
require 'spatial_adapter/oracle_enhanced'
require 'db/oracle_enhanced_raw'
require 'models/common'

describe "Spatially-enabled Models" do
  before :each do
    oracle_enhanced_connection
    @connection = ActiveRecord::Base.connection
    GeometryFactory.default_srid = @connection.default_srid
  end
  
  describe "inserting records" do
    it 'should save Point objects' do
      model = PointModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"POINT_MODELS\" (\"ID\", \"MORE_EXTRA\", \"EXTRA\", \"GEOM\") VALUES(10000, NULL, 'test', SDO_GEOMETRY( 2001, 8307, MDSYS.SDO_POINT_TYPE( 1.0, 2.0, NULL ), NULL, NULL ))", "PointModel Create", "id", 10000, "point_models_seq")
      model.save.should == true
    end
  
    it 'should save LineString objects' do
      model = LineStringModel.new(:extra => 'test', :geom => GeometryFactory.line_string)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"LINE_STRING_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'LINESTRING(1.4 2.5,1.5 6.7)', 8307 ))", "LineStringModel Create", "id", 10000, "line_string_models_seq")
      model.save.should == true
    end
  
    it 'should save Polygon objects' do
      model = PolygonModel.new(:extra => 'test', :geom => GeometryFactory.polygon)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"POLYGON_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'POLYGON((12.4 -45.3,45.4 41.6,4.456 1.0698,12.4 -45.3),(2.4 5.3,5.4 1.4263,14.46 1.06,2.4 5.3))', 8307 ))", "PolygonModel Create", "id", 10000, "polygon_models_seq")
      model.save.should == true
    end
  
    it 'should save MultiPoint objects' do
      model = MultiPointModel.new(:extra => 'test', :geom => GeometryFactory.multi_point)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"MULTI_POINT_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'MULTIPOINT((12.4 -23.3),(-65.1 23.4),(23.55555555 23.0))', 8307 ))", "MultiPointModel Create", "id", 10000, "multi_point_models_seq")
      model.save.should == true
    end
  
    it 'should save MultiLineString objects' do
      model = MultiLineStringModel.new(:extra => 'test', :geom => GeometryFactory.multi_line_string)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"MULTI_LINE_STRING_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'MULTILINESTRING((1.5 45.2,-54.12312 -0.012),(1.5 45.2,-54.12312 -0.012,45.123 23.3))', 8307 ))", "MultiLineStringModel Create", "id", 10000, "multi_line_string_models_seq")
      model.save.should == true
    end
  
    it 'should save MultiPolygon objects' do
      model = MultiPolygonModel.new(:extra => 'test', :geom => GeometryFactory.multi_polygon)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"MULTI_POLYGON_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'MULTIPOLYGON(((12.4 -45.3,45.4 41.6,4.456 1.0698,12.4 -45.3),(2.4 5.3,5.4 1.4263,14.46 1.06,2.4 5.3)),((0.0 0.0,4.0 0.0,4.0 4.0,0.0 4.0,0.0 0.0),(1.0 1.0,3.0 1.0,3.0 3.0,1.0 3.0,1.0 1.0)))', 8307 ))", "MultiPolygonModel Create", "id", 10000, "multi_polygon_models_seq")
      model.save.should == true
    end
  
    it 'should save GeometryCollection objects' do
      model = GeometryCollectionModel.new(:extra => 'test', :geom => GeometryFactory.geometry_collection)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"GEOMETRY_COLLECTION_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 'GEOMETRYCOLLECTION(POINT(4.67 45.4),LINESTRING(5.7 12.45,67.55 54.0))', 8307 ))", "GeometryCollectionModel Create", "id", 10000, "geometry_collection_models_seq")
      model.save.should == true
    end
  
    it 'should save Geometry objects' do
      model = GeometryModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"GEOMETRY_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 2001, 8307, MDSYS.SDO_POINT_TYPE( 1.0, 2.0, NULL ), NULL, NULL ))", "GeometryModel Create", "id", 10000, "geometry_models_seq")
      model.save.should == true
    end
  
    it 'should save 3D Point (with Z coord) objects' do
      model = PointzModel.new(:extra => 'test', :geom => GeometryFactory.pointz)
      @connection.should_receive(:insert_sql).with("INSERT INTO \"POINTZ_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 3001, 8307, MDSYS.SDO_POINT_TYPE( 1.0, 2.0, 3.0 ), NULL, NULL ))", "PointzModel Create", "id", 10000, "pointz_models_seq")
      model.save.should == true
    end
  
    #it 'should save 3D Point (with M coord) objects' do
    #  model = PointmModel.new(:extra => 'test', :geom => GeometryFactory.pointm)
    #  @connection.should_receive(:insert_sql).with("INSERT INTO \"POINTM_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 2001, 8307, MDSYS.SDO_POINT_TYPE( 1.0, 2.0, 3.0 ), NULL, NULL ))", "PointmModel Create", "id", 10000, "pointm_models_seq")
    #  model.save.should == true
    #end
  
    #it 'should save 4D Point objects' do
    #  model = Point4Model.new(:extra => 'test', :geom => GeometryFactory.point4)
    #  @connection.should_receive(:insert_sql).with("INSERT INTO \"POINT4_MODELS\" (\"ID\", \"EXTRA\", \"GEOM\") VALUES(10000, 'test', SDO_GEOMETRY( 2001, 8307, MDSYS.SDO_POINT_TYPE( 1.0, 2.0, 3.0, 4.0 ), NULL, NULL ))", "Point4Model Create", "id", 10000, "point4_models_seq")
    #  model.save.should == true
    #end

  end

  include CommonModelActions
  
  describe "finding records" do    
    it 'should retrieve 3D Point (with Z coord) objects' do
      model = PointzModel.create(:extra => 'test', :geom => GeometryFactory.pointz)
      PointzModel.find(model.id).geom.as_ewkt.should == GeometryFactory.pointz.as_ewkt
    end
  
    #it 'should retrieve 3D Point (with M coord) objects' do
    #  model = GeographyPointmModel.create(:extra => 'test', :geom => GeometryFactory.pointm)
    #  GeographyPointmModel.find(model.id).geom.as_ewkt.should == GeometryFactory.pointm.as_ewkt
    #end
  
    #it 'should retrieve 4D Point objects' do
    #  model = GeographyPoint4Model.create(:extra => 'test', :geom => GeometryFactory.point4)
    #  GeographyPoint4Model.find(model.id).geom.as_ewkt.should == GeometryFactory.point4.as_ewkt
    #end

  end
end

