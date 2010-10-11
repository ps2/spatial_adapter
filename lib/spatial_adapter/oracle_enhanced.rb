require 'spatial_adapter'
require 'active_record/connection_adapters/oracle_enhanced_adapter'

include GeoRuby::SimpleFeatures
include SpatialAdapter


module ActiveRecord
  module ConnectionAdapters
    class OracleEnhancedAdapter
  
      def spatial?
        rval = select_value("select object_id from all_objects where owner = 'MDSYS' and object_name = 'SDO_GEOMETRY'").to_i
        rval > 0 ? true : false
      end

      def columns_without_cache(table_name, name = nil) #:nodoc:
        table_name = table_name.to_s
        # get ignored_columns by original table name
        ignored_columns = ignored_table_columns(table_name)

        (owner, desc_table_name, db_link) = @connection.describe(table_name)

        @@do_not_prefetch_primary_key[table_name] =
          !has_primary_key?(table_name, owner, desc_table_name, db_link) ||
          has_primary_key_trigger?(table_name, owner, desc_table_name, db_link)

        table_cols = <<-SQL
          select column_name as name, data_type as sql_type, data_default, nullable,
                 decode(data_type, 'NUMBER', data_precision,
                                   'FLOAT', data_precision,
                                   'VARCHAR2', decode(char_used, 'C', char_length, data_length),
                                   'CHAR', decode(char_used, 'C', char_length, data_length),
                                    null) as limit,
                 decode(data_type, 'NUMBER', data_scale, null) as scale
            from all_tab_columns#{db_link}
           where owner      = '#{owner}'
             and table_name = '#{desc_table_name}'
           order by column_id
        SQL
    
        raw_geom_infos = column_spatial_info(desc_table_name)

        # added deletion of ignored columns
        select_all(table_cols, name).delete_if do |row|
          ignored_columns && ignored_columns.include?(row['name'].downcase)
        end.map do |row|
          limit, scale = row['limit'], row['scale']
          if limit || scale
            row['sql_type'] += "(#{(limit || 38).to_i}" + ((scale = scale.to_i) > 0 ? ",#{scale})" : ")")
          end
          
          # clean up odd default spacing from Oracle
          if row['data_default']
            row['data_default'].sub!(/^(.*?)\s*$/, '\1')

            # If a default contains a newline these cleanup regexes need to
            # match newlines.
            row['data_default'].sub!(/^'(.*)'$/m, '\1')
            row['data_default'] = nil if row['data_default'] =~ /^(null|empty_[bc]lob\(\))$/i
          end

          if row['sql_type'] =~ /sdo_geometry/i
            raw_geom_info = raw_geom_infos[oracle_downcase(row['name'])]
            if(raw_geom_info.nil?)
              puts "Couldn't find geom info for #{row['name']} in #{raw_geom_infos.inspect}"
            end
            ActiveRecord::ConnectionAdapters::SpatialOracleColumn.new(
              oracle_downcase(row['name']),
              row['data_default'],
              raw_geom_info.type,
              row['nullable'] == 'Y',
              raw_geom_info.srid,
              raw_geom_info.with_z,
              raw_geom_info.with_m)
          else
            OracleEnhancedColumn.new(oracle_downcase(row['name']),
                             row['data_default'],
                             row['sql_type'],
                             row['nullable'] == 'Y',
                             # pass table name for table specific column definitions
                             table_name,
                             # pass column type if specified in class definition
                             get_type_for_column(table_name, oracle_downcase(row['name'])))
          end
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::OracleEnhancedIndexDefinition.class_eval do
  def spatial
    type == "MDSYS.SPATIAL_INDEX"
  end
