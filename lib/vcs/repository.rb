class Repository
  REPOSITORY_DIR = ".vcs"

  def initialize(path)
    @path = path
    @index = Index.new path
    @commits = []
    load_commits
  end

  def exists?
    Dir.exists?(File.join(@path, REPOSITORY_DIR))
  end

  def create_repository(force)
    dir = File.join(@path, REPOSITORY_DIR)

    if exists? && force
      FileUtils.rm dir, :force => true
    end

    if !exists?
      FileUtils.mkdir_p(dir)
    else
      raise RuntimeError
    end
  end

  def all_files
    Dir.glob(File.join(@path, "**/*")).reject do |f|
      File.directory?(f) || !!f.index(REPOSITORY_DIR)
    end
  end

  def all_changed_files
    all = all_files
    all.concat(@index.data.keys.reject { |f| !!all.index(f) })
    all.reject do |f|
      @index.data.key?(f) && File.exists?(f) && Digest::SHA1.digest(File.open(f).read) == Digest::SHA1.digest(@index.data[f])
    end
  end

  def new_files(type)
    files = all_files.reject { |f|
       @index.data.key?(f) && @index.indexed_file_hash.key?(f)
    }.concat(@index.indexed_file_hash.keys.reject { |f| @index.data.key?(f) }).uniq

    case type
      when :not_indexed
        files.reject { |f| @index.indexed_file_hash.key?(f) }
      when :indexed
        files.reject { |f| !@index.indexed_file_hash.key?(f) }
      else
        files
    end
  end

  def modified_files(type)
    files = {}.tap { |h|
      all_files.reject { |f| !@index.data.key?(f) }.each do |f|
        h[f] = Digest::SHA1.digest(File.open(f).read)
      end
    }.reject { |k, v| v == Digest::SHA1.digest(@index.data[k]) }.merge({}.tap { |h|
      new_files(:indexed).reject { |f| !File.exists?(f) }.each do |f|
        h[f] = Digest::SHA1.digest(File.open(f).read)
      end
    }.reject { |k, v| @index.indexed_file_hash[k] == v })

    case type
      when :not_indexed
        files.reject! { |k, v| @index.indexed_file_hash[k] == v }
      when :indexed
        files.reject! { |k, v| !@index.data.key?(k) || @index.indexed_file_hash[k] == Digest::SHA1.digest(@index.data[k]) }
    end
    files.keys
  end

  def deleted_files(type)
    all = all_files
    files = @index.data.keys.reject { |f| !!all.index(f) }.concat(@index.indexed_file_hash.keys.reject { |f| !!all.index(f) }).uniq

    case type
      when :not_indexed
        files.reject { |f| !@index.indexed_file_hash.key?(f) }
      when :indexed
        files.reject { |f| @index.indexed_file_hash.key?(f) }
      else
        files
    end
  end

  def indexing(files)
    all = all_changed_files
    diff_creator = DiffCreator.new
    hunks = []
    hash = @index.indexed_file_hash
    files.each do |f|
      if all.index f
        diff = diff_creator.create(File.extname(f))
        if File.exists? f
          hunks.concat(diff.diff(f, @index.data[f]))
          hash[f] = Digest::SHA1.digest(File.open(f).read)
        else
          hunks.concat(diff.diff(DiffBase::NULL_FILE, @index.data[f]))
          hash.delete f
        end
      end
    end
    @index.hunks = hunks
    @index.indexed_file_hash = hash
    @index.save_index
  end

  def commit(commit_message)
    if !!@index.hunks && !@index.hunks.empty?
      @commits << Commit.new(@index.hunks, commit_message)
      save_commits

      diff_creator = DiffCreator.new
      @index.hunks.each do |h|
        @index.data[h.file] = diff_creator.create_by_name(h.diff_class).apply(@index.data[h.file], [h], :forward)
      end
      @index.hunks = nil
      @index.save_index
    end
  end

  def save_commits
    File.open(File.join(@path, REPOSITORY_DIR, "commits"), "w+") do |f|
      f.write(Marshal.dump(@commits))
    end
  end

  def load_commits
    if File.exists? File.join(@path, REPOSITORY_DIR, "commits")
      @commits = Marshal.load(File.open(File.join(@path, REPOSITORY_DIR, "commits")).read)
    end
  end

  def commit_log
    [].tap do |a|
      if !!@commits
        @commits.each do |c|
          a << {
            hash: c.hash,
            date: c.commit_date,
            commit_message: c.commit_message
          }
        end
      end
    end
  end
end
