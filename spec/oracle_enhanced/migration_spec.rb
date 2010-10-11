require 'spec_helper'
require 'spatial_adapter/oracle_enhanced'

class MigratedGeometryModel < ActiveRecord::Base
end

describe "Spatially-enabled Migrations" do
  before :each do
    oracle_enhanced_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe "creating tables" do
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end
    
    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should create #{type.to_s} columns" do
        ActiveRecord::Schema.define do
          create_table :migrated_geometry_models, :force => true do |t|
            t.integer :extra
            t.send(type, :geom)
          end
        end
      
        geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
        geom_column.should be_a(SpatialAdapter::SpatialColumn)
        geom_column.type.should == :string
        geom_column.geometry_type.should == :geometry
        geom_column.should_not be_geographic
        geom_column.with_z.should == false
        geom_column.with_m.should == false
        geom_column.srid.should == -1
      end      
    end
    
  
    it "should create 3d (xyz) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_z => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.with_z.should == true
      geom_column.with_m.should == false
      geom_column.srid.should == -1
    end
    
    
    it "should create 3d (xym) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_m => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :geometry
      geom_column.type.should == :string
      geom_column.with_z.should == false
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
    
    
    it "should create 4d (xyzm) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_z => true, :with_m => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :geometry
      geom_column.type.should == :string
      geom_column.with_z.should == true
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
    
    it "should create geometry columns with specified SRID" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.geometry :geom, :srid => 4326
        end
      end
    
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.type.should == :string
      geom_column.geometry_type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == false
      geom_column.srid.should == 4326
    end
  end

  describe "adding columns" do
    before :each do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
        end
      end
    end
    
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end
  
    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should add #{type.to_s} columns" do
        ActiveRecord::Schema.define do
          add_column :migrated_geometry_models, :geom, type
        end
  
        geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
        geom_column.should be_a(SpatialAdapter::SpatialColumn)
        geom_column.type.should == :string
        geom_column.geometry_type.should == :geometry
        geom_column.with_z.should == false
        geom_column.with_m.should == false
        geom_column.srid.should == -1
      end
    end
  
    it "should add 3d (xyz) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_z => true
      end
  
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.type.should == :string
      geom_column.geometry_type.should == :geometry
      geom_column.with_z.should == true
      geom_column.with_m.should == false
      geom_column.srid.should == -1
    end
  
  
    it "should add 3d (xym) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_m => true
      end
  
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.type.should == :string
      geom_column.geometry_type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
  
  
    it "should add 4d (xyzm) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_z => true, :with_m => true
      end
  
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.type.should == :string
      geom_column.geometry_type.should == :geometry
      geom_column.with_z.should == true
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
  
    it "should add GEOMETRY columns with specified SRID" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :geometry, :srid => 4326
      end
  
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :geometry
      geom_column.type.should == :string
      geom_column.with_z.should == false
      geom_column.with_m.should == false
      geom_column.srid.should == 4326
    end
  end
  
  describe "removing columns" do
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end
  
    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should remove #{type.to_s} column metadata from user_sdo_geom_metadata" do
        ActiveRecord::Schema.define do
          create_table :migrated_geometry_models, :force => true do |t|
            t.integer :extra
            t.send(type, :geom)
          end
        end
  
        @connection.should_receive(:execute).with(/DELETE FROM USER_SDO_GEOM_METADATA/).once
        @connection.should_receive(:execute).with(anything())
        ActiveRecord::Schema.define do
          remove_column :migrated_geometry_models, :geom
        end
        @connection.should_receive(:execute).with(anything()).twice
      end
    end

    it "should still remove non-spatial columns using ALTER TABLE DROP COLUMN" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom
        end
      end

      @connection.should_receive(:execute).with(/alter table.*migrated_geometry_models.*drop.*extra/i)
      ActiveRecord::Schema.define do
        remove_column :migrated_geometry_models, :extra
      end
      @connection.should_receive(:execute).with(anything()).twice
    end
  end
end