end

ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do

  include SpatialAdapter

  SPATIAL_TOLERANCE = 0.5
  
  def supports_geographic?
    false
  end
  
  def default_srid
    8307
  end
  
  alias :original_native_database_types :native_database_types
  def native_database_types
    types = original_native_database_types.merge!(geometry_data_types)
    
    # Change mapping of :float from NUMBER to FLOAT, as oracle 
    # recognizes the ansi keyword and it helps keep the schema
    # stable, even though it ends up mapping to the same underlying
    # native type.
    types[:float] = {:name => "FLOAT", :limit => 126 }
    
    types
  end

  #Redefines the quote method to add behaviour for when a Geometry is encountered ; used when binding variables in find_by methods
  def quote(value, column = nil)
    if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
      quote_generic_geom( value )
    elsif value && column && [:text, :binary].include?(column.type)
      %Q{empty_#{ column.sql_type.downcase rescue 'blob' }()}
    else
      super
    end
  end
  
  def quote_point_geom( value )
    if !value.with_z && !value.with_m
      "SDO_GEOMETRY( 2001, #{value.srid}, MDSYS.SDO_POINT_TYPE( #{value.x}, #{value.y}, NULL ), NULL, NULL )"
    elsif value.with_z && value.with_m
      raise ArgumentError, "4d points not currently supported in the oracle_enhanced spatial adapter."
      #"SDO_GEOMETRY( 2001, #{value.srid}, MDSYS.SDO_POINT_TYPE( #{value.x}, #{value.y}, #{value.z}, #{value.m} ), NULL, NULL )"
    elsif value.with_z
      "SDO_GEOMETRY( 3001, #{value.srid}, MDSYS.SDO_POINT_TYPE( #{value.x}, #{value.y}, #{value.z} ), NULL, NULL )"
    elsif value.with_m
      raise ArgumentError, "3d points (with M coord) not currently supported in the oracle_enhanced spatial adapter."
      #"SDO_GEOMETRY( 2001, #{value.srid}, MDSYS.SDO_POINT_TYPE( #{value.x}, #{value.y}, #{value.m} ), NULL, NULL )"
    end
  end
    
  # This technique only supports 2d geometries
  def quote_generic_geom( value )
    if value.kind_of?( GeoRuby::SimpleFeatures::Point )
      # Small optimization for the most commonly used type: points.  Oracle's WKT parsing seems slow
      quote_point_geom( value )
    else
      "SDO_GEOMETRY( '#{value.as_wkt}', #{value.srid} )"
    end
  end

  def create_table(name, options = {})
    table_definition = ActiveRecord::ConnectionAdapters::OracleTableDefinition.new(self)
    table_definition.primary_key(options[:primary_key] || "id") unless options[:id] == false
    
    yield table_definition if block_given?
    
    # table_exists? is slow
    #if options[:force] && table_exists?(name)
    if options[:force]
      drop_table(name) rescue nil
    end
    
    create_sql = "CREATE#{' TEMPORARY' if options[:temporary]} TABLE "
    create_sql << "#{name} ("
    create_sql << table_definition.to_sql
    create_sql << ") #{options[:options]}"
    execute create_sql
    execute "CREATE SEQUENCE #{name}_seq START WITH 10000" unless options[:id] == false
    
    #added to create the geometric columns identified during the table definition
    unless table_definition.geom_columns.nil?
      table_definition.geom_columns.each do |geom_column|
        geom_column.sql_create_statements(name).each do |stmt|
          execute stmt
        end
      end
    end
  end
  
  # We override this for three reasons:
  # 1) Drop spatial indexes before dropping the tables, as "drop table cascade constraints"
  #    seems to leave metadata around in SDO_INDEX_METADATA_TABLE
  # 2) Avoid dropping sequences that end in '$', as those are for the spatial indexes (which get dropped above)
  # 3) Need to clear out USER_SDO_GEOM_METADATA after everything else is done.
  def structure_drop
    s = []
    select_values("select sdo_index_name from user_sdo_index_metadata").uniq.each do |idx|
      s << "DROP INDEX \"#{idx}\""
    end
    
    select_values("select sequence_name from user_sequences order by 1").each do |seq|
      s << "DROP SEQUENCE \"#{seq}\"" unless seq[-1,1] == '$'
    end
    select_values("select table_name from all_tables t
                where owner = sys_context('userenv','session_user') and secondary='N'
                  and not exists (select mv.mview_name from all_mviews mv where mv.owner = t.owner and mv.mview_name = t.table_name)
                  and not exists (select mvl.log_table from all_mview_logs mvl where mvl.log_owner = t.owner and mvl.log_table = t.table_name)
                order by 1").each do |table|
      s << "DROP TABLE \"#{table}\" CASCADE CONSTRAINTS"
    end
    s << "DELETE FROM USER_SDO_GEOM_METADATA"
    join_with_statement_token(s)
  end
  
  alias :original_remove_column :remove_column
  def remove_column(table_name,column_name)
    columns(table_name).each do |col|
      if col.name.to_s == column_name.to_s
        #check if the column is geometric
        if col.is_a?(SpatialColumn) && col.spatial?
          execute "DELETE FROM USER_SDO_GEOM_METADATA WHERE TABLE_NAME = '#{table_name.upcase}' AND COLUMN_NAME = '#{column_name.to_s.upcase}'"
          execute "ALTER TABLE #{table_name} DROP COLUMN #{column_name}"
        else
          original_remove_column(table_name,column_name)
        end
      end
    end
  end
  
  alias :original_add_column :add_column
  def add_column(table_name, column_name, type, options = {})
    unless geometry_data_types[type].nil?
      geom_column = ActiveRecord::ConnectionAdapters::OracleColumnDefinition.new(self,column_name, type, nil,nil,options[:null],options[:srid] || -1 , options[:with_z] || false , options[:with_m] || false)
      geom_column.sql_create_statements(table_name).each do |stmt|
        execute stmt
      end
    else
      original_add_column(table_name,column_name,type,options)
    end
  end
  
  #Adds a spatial index to a column. Its name will be index_<table_name>_on_<column_name> unless the key :name is present in the options hash, in which case its value is taken as the name of the index.
  def add_index(table_name,column_name,options = {})
    # invalidate index cache
    self.all_schema_indexes = nil
    index_name = options[:name] || "index_#{table_name}_on_#{column_name}"
    if options[:spatial]
      execute "CREATE INDEX #{index_name} ON #{table_name} (#{column_name}) INDEXTYPE IS mdsys.spatial_index"
    else
      index_type = options[:unique] ? "UNIQUE" : ""
      #all together
      execute "CREATE #{index_type} INDEX #{index_name} ON #{table_name} (#{Array(column_name).join(", ")})"
    end
  end
  
  private

  def column_spatial_info(table_name)
    rows = select_all <<-end_sql
    SELECT column_name, diminfo, srid 
    FROM user_sdo_geom_metadata 
    WHERE table_name = '#{table_name}'
    end_sql
    
    raw_geom_infos = {}
    rows.each do |row|
      column_name = oracle_downcase(row['column_name'])
      dims = row['diminfo'].to_ary
      raw_geom_info = raw_geom_infos[column_name] || ActiveRecord::ConnectionAdapters::RawGeomInfo.new
      raw_geom_info.type = "geometry"
      raw_geom_info.with_m = dims.any? {|d| d.sdo_dimname == 'M'}
      raw_geom_info.with_z = dims.any? {|d| d.sdo_dimname == 'Z'}
      raw_geom_info.srid = row['srid'].to_i
      #raw_geom_info.diminfo = row['diminfo']
      raw_geom_infos[column_name] = raw_geom_info
    end #constr.each

    raw_geom_infos
  end
  
end

module ActiveRecord
  module ConnectionAdapters
    class RawGeomInfo < Struct.new(:type,:srid,:dimension,:with_z,:with_m) #:nodoc:
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    class OracleTableDefinition < TableDefinition
      attr_reader :geom_columns
      
      def column(name, type, options = {})
        unless @base.geometry_data_types[type.to_sym].nil?
          geom_column = OracleColumnDefinition.new(@base, name, type)
          geom_column.null = options[:null]
          srid = options[:srid] || -1
          srid = @base.default_srid if srid == :default_srid
          geom_column.srid = srid
          geom_column.with_z = options[:with_z] || false 
          geom_column.with_m = options[:with_m] || false
         
          @geom_columns = [] if @geom_columns.nil?
          @geom_columns << geom_column          
        else
          super(name,type,options)
        end
      end
    
      SpatialAdapter.geometry_data_types.keys.each do |column_type|
        class_eval <<-EOV
          def #{column_type}(*args)
            options = args.extract_options!
            column_names = args
          
            column_names.each { |name| column(name, '#{column_type}', options) }
          end
        EOV
      end      
    end

    class OracleColumnDefinition < ColumnDefinition
      attr_accessor :srid, :with_z,:with_m
      attr_reader :spatial

      def initialize(base = nil, name = nil, type=nil, limit=nil, default=nil,null=nil,srid=-1,with_z=false,with_m=false)
        super(base, name, type, limit, default,null)
        @spatial=true
        @srid=srid
        @with_z=with_z
        @with_m=with_m
      end
      
      def sql_create_statements(table_name)
          type_sql = type_to_sql(type)
          
          #column_sql = "SELECT AddGeometryColumn('#{table_name}','#{name}',#{srid},'#{type_sql}',#{dimension})"
          column_sql = "ALTER TABLE #{table_name} ADD (#{name} #{type_sql}"
          column_sql += " NOT NULL" if null == false
          column_sql += ")"
          stmts = [column_sql]
          if srid == 8307 # There are others we should probably support, but this is common
            dim_elems = ["MDSYS.SDO_DIM_ELEMENT('X', -180.0, 180.0, 0.005)",
                         "MDSYS.SDO_DIM_ELEMENT('Y', -90.0, 90.0, 0.005)"]
          else
            dim_elems = ["MDSYS.SDO_DIM_ELEMENT('X', -1000, 1000, 0.005)",
                         "MDSYS.SDO_DIM_ELEMENT('Y', -1000, 1000, 0.005)"]
          end
          if @with_z
            dim_elems << "MDSYS.SDO_DIM_ELEMENT('Z', -1000, 1000, 0.005)"
          end
          if @with_m
            dim_elems << "MDSYS.SDO_DIM_ELEMENT('M', -1000, 1000, 0.005)"
          end
          
          stmts <<  "DELETE FROM USER_SDO_GEOM_METADATA WHERE TABLE_NAME = '#{table_name.to_s.upcase}' AND COLUMN_NAME = '#{name.to_s.upcase}'"
          stmts << "INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) VALUES (" +
                   "'#{table_name}', '#{name}', MDSYS.SDO_DIM_ARRAY(#{dim_elems.join(',')}),#{srid})"
          stmts
      end
      
      def to_sql(table_name)
        if @spatial
          raise "Got here!"
        else
          super
        end
      end
  
  
      private
      def type_to_sql(name, limit=nil)
        case name.to_s
        when /geometry|point|line_string|polygon|multipoint|multilinestring|multipolygon|geometrycollection/i
          "MDSYS.SDO_GEOMETRY"
        else base.type_to_sql(name, limit) rescue name
        end
      end
      
    end

  end
end

#Would prefer creation of a OracleColumn type instead but I would need to reimplement methods where Column objects are instantiated so I leave it like this
module ActiveRecord
  module ConnectionAdapters
    class SpatialOracleColumn < Column

      include SpatialColumn
      
      # With the ruby-oci8 adapter, we get objects back from spatial columns
      # so this method name is a bit of a misnomer. TODO: change this method name to 'to_geometry'
      def self.string_to_geometry(obj)
        return obj unless obj && obj.class.to_s == "OCI8::Object::Mdsys::SdoGeometry"
        raise "Bad #{obj.class} object: #{obj.inspect}" if obj.sdo_gtype.nil? 
        ndim = obj.sdo_gtype.to_int/1000
        gtype = obj.sdo_gtype.to_int%1000
        eleminfo = obj.sdo_elem_info.instance_variable_get('@attributes')
        ordinates = obj.sdo_ordinates.instance_variable_get('@attributes')
        case gtype
        when 1
          geom = point_from_sdo_geometry(eleminfo, ordinates, ndim, obj.sdo_point)
        when 2
          geom = linestrings_from_sdo_geometry(eleminfo, ordinates, ndim)[0]
        when 3
          geom = polygons_from_sdo_geometry(eleminfo, ordinates, ndim)[0]
        when 4
          geom = geomcollection_from_sdo_geometry(eleminfo, ordinates, ndim)
        when 5
          geom = MultiPoint.from_coordinates(group_ordinates(ordinates, ndim))
        when 6
          linestrings = linestrings_from_sdo_geometry(eleminfo, ordinates, ndim)
          geom = MultiLineString.from_line_strings(linestrings)
        when 7
          polygons = polygons_from_sdo_geometry(eleminfo, ordinates, ndim)
          geom = MultiPolygon.from_polygons(polygons)
        else
          raise "Unhandled geometry type #{obj.sdo_gtype.to_int}"
        end
        geom.srid = obj.sdo_srid.to_i
        geom
      end
      
      def self.group_ordinates(ordinates, num_dims)
        coords = []
        ordinates.each_slice(num_dims) do |coord|
          x,y = coord
          coords << [x.to_f, y.to_f]
        end
        coords
      end
      
      def self.point_from_sdo_point(sdo_point, ndim)
        if ndim == 2
          Point.from_x_y(sdo_point.x.to_f, sdo_point.y.to_f)
        elsif ndim == 3
          Point.from_x_y_z(sdo_point.x.to_f, sdo_point.y.to_f, sdo_point.z.to_f)
        else
          raise "Not supporting #{ndim} dimensional points"
        end
      end
      
      def self.point_from_sdo_geometry(elem_info, ordinates, ndim, sdo_point)
        if sdo_point
          point_from_sdo_point(sdo_point, ndim)
        else
          coords = ordinates.slice(0,ndim)
          if ndim == 2
            Point.from_x_y(ordinates[0].to_f, ordinates[1].to_f)
          elsif ndim == 3
            Point.from_x_y_z(ordinates[0].to_f, ordinates[1].to_f, ordinates[2].to_f)
          end
        end
      end
      
      def self.linestrings_from_sdo_geometry(elem_info, ordinates, ndim)
        num_ls = elem_info.size / 3
        linestrings = []
        0.upto(num_ls-1) do |ring_idx|
          (start_ord, ring_type, gtype, end_ord) = elem_info.slice(ring_idx*3,4)
          end_ord ||= ordinates.size + 1
          num_ords = end_ord - start_ord
          linestrings << LineString.from_coordinates(group_ordinates(ordinates.slice(start_ord-1, num_ords), ndim))
        end
        linestrings
      end
      
      def self.polygons_from_sdo_geometry(elem_info, ordinates, ndim)
        num_rings = elem_info.size / 3
        polygons = []
        rings = []
        cur_polygon = nil
        0.upto(num_rings-1) do |ring_idx|
          (start_ord, etype, interpretation, end_ord) = elem_info.slice(ring_idx*3,4)
          end_ord ||= ordinates.size + 1
          num_ords = end_ord - start_ord
          if etype == 1003 && rings.size > 0 # exterior ring
            polygons << Polygon.from_linear_rings(rings)
            rings = []
          end
          rings << LinearRing.from_coordinates(group_ordinates(ordinates.slice(start_ord-1, num_ords), ndim))
        end
        if rings.size > 0 # exterior ring
          polygons << Polygon.from_linear_rings(rings)
          rings = []
        end
        polygons
      end
      
      def self.geomcollection_from_sdo_geometry(elem_info, ordinates, ndim)
        num_elems = elem_info.size / 3
        geometries = []
        0.upto(num_elems-1) do |idx|
          (start_ord, etype, interpretation, end_ord) = elem_info.slice(idx*3,4)
          end_ord ||= ordinates.size + 1
          num_ords = end_ord - start_ord
          geom = nil
          case etype
          when 1
            if ndim == 2
              geom = Point.from_x_y(ordinates[start_ord-1].to_f, ordinates[start_ord].to_f)
            elsif ndim == 3
              geom = Point.from_x_y_z(ordinates[start_ord-1].to_f, ordinates[start_ord].to_f, ordinates[start_ord+1].to_f)
            else
              raise "Not supporting #{ndim} dimensional points"
            end
          when 2
            geom = LineString.from_coordinates(group_ordinates(ordinates.slice(start_ord-1, num_ords), ndim))
          when 1003
            raise "Unsupported interpretation #{interpretation} for etype 1003" if interpretation != 1
            ring = LinearRing.from_coordinates(group_ordinates(ordinates.slice(start_ord-1, num_ords), ndim))
            geom = Polygon.from_linear_rings([ring])
          when 2003
            raise "Unsupported interpretation #{interpretation} for etype 2003" if interpretation != 1
            ring = LinearRing.from_coordinates(group_ordinates(ordinates.slice(start_ord-1, num_ords), ndim))
            last_geom = geometries.pop
            geom = Polygon.from_linear_rings(last_geom.rings + [ring])
          else
            raise "Unsupported type in collection: etype = #{etype}, interpretation = #{interpretation}"
          end
          geometries << geom if geom
        end
        GeometryCollection.from_geometries(geometries)
      end
    end
  end
end

ActiveRecord::SchemaDumper.class_eval do 
  def oracle_enhanced_table(table, stream)
    columns = @connection.columns(table)
    begin
      tbl = StringIO.new

      # first dump primary key column
      if @connection.respond_to?(:pk_and_sequence_for)
        pk, pk_seq = @connection.pk_and_sequence_for(table)
      elsif @connection.respond_to?(:primary_key)
        pk = @connection.primary_key(table)
      end

      tbl.print "  create_table #{table.inspect}"

      # addition to make temporary option work
      tbl.print ", :temporary => true" if @connection.temporary_table?(table)

      if columns.detect { |c| c.name == pk }
        if pk != 'id'
          tbl.print %Q(, :primary_key => "#{pk}")
        end
      else
        tbl.print ", :id => false"
      end
      tbl.print ", :force => true"
      tbl.puts " do |t|"

      # then dump all non-primary key columns
      column_specs = columns.map do |column|
        raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
        next if column.name == pk
        spec = column_spec(column)
        (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
        spec
      end.compact

      # find all migration keys used in this table
      keys = [:name, :limit, :precision, :scale, :default, :null, :with_z, :with_m, :srid] & column_specs.map(&:keys).flatten

      # figure out the lengths for each column based on above keys
      lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

      # the string we're going to sprintf our values against, with standardized column widths
      format_string = lengths.map{ |len| "%-#{len}s" }

      # find the max length for the 'type' column, which is special
      type_length = column_specs.map{ |column| column[:type].length }.max

      # add column type definition to our format string
      format_string.unshift "    t.%-#{type_length}s "

      format_string *= ''

      column_specs.each do |colspec|
        values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
        values.unshift colspec[:type]
        tbl.print((format_string % values).gsub(/,\s*$/, ''))
        tbl.puts
      end

      tbl.puts "  end"
      tbl.puts
      
      indexes(table, tbl)

      tbl.rewind
      stream.print tbl.read
    rescue => e
      stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
      stream.puts "#   #{e.message} #{e.backtrace.join("\n")}"
      stream.puts
    end

    stream
  end
  
  private 
  
  def indexes_with_oracle_enhanced_spatial(table, stream)
    if (indexes = @connection.indexes(table)).any?
      add_index_statements = indexes.map do |index|
        case index.type
        when nil
          # use table.inspect as it will remove prefix and suffix
          statement_parts = [ ('add_index ' + table.inspect) ]
          statement_parts << index.columns.inspect
          statement_parts << (':name => ' + index.name.inspect)
          statement_parts << ':unique => true' if index.unique
          statement_parts << ':tablespace => ' + index.tablespace.inspect if index.tablespace
        when 'MDSYS.SPATIAL_INDEX'
          statement_parts = [ ('add_index ' + table.inspect) ]
          statement_parts << index.columns.inspect
          statement_parts << (':name => ' + index.name.inspect)
          statement_parts << ':unique => true' if index.unique
          statement_parts << ':spatial => true' if index.spatial
          statement_parts << ':tablespace => ' + index.tablespace.inspect if index.tablespace
        when 'CTXSYS.CONTEXT'
          if index.statement_parameters
            statement_parts = [ ('add_context_index ' + table.inspect) ]
            statement_parts << index.statement_parameters
          else
            statement_parts = [ ('add_context_index ' + table.inspect) ]
            statement_parts << index.columns.inspect
            statement_parts << (':name => ' + index.name.inspect)
          end
        else
          # unrecognized index type
          statement_parts = ["# unrecognized index #{index.name.inspect} with type #{index.type.inspect}"]
        end
        '  ' + statement_parts.join(', ')
      end

      stream.puts add_index_statements.sort.join("\n")
      stream.puts
    end
  end  
  alias_method_chain :indexes, :oracle_enhanced_spatial
      
end
