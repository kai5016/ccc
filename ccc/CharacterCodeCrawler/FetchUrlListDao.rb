require 'mongo'

class FetchUrlListDao
  connection = Mongo::Connection.new
  #  connection = Mongo::Connection.new('localhost');
  #  connection = Mongo::Connection.new('localhost'27017);

  puts 'd'
  puts connection.database_names

  puts ''
  puts 'ds'
  connection.database_info.each { |info| puts info.inspect }

  # データベースを選択（存在しなければ作成）
  db = connection.db('ruby_sample')

  # コレクション選択
  coll = db.collection('test_coll')

  # インサートするドキュメントを作成
  doc = {'name' => 'MongoDB', 'type' => 'database', 'count' => 1, 'info' => {'x' => 203, 'y' => '102'}}

  # コレクションにドキュメントをインサート
  # （データベースが存在しない場合はここで初めて作成される）
  id = coll.insert(doc)
  
  # 大量のドキュメントをインサート
  10.times { |i| coll.insert('i' => i) }
    
  puts ''
  puts 'all collection names'
  puts db.collection.names
  
  puts ''
  puts 'get first document in a collection'
  puts coll.find_one
  
  puts ''
  puts 'get all document in a collection'
  coll.find.each { |row| puts row.inspect }
  
  puts ''
  puts 'find by id(id = ' + id.to_s + ')'
  coll.find('_id' => id).each { |row| row.inspect }
  puts 'find the \'i\'Field is 7 '
  coll.find('id' => 7).each { |row| puts row.inspect }
    
  puts ''
  puts 'the document found is able to sort'
  puts 'the key is \'i\''
  coll.find.sort([:i,:desc]).each { |row| puts row.inspect }
    
end