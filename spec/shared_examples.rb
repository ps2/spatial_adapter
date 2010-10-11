share_as :CommonModelActions do
  describe 'finding records' do
    it 'should retrieve Point objects' do
      model = PointModel.create(:extra => 'test', :geom => GeometryFactory.point)
      PointModel.find(model.id).geom.as_ewkt.should == GeometryFactory.point.as_ewkt
    end

    it 'should retrieve LineString objects' do
      model = LineStringModel.create(:extra => 'test', :geom => GeometryFactory.line_string)
      LineStringModel.find(model.id).geom.as_ewkt.should == GeometryFactory.line_string.as_ewkt
    end

    it 'should retrieve Polygon objects' do
      model = PolygonModel.create(:extra => 'test', :geom => GeometryFactory.polygon)
      PolygonModel.find(model.id).geom.as_ewkt.should == GeometryFactory.polygon.as_ewkt
    end

    it 'should retrieve MultiPoint objects' do
      model = MultiPointModel.create(:extra => 'test', :geom => GeometryFactory.multi_point)
      MultiPointModel.find(model.id).geom.as_ewkt.should == GeometryFactory.multi_point.as_ewkt
    end

    it 'should retrieve MultiLineString objects' do
      model = MultiLineStringModel.create(:extra => 'test', :geom => GeometryFactory.multi_line_string)
      MultiLineStringModel.find(model.id).geom.as_ewkt.should == GeometryFactory.multi_line_string.as_ewkt
    end

    it 'should retrieve MultiPolygon objects' do
      model = MultiPolygonModel.create(:extra => 'test', :geom => GeometryFactory.multi_polygon)
      MultiPolygonModel.find(model.id).geom.as_ewkt.should == GeometryFactory.multi_polygon.as_ewkt
    end

    it 'should retrieve GeometryCollection objects' do
      model = GeometryCollectionModel.create(:extra => 'test', :geom => GeometryFactory.geometry_collection)
      GeometryCollectionModel.find(model.id).geom.as_ewkt.should == GeometryFactory.geometry_collection.as_ewkt
    end

    it 'should retrieve Geometry objects' do
      model = GeometryModel.create(:extra => 'test', :geom => GeometryFactory.point)
      GeometryModel.find(model.id).geom.as_ewkt.should == GeometryFactory.point.as_ewkt
    end
  end
end
