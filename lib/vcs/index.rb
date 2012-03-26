class Index
  def initialize(path)
    @path = File.join(path, Repository::REPOSITORY_DIR)
    @data = {}
    @indexed_file_hash = {}
    load_index
  end

  attr_accessor :indexed_file_hash
  attr_accessor :data
  attr_accessor :hunks

  def save_index
    dump = Marshal.dump(self)
    File.open(File.join(@path, "index"), "w+") do |f|
      f.write(dump)
    end
  end

  def load_index
    dump = ""
    if File.exists?(File.join(@path, "index"))
      File.open(File.join(@path, "index"), "r") do |f|
        dump = f.read
      end
    end
    if dump.length > 0
      index = Marshal.load(dump)
      @indexed_file_hash = index.indexed_file_hash
      @data = index.data
      @hunks = index.hunks
    end
  end
end
