oracle_enhanced_connection

ActiveRecord::Schema.define() do
  execute "delete from user_sdo_geom_metadata"

  execute "drop table point_models" rescue nil
  execute "drop sequence point_models_seq" rescue nil
  execute "create table point_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	more_extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE point_models_seq START WITH 10000"
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('point_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
      8307)"        
  execute "create index index_point_models_on_geom ON point_models(geom) INDEXTYPE IS MDSYS.SPATIAL_INDEX"
  execute "create index index_point_models_on_extra on point_models (extra, more_extra)"
    
  execute "drop table line_string_models" rescue nil
  execute "drop sequence line_string_models_seq" rescue nil
  execute "create table line_string_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE line_string_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('line_string_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"

  execute "drop table polygon_models" rescue nil
  execute "drop sequence polygon_models_seq" rescue nil
  execute "create table polygon_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE polygon_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('polygon_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
        
  execute "drop table multi_point_models" rescue nil
  execute "drop sequence multi_point_models_seq" rescue nil
  execute "create table multi_point_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE multi_point_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('multi_point_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
        
  execute "drop table multi_line_string_models" rescue nil
  execute "drop sequence multi_line_string_models_seq" rescue nil
  execute "create table multi_line_string_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE multi_line_string_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('multi_line_string_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
        
  execute "drop table multi_polygon_models" rescue nil
  execute "drop sequence multi_polygon_models_seq" rescue nil
  execute "create table multi_polygon_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE multi_polygon_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('multi_polygon_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
        
  execute "drop table geometry_collection_models" rescue nil
  execute "drop sequence geometry_collection_models_seq" rescue nil
  execute "create table geometry_collection_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE geometry_collection_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('geometry_collection_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
  
  execute "drop table geometry_models" rescue nil
  execute "drop sequence geometry_models_seq" rescue nil
  execute "create table geometry_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE geometry_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('geometry_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)),
        8307)"
  
  execute "drop table pointz_models" rescue nil
  execute "drop sequence pointz_models_seq" rescue nil
  execute "create table pointz_models
    (
    	id NUMBER(38,0) NOT NULL,
    	extra varchar2(255),
    	geom SDO_GEOMETRY,
    	PRIMARY KEY (id)
    )"
  execute "CREATE SEQUENCE pointz_models_seq START WITH 10000"  
  execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
      VALUES ('pointz_models', 'geom', 
      SDO_DIM_ARRAY(
        MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005),
        MDSYS.SDO_DIM_ELEMENT('Z', -90.0, 90.0, 0.005)),
        8307)"
  
  #execute "drop table pointm_models" rescue nil
  #execute "drop sequence pointm_models_seq" rescue nil
  #execute "create table pointm_models
  #  (
  #  	id NUMBER(38,0) NOT NULL,
  #  	extra varchar2(255),
  #  	geom SDO_GEOMETRY,
  #  	PRIMARY KEY (id)
  #  )"
  #execute "CREATE SEQUENCE pointm_models_seq START WITH 10000"
  #execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
  #    VALUES ('pointm_models', 'geom', 
  #    SDO_DIM_ARRAY(
  #      MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
  #      MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005),
  #      MDSYS.SDO_DIM_ELEMENT('M', -90.0, 90.0, 0.005)),
  #      8307)"

  #execute "drop table point4_models" rescue nil
  #execute "drop sequence point4_models_seq" rescue nil
  #execute "create table point4_models
  #  (
  #  	id NUMBER(38,0) NOT NULL,
  #  	extra varchar2(255),
  #  	geom SDO_GEOMETRY,
  #  	PRIMARY KEY (id)
  #  )"
  #execute "CREATE SEQUENCE point4_models_seq START WITH 10000"  
  #execute "insert into user_sdo_geom_metadata (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
  #    VALUES ('point4_models', 'geom', 
  #    SDO_DIM_ARRAY(
  #      MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005),
  #      MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005),
  #      MDSYS.SDO_DIM_ELEMENT('Z', -90.0, 90.0, 0.005),
  #      MDSYS.SDO_DIM_ELEMENT('M', -90.0, 90.0, 0.005)),
  #      8307)"
end
