require 'spec_helper'
require 'spatial_adapter/oracle_enhanced'
require 'db/oracle_enhanced_raw'
require 'models/common'

describe "Modified OracleEnhancedAdapter" do
  before :each do
    oracle_enhanced_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe '#spatial?' do
    it 'should be true if Spatial is installed' do
      @connection.should_receive(:select_value).with("select object_id from all_objects where owner = 'MDSYS' and object_name = 'SDO_GEOMETRY'").and_return(1)
      @connection.should be_spatial
    end
    
    it 'should be false if Spatial is not installed' do
      @connection.should_receive(:select_value).with("select object_id from all_objects where owner = 'MDSYS' and object_name = 'SDO_GEOMETRY'").and_return(0)
      @connection.should_not be_spatial
    end
  end
  
  describe "#columns" do
    describe "type" do
      it "should be a regular SpatialOracleColumn if column is a geometry data type" do
        column = PointModel.columns.select{|c| c.name == 'geom'}.first
        column.should be_a(ActiveRecord::ConnectionAdapters::SpatialOracleColumn)
        column.geometry_type.should == :geometry
        column.should_not be_geographic
      end
      
      it "should be OracleEnhancedColumn if column is not a spatial data type" do
        PointModel.columns.select{|c| c.name == 'extra'}.first.should be_a(ActiveRecord::ConnectionAdapters::OracleEnhancedColumn)
      end
    end
    
    describe "@geometry_type" do
      # Oracle does not provide an easy way to denote particular types of geometries.
      # We could use some constraint, but not sure of performance impacts.
      
      it "should be :geometry for geometry columns" do
        PointModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :geometry
      end
      
      #it "should be :point for geometry columns restricted to POINT types" do
      #  PointModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :point
      #end
      
      #it "should be :line_string for geometry columns restricted to LINESTRING types" do
      #  LineStringModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :line_string
      #end

      #it "should be :polygon for geometry columns restricted to POLYGON types" do
      #  PolygonModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :polygon
      #end

      #it "should be :multi_point for geometry columns restricted to MULTIPOINT types" do
      #  MultiPointModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_point
      #end

      #it "should be :multi_line_string for geometry columns restricted to MULTILINESTRING types" do
      #  MultiLineStringModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_line_string
      #end
      
      #it "should be :multi_polygon for geometry columns restricted to MULTIPOLYGON types" do
      #  MultiPolygonModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_polygon
      #end
      
      #it "should be :geometry_collection for geometry columns restricted to GEOMETRYCOLLECTION types" do
      #  GeometryCollectionModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :geometry_collection
      #end
      
      #it "should be :geometry for geometry columns not restricted to a type" do
      #  GeometryModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :geometry
      #end
    end
  end
  
  describe "#indexes" do
    before :each do
      @indexes = @connection.indexes('point_models')
    end
    
    it "should return an OracleEnhancedIndexDefinition for each index on the table" do
      @indexes.should have(2).items
      @indexes.each do |i|
        i.should be_a(ActiveRecord::ConnectionAdapters::OracleEnhancedIndexDefinition)
      end
    end
    
    it "should indicate the correct columns in the index" do
      @indexes.select{|i| i.name == 'index_point_models_on_geom'}.first.columns.should == ['geom']
      @indexes.select{|i| i.name == 'index_point_models_on_extra'}.first.columns.should == ['extra', 'more_extra']
    end
    
    it "should be marked as spatial if a MDSYS.SPATIAL_INDEX index on a geometry column" do
      @indexes.select{|i| i.name == 'index_point_models_on_geom'}.first.spatial.should == true
    end
    
    it "should not be marked as spatial if not a MDSYS.SPATIAL_INDEX index" do
      @indexes.select{|i| i.name == 'index_point_models_on_extra'}.first.spatial.should == false
    end
    
  end  
  
  describe "#add_index" do
    after :each do
      @connection.remove_index('geometry_models', 'geom')
    end
    
    it "should create a spatial index given :spatial => true" do
      @connection.should_receive(:execute).with(/INDEXTYPE IS mdsys.spatial_index/i)
      @connection.add_index('geometry_models', 'geom', :spatial => true)
    end
    
    it "should not create a spatial index unless specified" do
      @connection.should_not_receive(:execute).with(/INDEXTYPE IS mdsys.spatial_index/i)
      @connection.add_index('geometry_models', 'extra')
    end
  end
end
