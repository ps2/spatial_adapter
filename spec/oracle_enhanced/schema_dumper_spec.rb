require 'spec_helper'
require 'spatial_adapter/oracle_enhanced'

describe "Spatially-enabled Schema Dumps" do
  before :all do
    oracle_enhanced_connection
    @connection = ActiveRecord::Base.connection
    
    @connection.execute_structure_dump(@connection.full_drop)

    # Create a new table
    ActiveRecord::Schema.define do
      create_table :migrated_geometry_models, :force => true do |t|
        t.integer :extra
        t.point   :geom, :with_m => false, :with_z => true, :srid => :default_srid
      end
      add_index :migrated_geometry_models, :geom, :spatial => true, :name => 'test_spatial_index'

    end
    
    File.open('schema.rb', "w") do |file|
      ActiveRecord::SchemaDumper.dump(@connection, file)
    end
    
    # Drop the original tables
    @connection.drop_table "migrated_geometry_models"
    
    # Load the dumped schema
    load('schema.rb')
  end
  
  after :all do
    # delete the schema file
    File.delete('schema.rb')

    # Drop the new tables
    @connection.drop_table "migrated_geometry_models"
  end
  
  it "should preserve spatial attributes of geometry tables" do
    columns = @connection.columns("migrated_geometry_models")
    
    columns.should have(3).items
    geom_column = columns.select{|c| c.name == 'geom'}.first
    geom_column.should be_a(SpatialAdapter::SpatialColumn)
    geom_column.geometry_type.should == :geometry
    geom_column.type.should == :string
    geom_column.with_z.should == true
    geom_column.with_m.should == false
    geom_column.srid.should == @connection.default_srid
  end
  
  it "should preserve spatial indexes" do
    indexes = @connection.indexes("migrated_geometry_models")
    
    indexes.should have(1).item
    
    indexes.first.name.should == 'test_spatial_index'
    indexes.first.columns.should == ["geom"]
    indexes.first.spatial.should == true
  end
end